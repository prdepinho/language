
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "hash.h"

int yyparse();
int yylex();

Map *variables = NULL;

typedef enum Type {
	TYPE_BYTE = 0,  
	TYPE_INT = 1,
	TYPE_UINT = 2,
	TYPE_LONG = 3,
	TYPE_ULONG = 4,
	TYPE_FLOAT = 5,
	TYPE_DOUBLE = 6,
	TYPE_BOOL = 7,
	TYPE_STRING = 8
} Type;

typedef struct Variable {
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

void declare_variable(const char *identifier, int type) {
	Variable var = {type, 0};
	int rval = map_put(
		variables,
		identifier, strlen(identifier),
		&var, sizeof(Variable)
	);
	if (rval)
		fprintf(stderr, "out of memory for variables.\n");
	else{
#ifdef DEBUG
		printf("declaration: %d %s\n", type, identifier);
#endif
	}
}

int assign_number(const char *identifier, double number) {
	Variable var;
	size_t var_size;
	{
		int rval = map_get(
			variables,
			identifier, strlen(identifier),
			&var, &var_size
		);
		if (rval){
			fprintf(stderr, "Variable '%s' has not been declared.\n", identifier);
			return 1;
		}
		else {
#ifdef DEBUG
			printf("Found variable: %s of type: %d\n", identifier, var.type);
#endif
		}
	}

	switch(var.type){
		case TYPE_BYTE:      var.byte_value = (uint8_t)number; break;
		case TYPE_INT:       var.int_value = (int32_t)number; break;
		case TYPE_UINT:      var.int_value = (uint32_t)number; break;
		case TYPE_LONG:      var.long_value = (int64_t)number; break;
		case TYPE_ULONG:     var.long_value = (uint64_t)number; break;
		case TYPE_FLOAT:     var.float_value = (float)number; break;
		case TYPE_DOUBLE:    var.double_value = (double)number; break;
		case TYPE_BOOL:      printf("Cannot assign bool to number\n"); return 2; break;
		case TYPE_STRING:    printf("Cannot assign string to number\n"); return 2; break;
	}

	int rval = map_put(
		variables,
		identifier, strlen(identifier),
		&var, sizeof(Variable)
	);
	if (rval)
		fprintf(stderr, "out of memory for variables.\n");
	else {
#ifdef DEBUG
		printf("assignment: %s = %f\n", identifier, number);
#endif
	}
	return 0;
}

int assign_string_literal(const char* identifier, const char *string_literal) {
	Variable var;
	size_t var_size;
	{
		int rval = map_get(
			variables,
			identifier, strlen(identifier),
			&var, &var_size
		);
		if (rval){
			fprintf(stderr, "Variable '%s' has not been declared.\n", identifier);
			return 1;
		}
		else {
#ifdef DEBUG
			printf("Found variable: %s of type: %d\n", identifier, var.type);
#endif
		}
	}

	if (var.type != TYPE_STRING){
		printf("Variable %s is not of type string\n", identifier);
		return 2;
	}

	size_t string_size = strlen(string_literal);
	var.string_value = (char*) malloc(string_size * sizeof(char));
	if (var.string_value == NULL)
		return 1;

	memcpy(var.string_value, string_literal, string_size * sizeof(char));

	int rval = map_put(
		variables,
		identifier, strlen(identifier),
		&var, sizeof(Variable)
	);
	if (rval)
		fprintf(stderr, "out of memory for variables.\n");
	else {
#ifdef DEBUG
		printf("assignment: %s = %f\n", identifier, number);
#endif
	}
	return 0;
}

int assign_boolean(const char *identifier, int bool_value) {
	Variable var;
	size_t var_size;
	{
		int rval = map_get(
			variables,
			identifier, strlen(identifier),
			&var, &var_size
		);
		if (rval){
			fprintf(stderr, "Variable '%s' has not been declared.\n", identifier);
			return 1;
		}
		else {
#ifdef DEBUG
			printf("Found variable: %s of type: %d\n", identifier, var.type);
#endif
		}
	}

	if (var.type != TYPE_BOOL){
		printf("Variable %s is not of type bool\n", identifier);
		return 2;
	}

	var.bool_value = bool_value;

	int rval = map_put(
		variables,
		identifier, strlen(identifier),
		&var, sizeof(Variable)
	);
	if (rval)
		fprintf(stderr, "out of memory for variables.\n");
	else {
#ifdef DEBUG
		printf("assignment: %s = %f\n", identifier, number);
#endif
	}
	return 0;
}

int get_value(const char *identifier, double *out_value) {
	Variable var;
	size_t var_size;
	{
		int rval = map_get(
			variables,
			identifier, strlen(identifier),
			&var, &var_size
		);
		if (rval){
			fprintf(stderr, "Variable '%s' has not been declared.\n", identifier);
			return 1;
		}
		else {
#ifdef DEBUG
			printf("Found variable: %s of type: %d\n", identifier, var.type);
#endif
		}
	}

	switch(var.type){
		case TYPE_BYTE:      *out_value = (double) var.byte_value; break;
		case TYPE_INT:       *out_value = (double) var.int_value; break;
		case TYPE_UINT:      *out_value = (double) var.int_value; break;
		case TYPE_LONG:      *out_value = (double) var.long_value; break;
		case TYPE_ULONG:     *out_value = (double) var.long_value; break;
		case TYPE_FLOAT:     *out_value = (double) var.float_value; break;
		case TYPE_DOUBLE:    *out_value = var.double_value; break;
		case TYPE_BOOL:      printf("Cannot get number from bool.\n"); return 2; break;
		case TYPE_STRING:    printf("Cannot get number from string.\n"); return 2; break;
	}

	return 0;
}

void exit_program(int exit_code) {
	for (int i = 0; i < variables->length; ++i){
		void *key = variables->buckets[i].key;
		if(key != 0){
			Variable *var = (Variable*) variables->buckets[i].value;
			if (var->type == TYPE_STRING && var->string_value != NULL){
#ifdef DEBUG
				printf("Freed string %s: %s\n", (char*) key, var->string_value);
#endif
				free(var->string_value);
				var->string_value = NULL;
			}
		}
	}
	map_delete(variables);
	exit(exit_code);
}

void yyerror(const char *str){ /* fprintf(stderr, "Error: %s\n", str); */ }

int yywrap(){ return 1; }

int main(){
	variables = map_new(2);
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
	double number;
	char *str;
}
%type <str> IDENTIFIER
%type <str> STRING_LITERAL
%type <integer> type
%type <integer> boolean
%type <number> NUMBER
%type <number> expression
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
	| program error NEWLINE
	{
		printf("Error\n");
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
