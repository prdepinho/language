
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "hash.h"
#include "vm.h"
#include "types.h"

extern FILE *yyin;

Map *variables;
VM *vm;
size_t vcount;
Addr null_addr;

void clean_stack() {
	for (Addr i = vm->stack->length; i > vcount; i--) {
		vm_pop(vm);
	}
}

void exit_program(int status_code) {
	if (variables != NULL)
		map_delete(variables);
	if (vm != NULL)
		vm_delete(vm);
	exit(status_code);
}

int yyparse();
int yylex();

void yyerror(const char *str) { /* fprintf(stderr, "Error: %s\n", str); */ }

int yywrap() { 
	fclose(yyin);
	return 1; 
}

int main(int argc, const char **argv) {
	// arguments
	if (argc > 1) {
		printf("%s\n", argv[1]);
		yyin = fopen(argv[1], "r");
	}

	// initialization

	int rval = 0;
	vcount = 1;
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

	null_addr = vm_push_int(vm, 0);

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

%token UNDERLINE NEWLINE IDENTIFIER INT_LITERAL FLOAT_LITERAL HEX_LITERAL STRING_LITERAL PRINT BYTE INT UINT LONG ULONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT TRUE FALSE STACK COMMANDS
%left '+' '-'
%left '*' '/' '%'
%left '^'

%%

program
	: %empty
	| program declaration NEWLINE
	{
		vm_run(vm);
		clean_stack();
	}
	| program assignment NEWLINE
	{
		vm_run(vm);
		clean_stack();
	}
	| program command NEWLINE
	| program expression NEWLINE
	{
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
		clean_stack();
	}
	| program error NEWLINE
	{
		printf("Error\n");
	}
	| program label NEWLINE
	| program NEWLINE
	;

label
	: IDENTIFIER ':'
	{
		char *identifier = $1;

		map_put (
			variables,
			identifier, strlen(identifier),
			&vcount, sizeof(vcount)
		);
		vcount++;

		Command cmd;
		vm_push_cmd(vm, cmd);

		free(identifier);
	}

declaration
	: IDENTIFIER ':' type
	{
		char *identifier = $1;
		int type = $3;

		map_put (
			variables,
			identifier, strlen(identifier),
			&vcount, sizeof(vcount)
		);
		vcount++;

		Command cmd;
		switch (type) {
		case TYPE_BYTE:
			cmd.code = CMD_SET_BYTE;
			cmd.addr = vm_push_byte(vm, 0);
			cmd.byte_arg = 0;
			break;
		case TYPE_UINT:
			cmd.code = CMD_SET_UINT;
			cmd.addr = vm_push_uint(vm, 0);
			cmd.uint_arg = 0;
			break;
		case TYPE_INT:
			cmd.code = CMD_SET_INT;
			cmd.addr = vm_push_int(vm, 0);
			cmd.int_arg = 0;
			break;
		case TYPE_FLOAT:
			cmd.code = CMD_SET_FLOAT;
			cmd.addr = vm_push_float(vm, 0.0);
			cmd.float_arg = 0.0;
			break;
		}
		vm_push_cmd(vm, cmd);

		free(identifier);
	}
	| IDENTIFIER ':' type '=' expression
	{
		char *identifier = $1;
		int type = $3;
		Addr rregaddr = $5;

		map_put (
			variables,
			identifier, strlen(identifier),
			&vcount, sizeof(vcount)
		);

		Register lreg = vm_get(vm, vcount);
		Register rreg = vm_get(vm, rregaddr);

		vcount++;

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

		free(identifier);
	}
	;

assignment
	: IDENTIFIER '=' expression
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
	;

expression
	: INT_LITERAL
	{
		$$ = vm_push_int(vm, $1);
	}
	| FLOAT_LITERAL
	{
		$$ = vm_push_float(vm, $1);
	}
	| HEX_LITERAL
	{
		$$ = vm_push_int(vm, $1);
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
	| STACK
	{
		for (int i = 0; i < vm->stack->length; i++) {
			printf("%d: ", i);
			Register reg = vm_get(vm, i);
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
			}
		}
		printf("Total: %lu\n", vm->stack->length);
	}
	| COMMANDS
	{
		for (int i = 0; i < vm->commands->length; i++) {
			if (i == vm->cmd_ptr)
				printf("> ");
			printf("%d: ", i);
			Command cmd;
			array_get(vm->commands, i, &cmd);
			switch (cmd.code) {
			case CMD_SET_BYTE:
				printf("set byte");
				break;
			case CMD_SET_UINT:
				printf("set uint\n");
				break;
			case CMD_SET_INT:
				printf("set int\n");
				break;
			case CMD_SET_FLOAT:
				printf("set float\n");
				break;
			case CMD_ADD:
				printf("add\n");
				break;
			case CMD_SUB:
				printf("sub\n");
				break;
			case CMD_MULT:
				printf("mult\n");
				break;
			case CMD_DIV:
				printf("div\n");
				break;
			case CMD_JUMP:
				printf("jump\n");
				break;
			case CMD_JCOND:
				printf("jcond\n");
				break;
			case CMD_POP:
				printf("pop\n");
				break;
			}
		}
		if (vm->cmd_ptr == vm->commands->length)
			printf(">\n");
		printf("Total: %lu\n", vm->commands->length);
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
