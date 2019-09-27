
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "hash.h"

int yyparse();
int yylex();

Map *variables = NULL;

typedef struct _Variable {
	int type;
	union {
		uint8_t  byte_value;
		int32_t  int_value;
		uint32_t uint_value;
		int64_t  long_value;
		uint64_t ulong_value;
		float  float_value;
		double double_value;
		uint8_t bool_value;
		char *string_value;
	};
} Variable;

void yyerror(const char *str){
	// fprintf(stderr, "Error: %s\n", str);
}

int yywrap(){
	return 1;
}

int main(){
	variables = map_new(2048);
	if (variables == NULL) {
		printf("Map is null.\n");
		return 1;
	}

	yyparse();

	map_delete(variables);
	return 0;
}

%}

%union {
	int integer;
	float number;
	char *str;
}
%type <str> IDENTIFIER
%type <str> STRING_LITERAL
%type <integer> type
%type <number> NUMBER
%token UNDERLINE NEWLINE IDENTIFIER NUMBER STRING_LITERAL PRINT BYTE INT UINT LONG ULONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT
%left '+' '-'

%%

program
	: %empty
	| program declaration NEWLINE
	| program assignment NEWLINE
	| program command NEWLINE
	| program error NEWLINE
	{
		printf("Error\n");
	}
	;

declaration
	: type IDENTIFIER
	{
		Variable var = {$1, 0};
		int rval = map_put(
			variables,
			(uint8_t*)$2, strlen($2),
			(uint8_t*)(&var), sizeof(Variable)
		);
		if (rval)
			fprintf(stderr, "out of memory for variables.\n");
		else
			printf("declaration: %d %s\n", $1, $2);

		free($2);
	}
	;

assignment
	: IDENTIFIER '=' NUMBER
	{
		Variable var;
		size_t var_size;
		{
			int rval = map_get(
				variables,
				(uint8_t*)$1, strlen($1),
				(uint8_t*)(&var), &var_size
			);
			if (rval){
				fprintf(stderr, "Variable '%s' has not been declared.\n", $1);
				goto assignment_end;
			}
			else {
#ifdef DEBUG
				printf("Found variable: %s of type: %d\n", $1, var.type);
#endif
			}
		}

		switch(var.type){
			case BYTE: var.byte_value = (uint8_t)$3; break;
			case INT: var.int_value = (int32_t)$3; break;
			case UINT: var.int_value = (uint32_t)$3; break;
			case LONG: var.long_value = (int64_t)$3; break;
			case ULONG: var.long_value = (uint64_t)$3; break;
			case FLOAT: var.float_value = (float)$3; break;
			case DOUBLE: var.double_value = (double)$3; break;
			// case BOOL: var.bool_value = (uint8_t)$3; break;
			// case STRING: var.string_value = ()$3; break;
		}

		int rval = map_put(
			variables,
			(uint8_t*)$1, strlen($1),
			(uint8_t*)(&var), sizeof(Variable)
		);
		if (rval)
			fprintf(stderr, "out of memory for variables.\n");
		else
			printf("assignment: %s = %f\n", $1, $3);

assignment_end:
		free($1);
	}

command
	: QUIT { exit(0); }
	| EXIT { exit(0); }
	| IDENTIFIER
	{
		Variable var;
		size_t var_size;
		{
			int rval = map_get(
				variables,
				(uint8_t*)$1, strlen($1),
				(uint8_t*)(&var), &var_size
			);
			if (rval){
				fprintf(stderr, "Variable '%s' has not been declared.\n", $1);
				goto command_end;
			}
			else {
#ifdef DEBUG
				printf("Found variable: %s of type: %d\n", $1, var.type);
#endif
			}
		}

		switch(var.type){
			case BYTE: printf("%x\n", var.byte_value); break;
			case INT: printf("%d\n", var.int_value); break;
			case UINT: printf("%u\n", var.int_value); break;
			case LONG: printf("%ld\n", var.long_value); break;
			case ULONG: printf("%lu\n", var.long_value); break;
			case FLOAT: printf("%f\n", var.float_value); break;
			case DOUBLE: printf("%f\n", var.double_value); break;
			// case BOOL: var.bool_value = (uint8_t)$3; break;
			// case STRING: var.string_value = ()$3; break;
		}

command_end:
		free($1);
	}
	;

type
	: BYTE { $$ = BYTE; }
	| INT { $$ = INT; }
	| UINT { $$ = UINT; }
	| LONG { $$ = LONG; }
	| ULONG { $$ = ULONG; }
	| FLOAT { $$ = FLOAT; }
	| DOUBLE { $$ = DOUBLE; }
	| BOOL { $$ = BOOL; }
	| STRING { $$ = STRING; }
	;
