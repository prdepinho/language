
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

void yyerror(const char *str) { /* fprintf(stderr, "Error: %s\n", str); */ }

int yywrap() { return 1; }

int main() {
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
%type <variable> expression

%token UNDERLINE NEWLINE IDENTIFIER NUMBER STRING_LITERAL PRINT BYTE INT UINT LONG ULONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT TRUE FALSE

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
		Variable variable = $2;
		print_variable(variable);
	}
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
		Variable var = $5;
		declare_variable(identifier, type);
		assign_variable(identifier, var);
		free(identifier);
	}
	;

assignment
	: IDENTIFIER '=' expression
	{
		char *identifier = $1;
		Variable var = $3;
		assign_variable(identifier, var);
		free(identifier);
	}
	;

expression
	: NUMBER
	{
		Variable var;
		var.type = TYPE_DOUBLE;
		var.double_value = $1;
		$$ = var;
	}
	| STRING_LITERAL
	{
		Variable var;
		set_string_literal(&var, $1);
		free($1);
		$$ = var;
	}
	| boolean
	{
		Variable var;
		var.type = TYPE_BOOL;
		var.bool_value = $1;
		$$ = var;
	}
	| IDENTIFIER
	{
		Variable var;
		get_variable($1, &var);
		free($1);
		$$ = var;
	}
	| '-' expression
	{
		Variable var = $2;
		switch(var.type) {
		case TYPE_BYTE:      var.byte_value *= -1; break;
		case TYPE_INT:       var.int_value *= -1; break;
		case TYPE_UINT:      printf("Cannot have negative uint.\n"); return 1; break;
		case TYPE_LONG:      var.long_value *= -1; break;
		case TYPE_ULONG:     printf("Cannot have negative ulong.\n"); return 1; break;
		case TYPE_FLOAT:     var.float_value *= -1; break;
		case TYPE_DOUBLE:    var.double_value *= -1; break;
		case TYPE_BOOL:      printf("Cannot have negative bool.\n"); return 1; break;
		case TYPE_STRING:    printf("Cannot have negative string.\n"); return 1; break;
		}
		$$ = var;
	}
	| '(' expression ')'
	{
		$$ = $2;
	}
	| expression '+' expression
	{
		Variable lvar = $1;
		Variable rvar = $3;

		switch(lvar.type) {
		case TYPE_BYTE:      lvar.byte_value = (uint8_t) (get_number(lvar) + get_number(rvar)); break;
		case TYPE_INT:       lvar.int_value = (int32_t) (get_number(lvar) + get_number(rvar)); break;
		case TYPE_UINT:      lvar.uint_value = (uint32_t) (get_number(lvar) + get_number(rvar)); break;
		case TYPE_LONG:      lvar.long_value = (int64_t) (get_number(lvar) + get_number(rvar)); break;
		case TYPE_ULONG:     lvar.ulong_value = (uint64_t) (get_number(lvar) + get_number(rvar)); break;
		case TYPE_FLOAT:     lvar.float_value = (float) (get_number(lvar) + get_number(rvar)); break;
		case TYPE_DOUBLE:    lvar.double_value = (double) (get_number(lvar) + get_number(rvar)); break;
		case TYPE_BOOL:      printf("Cannot operate on bool.\n"); break;
		case TYPE_STRING:    printf("Cannot operate on string.\n"); break;
		}
		$$ = lvar;
	}
	| expression '-' expression
	{
		Variable lvar = $1;
		Variable rvar = $3;

		switch(lvar.type) {
		case TYPE_BYTE:      lvar.byte_value = (uint8_t) (get_number(lvar) - get_number(rvar)); break;
		case TYPE_INT:       lvar.int_value = (int32_t) (get_number(lvar) - get_number(rvar)); break;
		case TYPE_UINT:      lvar.uint_value = (uint32_t) (get_number(lvar) - get_number(rvar)); break;
		case TYPE_LONG:      lvar.long_value = (int64_t) (get_number(lvar) - get_number(rvar)); break;
		case TYPE_ULONG:     lvar.ulong_value = (uint64_t) (get_number(lvar) - get_number(rvar)); break;
		case TYPE_FLOAT:     lvar.float_value = (float) (get_number(lvar) - get_number(rvar)); break;
		case TYPE_DOUBLE:    lvar.double_value = (double) (get_number(lvar) - get_number(rvar)); break;
		case TYPE_BOOL:      printf("Cannot operate on bool.\n"); break;
		case TYPE_STRING:    printf("Cannot operate on string.\n"); break;
		}
		$$ = lvar;
	}
	| expression '*' expression
	{
		Variable lvar = $1;
		Variable rvar = $3;

		switch(lvar.type) {
		case TYPE_BYTE:      lvar.byte_value = (uint8_t) (get_number(lvar) * get_number(rvar)); break;
		case TYPE_INT:       lvar.int_value = (int32_t) (get_number(lvar) * get_number(rvar)); break;
		case TYPE_UINT:      lvar.uint_value = (uint32_t) (get_number(lvar) * get_number(rvar)); break;
		case TYPE_LONG:      lvar.long_value = (int64_t) (get_number(lvar) * get_number(rvar)); break;
		case TYPE_ULONG:     lvar.ulong_value = (uint64_t) (get_number(lvar) * get_number(rvar)); break;
		case TYPE_FLOAT:     lvar.float_value = (float) (get_number(lvar) * get_number(rvar)); break;
		case TYPE_DOUBLE:    lvar.double_value = (double) (get_number(lvar) * get_number(rvar)); break;
		case TYPE_BOOL:      printf("Cannot operate on bool.\n"); break;
		case TYPE_STRING:    printf("Cannot operate on string.\n"); break;
		}
		$$ = lvar;
	}
	| expression '/' expression
	{
		Variable lvar = $1;
		Variable rvar = $3;

		switch(lvar.type) {
		case TYPE_BYTE:      lvar.byte_value = (uint8_t) (get_number(lvar) / get_number(rvar)); break;
		case TYPE_INT:       lvar.int_value = (int32_t) (get_number(lvar) / get_number(rvar)); break;
		case TYPE_UINT:      lvar.uint_value = (uint32_t) (get_number(lvar) / get_number(rvar)); break;
		case TYPE_LONG:      lvar.long_value = (int64_t) (get_number(lvar) / get_number(rvar)); break;
		case TYPE_ULONG:     lvar.ulong_value = (uint64_t) (get_number(lvar) / get_number(rvar)); break;
		case TYPE_FLOAT:     lvar.float_value = (float) (get_number(lvar) / get_number(rvar)); break;
		case TYPE_DOUBLE:    lvar.double_value = (double) (get_number(lvar) / get_number(rvar)); break;
		case TYPE_BOOL:      printf("Cannot operate on bool.\n"); break;
		case TYPE_STRING:    printf("Cannot operate on string.\n"); break;
		}
		$$ = lvar;
	}
	| expression '%' expression
	{
		Variable lvar = $1;
		Variable rvar = $3;

		switch(lvar.type) {
		case TYPE_BYTE:      lvar.byte_value = (uint8_t) ((int) get_number(lvar) % (int) get_number(rvar)); break;
		case TYPE_INT:       lvar.int_value = (int32_t) ((int) get_number(lvar) % (int) get_number(rvar)); break;
		case TYPE_UINT:      lvar.uint_value = (uint32_t) ((int) get_number(lvar) % (int) get_number(rvar)); break;
		case TYPE_LONG:      lvar.long_value = (int64_t) ((int) get_number(lvar) % (int) get_number(rvar)); break;
		case TYPE_ULONG:     lvar.ulong_value = (uint64_t) ((int) get_number(lvar) % (int) get_number(rvar)); break;
		case TYPE_FLOAT:     lvar.float_value = (float) ((int) get_number(lvar) % (int) get_number(rvar)); break;
		case TYPE_DOUBLE:    lvar.double_value = (double) ((int) get_number(lvar) % (int) get_number(rvar)); break;
		case TYPE_BOOL:      printf("Cannot operate on bool.\n"); break;
		case TYPE_STRING:    printf("Cannot operate on string.\n"); break;
		}
		$$ = lvar;
	}
	| expression '^' expression
	{
		Variable lvar = $1;
		Variable rvar = $3;

		switch(lvar.type) {
		case TYPE_BYTE:      lvar.byte_value = (uint8_t) pow(get_number(lvar), get_number(rvar)); break;
		case TYPE_INT:       lvar.int_value = (int32_t) pow(get_number(lvar), get_number(rvar)); break;
		case TYPE_UINT:      lvar.uint_value = (uint32_t) pow(get_number(lvar), get_number(rvar)); break;
		case TYPE_LONG:      lvar.long_value = (int64_t) pow(get_number(lvar), get_number(rvar)); break;
		case TYPE_ULONG:     lvar.ulong_value = (uint64_t) pow(get_number(lvar), get_number(rvar)); break;
		case TYPE_FLOAT:     lvar.float_value = (float) pow(get_number(lvar), get_number(rvar)); break;
		case TYPE_DOUBLE:    lvar.double_value = (double) pow(get_number(lvar), get_number(rvar)); break;
		case TYPE_BOOL:      printf("Cannot operate on bool.\n"); break;
		case TYPE_STRING:    printf("Cannot operate on string.\n"); break;
		}
		$$ = lvar;
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
