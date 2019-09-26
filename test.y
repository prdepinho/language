
%{
#include <stdio.h>
#include <stdlib.h>
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
%type <str> IDENTIFIER
%type <str> STRING_LITERAL
%type <str> type
%type <number> NUMBER
%token UNDERLINE NEWLINE IDENTIFIER NUMBER STRING_LITERAL PRINT BYTE INT LONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT
%left '+' '-'

%%

program
	: %empty
	| program assignment NEWLINE
	| program command NEWLINE
	| program error NEWLINE
	{
		printf("Error\n");
	}
	;

assignment
	: type IDENTIFIER
	{
		printf("Declaration: %s %s\n", $1, $2);
	}
	;

command
	: QUIT { exit(0); }
	| EXIT { exit(0); }
	;

type
	: BYTE
	| INT
	| LONG
	| FLOAT
	| DOUBLE
	| BOOL
	| STRING
	;
