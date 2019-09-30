
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "hash.h"
#include "semantics.h"

extern Map *variables;

int yyparse();
int yylex();

void yyerror(const char *str){ /* fprintf(stderr, "Error: %s\n", str); */ }

int yywrap(){ return 1; }

int main(){
	if (init()){
		printf("Map is null.\n");
		return 1;
	}

	yyparse();

	finalize();
	return 0;
}

%}

%union {
	int integer;
	double number;
	char *str;
	Variable variable;
}

%type <str> IDENTIFIER
%type <str> STRING_LITERAL
%type <integer> type
%type <integer> boolean
%type <number> NUMBER
%type <number> expression
%type <variable> test

%token UNDERLINE NEWLINE IDENTIFIER NUMBER STRING_LITERAL PRINT BYTE INT UINT LONG ULONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT TRUE FALSE

%left '+' '-'
%left '*' '/' '%' '^'

%%

program
	: %empty
	| program declaration NEWLINE
	| program assignment NEWLINE
	| program command NEWLINE
	| program expression NEWLINE
	| program test NEWLINE
	| program error NEWLINE
	{
		printf("Error\n");
	}
	;

test
	: UNDERLINE IDENTIFIER
	{
		printf("test\n");
		Variable var;
		var.type = TYPE_DOUBLE;
		var.double_value = 0.f;
		$$ = var;
	}
	;

declaration
	: IDENTIFIER ':' type
	{
		char *identifier = $1;
		int type = $3;
		declare_variable(identifier, type);
		free(identifier);
	}
	| IDENTIFIER ':' type '=' expression
	{
		char *identifier = $1;
		int type = $3;
		double number = $5;
		declare_variable(identifier, type);
		assign_number(identifier, number);
		free(identifier);
	}
	| IDENTIFIER ':' type '=' STRING_LITERAL
	{
		char *identifier = $1;
		int type = $3;
		char *string_literal = $5;
		declare_variable(identifier, type);
		assign_string_literal(identifier, string_literal);
		free(identifier);
		free(string_literal);
	}
	| IDENTIFIER ':' type '=' boolean
	{
		char *identifier = $1;
		int type = $3;
		int bool_value = $5;
		declare_variable(identifier, type);
		assign_boolean(identifier, bool_value);
		free(identifier);
	}
	;

assignment
	: IDENTIFIER '=' expression
	{
		char *identifier = $1;
		double number = $3;
		assign_number(identifier, number);
		free(identifier);
	}
	| IDENTIFIER '=' STRING_LITERAL
	{
		char *identifier = $1;
		char *string_literal = $3;
		assign_string_literal(identifier, string_literal);
		free(identifier);
		free(string_literal);
	}
	| IDENTIFIER '=' boolean
	{
		char *identifier = $1;
		int bool_value = $3;
		assign_boolean(identifier, bool_value);
		free(identifier);
	}
	;

expression
	: NUMBER
	{
		$$ = $1;
	}
	| expression '+' expression
	{
		double lval = $1;
		double rval = $3;
		double result = lval + rval;
		$$ = result;
	}
	| expression '-' expression
	{
		double lval = $1;
		double rval = $3;
		double result = lval - rval;
		$$ = result;
	}
	| expression '*' expression
	{
		double lval = $1;
		double rval = $3;
		double result = lval * rval;
		$$ = result;
	}
	| expression '/' expression
	{
		double lval = $1;
		double rval = $3;
		double result = lval / rval;
		$$ = result;
	}
	| expression '%' expression
	{
		int lval = (int) $1;
		int rval = (int) $3;
		double result = (double) (lval % rval);
		$$ = result;
	}
	| expression '^' expression
	{
		double lval = $1;
		double rval = $3;
		double result = pow(lval, rval);
		$$ = result;
	}
	| '-' expression
	{
		$$ = $2 * -1;
	}
	| IDENTIFIER
	{
		double value;
		int rval = get_value($1, &value);
		$$ = value;
	}
	| '(' expression ')'
	{
		$$ = $2;
	}
	;

command
	: QUIT { exit_program(0); }
	| EXIT { exit_program(0); }
	| PRINT IDENTIFIER
	{
		char *identifier = $2;
		Variable var;
		size_t var_size;
		{
			int rval = map_get(
				variables,
				identifier, strlen(identifier),
				(&var), &var_size
			);
			if (rval){
				fprintf(stderr, "Variable '%s' has not been declared.\n", identifier);
				goto command_end;
			}
			else {
#ifdef DEBUG
				printf("Found variable: %s of type: %d\n", identifier, var.type);
#endif
			}
		}

		switch(var.type){
			case TYPE_BYTE: printf("%x\n", var.byte_value); break;
			case TYPE_INT: printf("%d\n", var.int_value); break;
			case TYPE_UINT: printf("%u\n", var.int_value); break;
			case TYPE_LONG: printf("%ld\n", var.long_value); break;
			case TYPE_ULONG: printf("%lu\n", var.long_value); break;
			case TYPE_FLOAT: printf("%f\n", var.float_value); break;
			case TYPE_DOUBLE: printf("%f\n", var.double_value); break;
			case TYPE_BOOL: printf("%s (%u)\n", var.bool_value ? "true" : "false", var.bool_value); break;
			case TYPE_STRING: printf("%s\n", var.string_value); break;
		}

command_end:
		free(identifier);
	}
	;

type
	: BYTE    { $$ = TYPE_BYTE; }
	| INT     { $$ = TYPE_INT; }
	| UINT    { $$ = TYPE_UINT; }
	| LONG    { $$ = TYPE_LONG; }
	| ULONG   { $$ = TYPE_ULONG; }
	| FLOAT   { $$ = TYPE_FLOAT; }
	| DOUBLE  { $$ = TYPE_DOUBLE; }
	| BOOL    { $$ = TYPE_BOOL; }
	| STRING  { $$ = TYPE_STRING; }
	;

boolean
	: TRUE { $$ = 1; }
	| FALSE { $$ = 0; }
