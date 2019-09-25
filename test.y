
%{
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "hash.h"

int yyparse();
int yylex();

Map *variables = NULL;

void yyerror(const char *str){
	fprintf(stderr, "Error: %s\n", str);
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
	float number;
	char *str;
}
%type <str> WORD
%type <str> STRING_LITERAL
%type <number> expression NUMBER
%token UNDERLINE NEWLINE WORD NUMBER STRING_LITERAL PRINT
%left '+' '-'

%%

program
	: %empty
	| program line ';'
	| program line NEWLINE
	;

line
	: expression
	{
		printf("%f\n", $1);
	}
	;

expression
	: NUMBER 
	| expression '+' expression { $$ = $1 + $3; }
	| expression '-' expression { $$ = $1 - $3; }
	| expression '*' expression { $$ = $1 * $3; }
	| expression '/' expression { $$ = $1 / $3; }
	| '-' expression { $$ = -$2; }
	| expression '^' expression { $$ = pow($1, $3); }
	| '(' expression ')' { $$ = $2; }
	;

assignment
	: WORD '=' NUMBER
	{
		float *p = &($3);
		if (map_put(variables, $1, strlen($1), (uint8_t*)p, sizeof(float))){
			fprintf(stderr, "out of memory for variables.\n");
		}
		printf("Command: %s = %f\n", $1, $3);
		free($1);
	}
	;

command
	: PRINT '(' WORD ')'
	{
		float *p;
		size_t size;
		if(map_get(variables, $3, strlen($3), (uint8_t*)p, &size)){
			fprintf(stderr, "out of memory for variables.\n");
		}
		printf("%f\n", *p);
		free($3);
	}
	;
