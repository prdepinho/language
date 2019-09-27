
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
		int8_t bool_value;
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

		int rval = map_get(
			variables,
			(uint8_t*)$1, strlen($1),
			(uint8_t*)(&var), &var_size
		);
		if (rval){
			fprintf(stderr, "Error reading variable\n");
			goto end;
		}
		else
			printf("Found variable: %s of type: %d\n", $1, var.type);
			
		// rval = map_put(
		// 	variables,
		// 	(uint8_t*)$2, strlen($2),
		// 	(uint8_t*)(&var), sizeof(Variable)
		// );
		// if (rval)
		// 	fprintf(stderr, "out of memory for variables.\n");
		// else
			printf("assignment: %s = %f\n", $1, $3);

end:
		free($1);
	}

command
	: QUIT { exit(0); }
	| EXIT { exit(0); }
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
