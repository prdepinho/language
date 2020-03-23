
%{
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "hash.h"
#include "vm.h"
#include "types.h"

extern FILE *yyin;

// Virtual machine
VM *vm;
bool interactive_mode;		// when input is from stdin and executing them at once.

// Variable handling
Array *scope_stack;			// keeps track of identifiers positions for each scope level.
Array *identifiers;			// keeps track of identifiers, that is, variable, labels, function names. All identifiers are in the machine stack.
Map *variables;				// maps variable names with their place in the machine stack.
size_t ccount;				// count how many constants have been used for each sentence.

// null pointer
Addr null_addr;				// the null pointer is an int 0 at the bottom of the stack.


void exit_program(int status_code) {
	if (variables != NULL)
		map_delete(variables);
	if (vm != NULL)
		vm_delete(vm);
	if (scope_stack != NULL)
		array_delete(scope_stack);
	if (identifiers != NULL)
		array_delete(identifiers);
	fclose(yyin);
	printf("Good bye.\n");
	exit(status_code);
}

int yyparse();
int yylex();

void yyerror(const char *str) {
	fprintf(stderr, "YYError: %s\n", str);
}

// This function is called when finished reading from yyin. Execute code if it was a file.
int yywrap() { 
	printf("wrapping up.\n");
	return 1; 
}

int main(int argc, const char **argv) {
	// arguments
	if (argc > 1) {
		printf("%s\n", argv[1]);
		yyin = fopen(argv[1], "r");
		interactive_mode = false;
	}
	else {
		interactive_mode = true;
		printf("Interactive mode.\n");
	}

	// initialization
	int rval = 0;
	{
		ccount = 0;
		variables = NULL;
		vm = NULL;

		variables = map_new(2);
		if (variables == NULL) {
			printf("Map is null.\n");
			rval = 1;
			goto main_end;
		}

		vm = vm_new();
		if (vm == NULL) {
			printf("vm is null.\n");
			rval = 1;
			goto main_end;
		}

		scope_stack = array_new(sizeof(size_t), 0);
		if (scope_stack == NULL) {
			printf("scope_stack is null.\n");
			rval = 1;
			goto main_end;
		}

		identifiers = array_new(sizeof(char *), 0);
		if (identifiers == NULL) {
			printf("identifiers is null.\n");
			rval = 1;
			goto main_end;
		}

		null_addr = vm_push_int(vm, 0);
	}

	yyparse();

main_end:
	exit_program(rval);
	return rval;
}

%}

%union {
	Int int_value;
	Float float_value;
	Byte byte_value;
	Addr addr_value;
	char *str;
}

%type <str> IDENTIFIER
%type <str> STRING_LITERAL
%type <int_value> type
%type <int_value> boolean
%type <int_value> INT_LITERAL
%type <float_value> FLOAT_LITERAL
%type <int_value> HEX_LITERAL
%type <addr_value> expression
%type <int_value> vm_command_int_param
%type <float_value> vm_command_float_param

%token UNDERLINE NEWLINE IDENTIFIER INT_LITERAL FLOAT_LITERAL HEX_LITERAL STRING_LITERAL PRINT BYTE INT UINT LONG ULONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT TRUE FALSE STACK COMMANDS VM_SET_BYTE VM_SET_INT VM_SET_UINT VM_SET_FLOAT VM_MALLOC VM_FREE VM_ADD VM_SUB VM_MULT VM_DIV VM_JUMP VM_JCOND VM_POP VM_PUSH VM_PUSH_BYTE VM_PUSH_INT VM_PUSH_UINT VM_PUSH_FLOAT VM_AND VM_OR VM_XOR VM_NOT DUMP
%left '+' '-'
%left '*' '/' '%'
%left '^'

%%

program
	: sentences
	{
		if (!interactive_mode)
			vm_run(vm);
	}
	;

sentences
	: %empty
	| sentences declaration end_sentence
	{
		if (interactive_mode) {
			vm_run(vm);
		}
		// clean stack from constants
		for (; ccount > 0; ccount--) {
			vm_push_cmd_pop(vm);
		}
	}
	| sentences assignment end_sentence
	{
		if (interactive_mode) {
			vm_run(vm);
		}
		// clean stack from constants
		for (; ccount > 0; ccount--) {
			vm_push_cmd_pop(vm);
		}
	}
	| sentences expression end_sentence
	{
		if (interactive_mode) {
			vm_run(vm);
			Addr addr = $2;
			Register reg = vm_get(vm, addr);
			switch (reg.type) {
			case TYPE_BYTE:
				printf("%d\n", reg.byte_value);
				break;
			case TYPE_UINT:
				printf("%lu\n", reg.uint_value);
				break;
			case TYPE_INT:
				printf("%ld\n", reg.int_value);
				break;
			case TYPE_FLOAT:
				printf("%f\n", reg.float_value);
				break;
			}
		}
		// clean stack from constants
		for (; ccount > 0; ccount--) {
			vm_push_cmd_pop(vm);
		}
	}
	| sentences error end_sentence
	{
		printf("Error\n");
	}
	| sentences label end_sentence
	| sentences end_sentence
	| sentences function_declaration end_sentence
	| sentences command end_sentence
	| sentences vm_command end_sentence
	{
		// if it is interactive mode, execute after each line.
		if (interactive_mode) {
			vm_run(vm);
		}
	}
	| sentences block
	;

block
	: start_block sentences end_block
	{
		printf("a block\n");
	}
	;

start_block
	: '{'
	{
		size_t level = array_push(scope_stack, &identifiers->length);
		printf("start scope: level: %lu, identifiers: %lu\n", level, identifiers->length);
	}
	;

end_block
	: '}'
	{
		size_t position = 0;
		array_pop(scope_stack, &position);
		printf("returning to %lu from %lu\n", position, identifiers->length);

		for (Addr i = identifiers->length; i > position; i--) {
			// remove variables from stack and from map (compile time)
			char *vname = NULL;
			array_pop(identifiers, &vname);
			map_remove(variables, vname, strlen(vname));
			free(vname);

			// pop from machine stack (run time)
			vm_push_cmd_pop(vm);
		}
	}
	;

function_declaration
	: IDENTIFIER  param_list ':' type
	{
		char *identifier = $1;
		printf("function declaration\n");
		free(identifier);
	}
	;

param_list
	: param_list_content ')'

param_list_content
	: param_list_content ',' IDENTIFIER ':' type
	{
		char *identifier = $3;
		free(identifier);
	}
	| '(' IDENTIFIER ':' type
	{
		char *identifier = $2;
		free(identifier);
	}
	| '('
	; 

label
	: IDENTIFIER ':'
	{
		char *identifier = $1;

		array_push(identifiers, &identifier);

		map_put (
			variables,
			identifier, strlen(identifier),
			&identifiers->length, sizeof(identifiers->length)
		);

		Addr addr = vm_push_cmd_push(vm);
		vm_push_cmd_set_uint(vm, identifiers->length, addr);
	}

declaration
	: IDENTIFIER ':' type
	{
		char *identifier = $1;
		int type = $3;

		array_push(identifiers, &identifier);

		map_put (
			variables,
			identifier, strlen(identifier),
			&identifiers->length, sizeof(identifiers->length)
		);

		vm_push_cmd_push(vm);

		switch (type) {
		case TYPE_BYTE:
			vm_push_cmd_set_byte(vm, identifiers->length, 0);
			break;
		case TYPE_UINT:
			vm_push_cmd_set_uint(vm, identifiers->length, 0);
			break;
		case TYPE_INT:
			vm_push_cmd_set_int(vm, identifiers->length, 0);
			break;
		case TYPE_FLOAT:
			vm_push_cmd_set_float(vm, identifiers->length, 0.0);
			break;
		}
	}
	| IDENTIFIER ':' type '=' expression
	{
#if false
	{
		char *identifier = $1;
		int type = $3;
		Addr rregaddr = $5;

		array_push(identifiers, &identifier);

		map_put (
			variables,
			identifier, strlen(identifier),
			&identifiers->length, sizeof(identifiers->length)
		);

		Register lreg = vm_get(vm, vcount);
		Register rreg = vm_get(vm, rregaddr);

		Command cmd;
		switch (lreg.type) {
		case TYPE_BYTE:
			cmd.code = CMD_SET_BYTE;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.addr = vm_push_byte(vm, 0);
				cmd.byte_arg = rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.addr = vm_push_byte(vm, 0);
				cmd.byte_arg = (Byte) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.addr = vm_push_byte(vm, 0);
				cmd.byte_arg = (Byte) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.addr = vm_push_byte(vm, 0);
				cmd.byte_arg = (Byte) rreg.float_value;
				break;
			}
			break;

		case TYPE_UINT:
			cmd.code = CMD_SET_UINT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.addr = vm_push_uint(vm, 0);
				cmd.uint_arg = (UInt) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.addr = vm_push_uint(vm, 0);
				cmd.uint_arg = rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.addr = vm_push_uint(vm, 0);
				cmd.uint_arg = (UInt) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.addr = vm_push_uint(vm, 0);
				cmd.uint_arg = (UInt) rreg.float_value;
				break;
			}
			break;

		case TYPE_INT:
			cmd.code = CMD_SET_INT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.addr = vm_push_int(vm, 0);
				cmd.int_arg = (Int) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.addr = vm_push_int(vm, 0);
				cmd.int_arg = (Int) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.addr = vm_push_int(vm, 0);
				cmd.int_arg = rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.addr = vm_push_int(vm, 0);
				cmd.int_arg = (Int) rreg.float_value;
				break;
			}
			break;

		case TYPE_FLOAT:
			cmd.code = CMD_SET_FLOAT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.addr = vm_push_float(vm, 0.0);
				cmd.float_arg = (Float) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.addr = vm_push_float(vm, 0.0);
				cmd.float_arg = (Float) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.addr = vm_push_float(vm, 0.0);
				cmd.float_arg = (Float) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.addr = vm_push_float(vm, 0.0);
				cmd.float_arg = rreg.float_value;
				break;
			}
			break;
		}
		vm_push_cmd(vm, cmd);
	}
#endif
	}
	;

assignment
	: IDENTIFIER '=' expression
	{
#if false
	{
		char *identifier = $1;
		Addr rregaddr = $3;

		Addr lregaddr;
		size_t size;
		if (map_get (
			variables,
			identifier, strlen(identifier),
			&lregaddr, &size
		))
		{
			printf("Identifier '%s' undeclared.\n", identifier);
			goto assignment_end;
		}

		Register lreg = vm_get(vm, lregaddr);
		Register rreg = vm_get(vm, rregaddr);

		Command cmd;
		cmd.addr = lregaddr;

		switch (lreg.type) {
		case TYPE_BYTE:
			cmd.code = CMD_SET_BYTE;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.byte_arg = rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.byte_arg = (Byte) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.byte_arg = (Byte) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.byte_arg = (Byte) rreg.float_value;
				break;
			}
			break;

		case TYPE_UINT:
			cmd.code = CMD_SET_UINT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.uint_arg = (UInt) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.uint_arg = rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.uint_arg = (UInt) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.uint_arg = (UInt) rreg.float_value;
				break;
			}
			break;

		case TYPE_INT:
			cmd.code = CMD_SET_INT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.int_arg = (Int) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.int_arg = (Int) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.int_arg = rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.int_arg = (Int) rreg.float_value;
				break;
			}
			break;

		case TYPE_FLOAT:
			cmd.code = CMD_SET_FLOAT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.float_arg = (Float) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.float_arg = (Float) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.float_arg = (Float) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.float_arg = rreg.float_value;
				break;
			}
			break;
		}
		vm_push_cmd(vm, cmd);

assignment_end:
		free(identifier);
	}
#else 
	{
		char *identifier = $1;
		Addr rregaddr = $3;

		Addr lregaddr;
		size_t size;
		if (map_get (
			variables,
			identifier, strlen(identifier),
			&lregaddr, &size
		))
		{
			printf("Identifier '%s' undeclared.\n", identifier);
			goto assignment_end;
		}

		Register lreg = vm_get(vm, lregaddr);
		Register rreg = vm_get(vm, rregaddr);

		Command cmd;
		cmd.addr = lregaddr;

		switch (lreg.type) {
		case TYPE_BYTE:
			cmd.code = CMD_SET_BYTE;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.byte_arg = rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.byte_arg = (Byte) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.byte_arg = (Byte) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.byte_arg = (Byte) rreg.float_value;
				break;
			}
			break;

		case TYPE_UINT:
			cmd.code = CMD_SET_UINT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.uint_arg = (UInt) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.uint_arg = rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.uint_arg = (UInt) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.uint_arg = (UInt) rreg.float_value;
				break;
			}
			break;

		case TYPE_INT:
			cmd.code = CMD_SET_INT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.int_arg = (Int) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.int_arg = (Int) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.int_arg = rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.int_arg = (Int) rreg.float_value;
				break;
			}
			break;

		case TYPE_FLOAT:
			cmd.code = CMD_SET_FLOAT;
			switch (rreg.type) {
			case TYPE_BYTE:
				cmd.float_arg = (Float) rreg.byte_value;
				break;
			case TYPE_UINT:
				cmd.float_arg = (Float) rreg.uint_value;
				break;
			case TYPE_INT:
				cmd.float_arg = (Float) rreg.int_value;
				break;
			case TYPE_FLOAT:
				cmd.float_arg = rreg.float_value;
				break;
			}
			break;
		}
		vm_push_cmd(vm, cmd);

assignment_end:
		free(identifier);
	}
#endif
	}
	;

expression
	: INT_LITERAL
	{
#if false
		$$ = vm_push_int(vm, $1);
#endif
		ccount++;
		vm_push_cmd_push(vm);
		vm_push_cmd_set_int(vm, -ccount, $1);
		$$ = -ccount;
	}
	| FLOAT_LITERAL
	{
		ccount++;
		vm_push_cmd_push(vm);
		vm_push_cmd_set_float(vm, -ccount, $1);
		$$ = -ccount;
	}
	| HEX_LITERAL
	{
		ccount++;
		vm_push_cmd_push(vm);
		vm_push_cmd_set_int(vm, -ccount, $1);
		$$ = -ccount;
	}
	| STRING_LITERAL
	{
		// Variable var;
		// set_string_literal(&var, $1);
		free($1);
		// $$ = var;
	}
	| boolean
	{
		// Variable var;
		// var.type = TYPE_BOOL;
		// var.bool_value = $1;
		// $$ = var;
	}
	| IDENTIFIER
	{
		char *identifier = $1;
		Addr addr;

		size_t size;
		if (map_get (
			variables,
			identifier, strlen(identifier),
			&addr, &size
		))
		{
			printf("Identifier '%s' undeclared.\n", identifier);
			addr = null_addr;
		}

		free(identifier);
		$$ = addr;
	}
	| '-' expression
	{
		Addr addr = $2;

		Command cmd;
		cmd.code = CMD_MULT;
		cmd.addr = addr;
		cmd.addr_arg = vm_push_int(vm, -1);
		cmd.raddr = vm_push_int(vm, 0);
		vm_push_cmd(vm, cmd);

		$$ = cmd.raddr;
	}
	| '(' expression ')'
	{
		$$ = $2;
	}
	| expression '+' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;

		Command cmd;
		cmd.code = CMD_ADD;
		cmd.addr = lvaladdr;
		cmd.addr_arg = rvaladdr;
		cmd.raddr = vm_push_int(vm, 0);
		vm_push_cmd(vm, cmd);

		$$ = cmd.raddr;
	}
	| expression '-' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;

		Command cmd;
		cmd.code = CMD_SUB;
		cmd.addr = lvaladdr;
		cmd.addr_arg = rvaladdr;
		cmd.raddr = vm_push_int(vm, 0);
		vm_push_cmd(vm, cmd);

		$$ = cmd.raddr;
	}
	| expression '*' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;

		Command cmd;
		cmd.code = CMD_MULT;
		cmd.addr = lvaladdr;
		cmd.addr_arg = rvaladdr;
		cmd.raddr = vm_push_int(vm, 0);
		vm_push_cmd(vm, cmd);

		$$ = cmd.raddr;
	}
	| expression '/' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;

		Command cmd;
		cmd.code = CMD_DIV;
		cmd.addr = lvaladdr;
		cmd.addr_arg = rvaladdr;
		cmd.raddr = vm_push_int(vm, 0);
		vm_push_cmd(vm, cmd);

		$$ = cmd.raddr;
	}
	| expression '%' expression
	{
	}
	| expression '^' expression
	{
	}
	;

command
	: QUIT { exit_program(0); }
	| EXIT { exit_program(0); }
	| PRINT IDENTIFIER
	{
		char *identifier = $2;
		Addr addr;

		size_t size;
		if (map_get (
			variables,
			identifier, strlen(identifier),
			&addr, &size
		))
		{
			printf("Identifier '%s' undeclared.\n", identifier);
			goto print_end;
		}

		Register reg = vm_get(vm, addr);
		printf("%s (%li): ", identifier, addr);
		switch (reg.type) {
		case TYPE_BYTE:
			printf("%d\n", reg.byte_value);
			break;
		case TYPE_UINT:
			printf("%lu\n", reg.uint_value);
			break;
		case TYPE_INT:
			printf("%ld\n", reg.int_value);
			break;
		case TYPE_FLOAT:
			printf("%f\n", reg.float_value);
			break;
		}
print_end:;
	}
	| DUMP
	{
		// print scope stack
		printf("scope_stack: %lu {", scope_stack->length);
		for (int i = 0; i < scope_stack->length; i++) {
			Addr addr;
			array_get(scope_stack, i, &addr);
			printf(" %lu", addr);
		}
		printf(" }\n");

		// print identifiers
		printf("identifiers: %lu\n", identifiers->length);
		for (int i = 0; i < identifiers->length; i++) {
			
			char *vname = NULL;
			array_get(identifiers, i, &vname);

			Addr addr;
			size_t addr_size;
			if (map_get(variables,
				vname, strlen(vname),
				&addr, &addr_size
			))
			{
				printf("Identifier '%s' undeclared.\n", vname);
				goto dump_end;
			}

			Register reg = vm_get(vm, addr);

			if (array_contains(scope_stack, &i))
				printf("%d: > ", i);
			else
				printf("%d:   ", i);

			printf("%s #%li ", vname, addr);
			switch (reg.type) {
			case TYPE_BYTE:
				printf("(byte) %d\n", reg.byte_value);
				break;
			case TYPE_UINT:
				printf("(uint) %lu\n", reg.uint_value);
				break;
			case TYPE_INT:
				printf("(int) %ld\n", reg.int_value);
				break;
			case TYPE_FLOAT:
				printf("(float) %f\n", reg.float_value);
				break;
			default:
				printf("default\n");
				break;
			}

		}
dump_end:
		printf("dump end\n");
	}
	;

vm_command
	: STACK
	{
		vm_push_cmd_stack(vm);
	}
	| COMMANDS
	{
		vm_push_cmd_commands(vm);
	}
	| PRINT vm_command_int_param
	{
		vm_push_cmd_print(vm, $2);
	}
	| VM_SET_BYTE vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_set_byte(vm, $2, $3);
	}
	| VM_SET_INT vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_set_int(vm, $2, $3);
	}
	| VM_SET_UINT vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_set_uint(vm, $2, $3);
	}
	| VM_SET_FLOAT vm_command_int_param vm_command_float_param
	{
		vm_push_cmd_set_float(vm, $2, $3);
	}
	| VM_ADD vm_command_int_param vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_add(vm, $2, $3, $4);
	}
	| VM_SUB vm_command_int_param vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_sub(vm, $2, $3, $4);
	}
	| VM_MULT vm_command_int_param vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_mult(vm, $2, $3, $4);
	}
	| VM_DIV vm_command_int_param vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_div(vm, $2, $3, $4);
	}
	| VM_AND vm_command_int_param vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_and(vm, $2, $3, $4);
	}
	| VM_OR vm_command_int_param vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_or(vm, $2, $3, $4);
	}
	| VM_XOR vm_command_int_param vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_xor(vm, $2, $3, $4);
	}
	| VM_NOT vm_command_int_param vm_command_int_param 
	{
		vm_push_cmd_not(vm, $2, $3);
	}
	| VM_JUMP vm_command_int_param
	{
		vm_push_cmd_jump(vm, $2);
	}
	| VM_JCOND vm_command_int_param vm_command_int_param
	{
		vm_push_cmd_jcond(vm, $2, $3);
	}
	| VM_PUSH
	{
		vm_push_cmd_push(vm);
	}
	| VM_POP
	{
		vm_push_cmd_pop(vm);
	}
	;

vm_command_int_param
	: INT_LITERAL
	{
		$$ = $1;
	}
	| HEX_LITERAL
	{
		$$ = $1;
	}
	;

vm_command_float_param
	: FLOAT_LITERAL
	{
		$$ = $1;
	}
	;

type
	: BYTE    { $$ = TYPE_BYTE; }
	| INT     { $$ = TYPE_INT; }
	| UINT    { $$ = TYPE_UINT; }
	| FLOAT   { $$ = TYPE_FLOAT; }
	;

boolean
	: TRUE { $$ = 1; }
	| FALSE { $$ = 0; }
	;

end_sentence
	: NEWLINE
	| ';'
	;
