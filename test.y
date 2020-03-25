
%{
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "hash.h"
#include "map_array.h"
#include "vm.h"
#include "types.h"

extern FILE *yyin;

// Virtual machine
VM *vm;
bool interactive_mode;		// when input is from stdin and executing them at once.

// Machine stack handling
Array *stack_scope;			// keeps track of machine stack positions for each scope level.
size_t stack_track;			// keep track in compile time of the size of the machine stack.

// Variable handling
Array *identifiers;			// keeps track of identifiers, that is, variable, labels, function names. All identifiers are in the machine stack.
Map *variables;				// maps variable names with their place in the machine stack. Labels are treated as variables.
Array *identifiers_scope;	// keeps track of identifiers positions for each scope level.

MapArray *labels;			// maps jump labels and the list of their positions in the commands.

// null pointer
Addr null_addr;				// the null pointer is an int 0 at the bottom of the stack.

void dump() {
	// print scope stack
	printf("stack_scope: %lu {", stack_scope->length);
	for (int i = 0; i < stack_scope->length; i++) {
		Addr addr;
		array_get(stack_scope, i, &addr);
		printf(" %lu", addr);
	}
	printf(" }\n");

	printf("identifiers_scope: %lu {", identifiers_scope->length);
	for (int i = 0; i < identifiers_scope->length; i++) {
		Addr addr;
		array_get(identifiers_scope, i, &addr);
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
		if (!map_get(variables,
			vname, strlen(vname),
			&addr, &addr_size
		))
		{
			printf("Identifier '%s' undeclared.\n", vname);
			goto dump_end;
		}

		Register reg = vm_get(vm, addr);

		if (array_contains(identifiers_scope, &i))
			printf("_ %4d: ", i);
		else
			printf("  %4d: ", i);

		printf("#%-4li ", addr); 
		switch (reg.type) {
		case TYPE_BYTE:
			printf("(byte)    %-15s %10d\n", vname, reg.byte_value);
			break;
		case TYPE_UINT:
			printf("(uint)    %-15s %10lu\n", vname, reg.uint_value);
			break;
		case TYPE_INT:
			printf("(int)     %-15s %10ld\n", vname, reg.int_value);
			break;
		case TYPE_FLOAT:
			printf("(float)   %-15s %10f\n", vname, reg.float_value);
			break;
		default:
			printf("default\n");
			break;
		}

	}
dump_end:
	printf("dump end\n");
}

void exit_program(int status_code) {
	if (variables != NULL)
		map_delete(variables);
	if (vm != NULL)
		vm_delete(vm);
	if (stack_scope != NULL)
		array_delete(stack_scope);
	if (identifiers_scope != NULL)
		array_delete(identifiers_scope);
	if (identifiers != NULL)
		array_delete(identifiers);
	if (labels != NULL)
		map_array_delete(labels);
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
		stack_track = 0;
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

		stack_scope = array_new(sizeof(size_t), 0);
		if (stack_scope == NULL) {
			printf("stack_scope is null.\n");
			rval = 1;
			goto main_end;
		}

		identifiers_scope = array_new(sizeof(size_t), 0);
		if (identifiers_scope == NULL) {
			printf("identifiers_scope is null.\n");
			rval = 1;
			goto main_end;
		}

		identifiers = array_new(sizeof(char *), 0);
		if (identifiers == NULL) {
			printf("identifiers is null.\n");
			rval = 1;
			goto main_end;
		}

		labels = map_array_new(2, sizeof(Addr), 0);
		if (labels == NULL) {
			printf("Labels is null.\n");
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

%token UNDERLINE NEWLINE IDENTIFIER INT_LITERAL FLOAT_LITERAL HEX_LITERAL STRING_LITERAL PRINT BYTE INT UINT LONG ULONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT TRUE FALSE STACK COMMANDS VM_SET_BYTE VM_SET_INT VM_SET_UINT VM_SET_FLOAT VM_MALLOC VM_FREE VM_ADD VM_SUB VM_MULT VM_DIV VM_JUMP VM_JCOND VM_POP VM_PUSH VM_PUSH_BYTE VM_PUSH_INT VM_PUSH_UINT VM_PUSH_FLOAT VM_AND VM_OR VM_XOR VM_NOT DUMP GOTO
%left '+' '-'
%left '*' '/' '%'
%left '^'

%%

program
	: sentences
	{
		if (!interactive_mode) {
			printf("Finished compiling, now running.\n");
			vm_run(vm);
		}
	}
	;

sentences
	: %empty
	| sentences declaration end_sentence
	{
		if (interactive_mode) {
			vm_run(vm);
		}
	}
	| sentences assignment end_sentence
	{
		if (interactive_mode) {
			vm_run(vm);
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
	| sentences GOTO IDENTIFIER end_sentence
	{
		// if label is already defined in variables, set jump to that label's value;
		// else, set jump to 0, and push its commands index to labels.
		char *identifier = $3;

		Addr addr;
		size_t size;
		if (map_get(
			variables,
			identifier, strlen(identifier),
			&addr, &size
		)) {
			vm_push_cmd_jump(vm, addr);
			free(identifier);
		}
		else {
			printf("Jump Identifier '%s' is undeclared.\n", identifier);
			vm_push_cmd_jump(vm, 0);
			if (!map_array_push(labels, identifier, strlen(identifier), &vm->commands->length))
				printf("label push failed.\n");
		}

	}
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
	}
	;

start_block
	: '{'
	{
		size_t level = array_push(stack_scope, &stack_track);
		array_push(identifiers_scope, &identifiers->length);
	}
	;

end_block
	: '}'
	{
		size_t position = 0;
		array_pop(stack_scope, &position);

		for (; stack_track > position; stack_track--) {
			// pop from machine stack (run time)
			vm_push_cmd_pop(vm);
		}

		position = 0;
		array_pop(identifiers_scope, &position);

		for (int i = identifiers->length; i > position; i--) {
			// remove variables from stack and from map (compile time)
			char *vname = NULL;
			array_pop(identifiers, &vname);
			map_remove(variables, vname, strlen(vname));
			free(vname);
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
		// define label in variables, if not already.
		// if there is a goto label set in labels, change all mapped jump commands to jump to this address.
		char *identifier = $1;

		Addr addr = 0;
		size_t size = 0;
		if (map_get(
			variables,
			identifier, strlen(identifier),
			&addr, &size
		)) {
			printf("Identifier %s already declared.\n", identifier);
			exit_program(0);
		}

		array_push(identifiers, &identifier);

		if (!map_put (
			variables,
			identifier, strlen(identifier),
			&vm->commands->length, sizeof(vm->commands->length)
		)){
			printf("Could not push identifier %s to variables\n", identifier);
			exit_program(0);
		}

		if (map_array_contains(labels, identifier, strlen(identifier))) {
			Array *array = NULL;
			map_array_get_array(labels, identifier, strlen(identifier), &array);

			for (int i = 0; i < array->length; i++) {
				Addr index = 0;
				array_get(array, i, &index);

				Command command;
				array_get(vm->commands, index, &command);
				command.addr = index;
				array_set(vm->commands, index, &command);
			}
		}


#if false
		if (!map_get (
			variables,
			identifier, strlen(identifier),
			&addr, &size
		))
		{
			printf("Jump Identifier '%s' is undeclared. Creating it now.\n", identifier);
			{
				stack_track++;
				array_push(identifiers, &identifier);

				map_put (
					variables,
					identifier, strlen(identifier),
					&stack_track, sizeof(stack_track)
				);

				Addr addr = vm_push_cmd_push(vm);
				vm_push_cmd_set_uint(vm, stack_track, addr);
			}
		}
		else {
		}
#endif
		free(identifier);

	}

declaration
	: IDENTIFIER ':' type
	{
		char *identifier = $1;
		int type = $3;

		array_push(identifiers, &identifier);

		vm_push_cmd_push(vm);

		stack_track++;

		map_put (
			variables,
			identifier, strlen(identifier),
			&stack_track, sizeof(stack_track)
		);

		switch (type) {
		case TYPE_BYTE:
			vm_push_cmd_set_byte(vm, stack_track, 0);
			break;
		case TYPE_UINT:
			vm_push_cmd_set_uint(vm, stack_track, 0);
			break;
		case TYPE_INT:
			vm_push_cmd_set_int(vm, stack_track, 0);
			break;
		case TYPE_FLOAT:
			vm_push_cmd_set_float(vm, stack_track, 0.0);
			break;
		}
	}
	| IDENTIFIER ':' type '=' expression
	{
		char *identifier = $1;
		int type = $3;
		Addr rregaddr = $5;

		array_push(identifiers, &identifier);

		vm_push_cmd_push(vm);

		stack_track++;
		map_put (
			variables,
			identifier, strlen(identifier),
			&stack_track, sizeof(stack_track)
		);

		switch (type) {
		case TYPE_BYTE:
			vm_push_cmd_set_byte(vm, stack_track, 0);
			break;
		case TYPE_UINT:
			vm_push_cmd_set_uint(vm, stack_track, 0);
			break;
		case TYPE_INT:
			vm_push_cmd_set_int(vm, stack_track, 0);
			break;
		case TYPE_FLOAT:
			vm_push_cmd_set_float(vm, stack_track, 0.0);
			break;
		}

		vm_push_cmd_assign(vm, stack_track, rregaddr);
	}
	;

assignment
	: IDENTIFIER '=' expression
	{
		char *identifier = $1;

		Addr rregaddr = $3;
		Addr lregaddr;

		size_t size;
		if (!map_get (
			variables,
			identifier, strlen(identifier),
			&lregaddr, &size
		))
		{
			printf("Identifier '%s' undeclared.\n", identifier);
			goto assignment_end;
		}

		vm_push_cmd_assign(vm, lregaddr, rregaddr);

assignment_end:
		free(identifier);
	}
	;

expression
	: INT_LITERAL
	{
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_set_int(vm, stack_track, $1);
		$$ = stack_track;
	}
	| FLOAT_LITERAL
	{
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_set_float(vm, stack_track, $1);
		$$ = stack_track;
	}
	| HEX_LITERAL
	{
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_set_int(vm, stack_track, $1);
		$$ = stack_track;
	}
	| STRING_LITERAL
	{
		free($1);
	}
	| boolean
	{
	}
	| IDENTIFIER
	{
		char *identifier = $1;
		Addr addr;

		size_t size;
		if (!map_get (
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
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_sub(vm, 0, addr, stack_track);
		$$ = stack_track;
	}
	| '(' expression ')'
	{
		$$ = $2;
	}
	| expression '+' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_add(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| expression '-' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_sub(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| expression '*' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_mult(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| expression '/' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_div(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
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
		if (!map_get (
			variables,
			identifier, strlen(identifier),
			&addr, &size
		))
		{
			printf("Identifier '%s' undeclared.\n", identifier);
		}
		else {
			vm_push_cmd_print(vm, addr);
		}
	}
	| DUMP
	{
		dump();
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
