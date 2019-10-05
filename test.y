
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "hash.h"
#include "vm.h"
#include "types.h"

Map *variables;
VM *vm;
size_t vcount;

int yyparse();
int yylex();

void yyerror(const char *str) { /* fprintf(stderr, "Error: %s\n", str); */ }

int yywrap() { return 1; }

int main() {
	int rval = 0;
	vcount = 0;
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

	yyparse();

main_end:
	if (variables != NULL)
		map_delete(variables);
	if (vm != NULL)
		vm_delete(vm);
	return rval;
}

%}

%union {
	Int int_value;
	Float float_value;
	Byte byte_value;
	char *str;
	Register reg;
}

%type <str> IDENTIFIER
%type <str> STRING_LITERAL
%type <int_value> type
%type <int_value> boolean
%type <int_value> INT_LITERAL
%type <float_value> FLOAT_LITERAL
%type <int_value> HEX_LITERAL
%type <reg> expression

%token UNDERLINE NEWLINE IDENTIFIER INT_LITERAL FLOAT_LITERAL HEX_LITERAL STRING_LITERAL PRINT BYTE INT UINT LONG ULONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT TRUE FALSE 
%left '+' '-'
%left '*' '/' '%'
%left '^'

%%

program
	: %empty
	| program declaration NEWLINE
	| program assignment NEWLINE
	| program command NEWLINE
	| program expression NEWLINE
	{
		Register reg = $2;
		switch (reg.type) {
		case TYPE_BYTE:
			printf("byte expression: %d\n", reg.byte_value);
			break;
		case TYPE_UINT:
			printf("uint expression: %lu\n", reg.uint_value);
			break;
		case TYPE_INT:
			printf("int expression: %ld\n", reg.int_value);
			break;
		case TYPE_FLOAT:
			printf("float expression: %f\n", reg.float_value);
			break;
		}
	}
	| program error NEWLINE
	{
		printf("Error\n");
	}
	;

declaration
	: IDENTIFIER ':' type
	{
		// char *identifier = $1;
		// int type = $3;

		// if (map_put (
		// 	variables,
		// 	identifier, strlen(identifier),
		// 	&vcount++, sizeof(vcount)
		// ))
		// {
		// 	fprintf(stderr, "out of memory");
		// 	return 1;
		// }

		// Command cmd;
		// switch (type) {
		// case TYPE_BYTE:
		// 	cmd.code = CMD_SET_BYTE;
		// 	break;
		// case TYPE_UINT:
		// 	cmd.code = CMD_SET_UINT;
		// 	break;
		// case TYPE_INT:
		// 	cmd.code = CMD_SET_INT;
		// 	break;
		// case TYPE_FLOAT:
		// 	cmd.code = CMD_SET_FLOAT;
		// 	break;
		// }
		// vm_push_command(vm, cmd);

		// free(identifier);
	}
	| IDENTIFIER ':' type '=' expression
	{
		// char *identifier = $1;
		// int type = $3;
		// Variable var = $5;

		// map_put (
		// 	variables,
		// 	identifier, strlen(identifier),
		// 	&vcount++, sizeof(vcount)
		// )

		// Command cmd;
		// switch (type) {
		// case TYPE_BYTE:
		// 	cmd.code = CMD_SET_BYTE;
		// 	cmd.byte_arg = var;
		// 	break;
		// case TYPE_UINT:
		// 	cmd.code = CMD_SET_UINT;
		// 	cmd.uint_arg = var;
		// 	break;
		// case TYPE_INT:
		// 	cmd.code = CMD_SET_INT;
		// 	cmd.int_arg = var;
		// 	break;
		// case TYPE_FLOAT:
		// 	cmd.code = CMD_SET_FLOAT;
		// 	cmd.float_arg = var;
		// 	break;
		// }
		// vm_push_command(vm, cmd);

		// free(identifier);
	}
	;

assignment
	: IDENTIFIER '=' expression
	{
		// char *identifier = $1;
		// Variable var = $3;

		// size_t index;
		// map_get (
		// 	variables,
		// 	identifier, strlen(identifier),
		// 	&index, sizeof(index)
		// )

		// Register reg = vm_get_register(vm, index);

		// Command cmd;
		// switch (reg.type) {
		// case TYPE_BYTE:
		// 	cmd.code = CMD_SET_BYTE;
		// 	cmd.byte_arg = var;
		// 	break;
		// case TYPE_UINT:
		// 	cmd.code = CMD_SET_UINT;
		// 	cmd.uint_arg = var;
		// 	break;
		// case TYPE_INT:
		// 	cmd.code = CMD_SET_INT;
		// 	cmd.int_arg = var;
		// 	break;
		// case TYPE_FLOAT:
		// 	cmd.code = CMD_SET_FLOAT;
		// 	cmd.float_arg = var;
		// 	break;
		// }
		// vm_push_command(vm, cmd);

		// free(identifier);
	}
	;

expression
	: INT_LITERAL
	{
		Register reg;
		reg.type = TYPE_INT;
		reg.int_value = $1;
		$$ = reg;
	}
	| FLOAT_LITERAL
	{
		Register reg;
		reg.type = TYPE_FLOAT;
		reg.float_value = $1;
		$$ = reg;
	}
	| HEX_LITERAL
	{
		Register reg;
		reg.type = TYPE_INT;
		reg.int_value = $1;
		$$ = reg;
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
		// Variable var;
		// get_variable($1, &var);
		free($1);
		// $$ = var;
	}
	| '-' expression
	{
		Register reg = $2;
		switch (reg.type) {
		case TYPE_BYTE:
			reg.byte_value *= -1;
			break;
		case TYPE_UINT:
			reg.uint_value *= -1;
			break;
		case TYPE_INT:
			reg.int_value *= -1;
			break;
		case TYPE_FLOAT:
			reg.float_value *= -1;
			break;
		}
		$$ = reg;
	}
	| '(' expression ')'
	{
		$$ = $2;
	}
	| expression '+' expression
	{
	}
	| expression '-' expression
	{
	}
	| expression '*' expression
	{
	}
	| expression '/' expression
	{
	}
	| expression '%' expression
	{
	}
	| expression '^' expression
	{
		// Variable lvar = $1;
		// Variable rvar = $3;

		// switch(lvar.type) {
		// case TYPE_BYTE:      lvar.byte_value = (uint8_t) pow(get_number(lvar), get_number(rvar)); break;
		// case TYPE_INT:       lvar.int_value = (int32_t) pow(get_number(lvar), get_number(rvar)); break;
		// case TYPE_UINT:      lvar.uint_value = (uint32_t) pow(get_number(lvar), get_number(rvar)); break;
		// case TYPE_LONG:      lvar.long_value = (int64_t) pow(get_number(lvar), get_number(rvar)); break;
		// case TYPE_ULONG:     lvar.ulong_value = (uint64_t) pow(get_number(lvar), get_number(rvar)); break;
		// case TYPE_FLOAT:     lvar.float_value = (float) pow(get_number(lvar), get_number(rvar)); break;
		// case TYPE_DOUBLE:    lvar.double_value = (double) pow(get_number(lvar), get_number(rvar)); break;
		// case TYPE_BOOL:      printf("Cannot operate on bool.\n"); break;
		// case TYPE_STRING:    printf("Cannot operate on string.\n"); break;
		// }
		// $$ = lvar;
	}
	;

command
	: QUIT 
	{
		exit(0);
	}
	| EXIT
	{
		exit(0);
	}
	| PRINT IDENTIFIER
	{
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
