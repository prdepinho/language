
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

// Scope handling
size_t stack_track;			// keep track in compile time of the size of the machine stack.
Array *stack_scope;			// keeps track of machine stack positions for each scope level.
Array *identifiers_scope;	// keeps track of identifiers positions for each scope level.
Array *identifier_stack;	// keeps track of identifiers, that is, variable, labels, function names. All identifiers are in the machine stack.

// Structured control flow handing
Array *control_stack;		// keeps track of the command address where control flow structures begin.

Map *variables;				// maps variable names with their place in the machine stack. Labels are treated as variables.
MapArray *labels;			// maps jump labels and the list of their positions in the commands.
Array *strings;				// keeps track of all identifiers and string literals in the program. These are strings dynamically allocated at lex level, so we want to keep their pointers to be able to free them.
size_t line_count;			// keeps track of source code lines.
bool compilation_success;

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
	printf("identifier_stack: %lu\n", identifier_stack->length);
	for (int i = 0; i < identifier_stack->length; i++) {
		
		char *vname = NULL;
		array_get(identifier_stack, i, &vname);

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
	if (identifier_stack != NULL)
		array_delete(identifier_stack);
	if (labels != NULL)
		map_array_delete(labels);
	if (control_stack != NULL)
		array_delete(control_stack);

	if (strings != NULL) {
		for (int i = 0; i < strings->length; i++) {
			char *str = NULL;
			array_get(strings, i, &str);
			free(str);
		}
		array_delete(strings);
	}

	fclose(yyin);
	printf("Good bye.\n");
	exit(status_code);
}

int yyparse();
int yylex();

void yyerror(const char *str) {
	fprintf(stderr, "YYError: %s. Line %lu.\n", str, line_count);
}

#define PRINT_ERROR(...) {													\
	fprintf(stderr, "Error (line %lu): ", line_count);						\
	fprintf(stderr, __VA_ARGS__);											\
	fprintf(stderr, "\n");													\
	compilation_success = false;											\
}

#define CRITICAL_ERROR(...) {												\
	fprintf(stderr, "Critical Error (line %lu): ", line_count);				\
	fprintf(stderr, __VA_ARGS__);											\
	fprintf(stderr, "\n");													\
	fprintf(stderr, "Exiting program with status code -1.\n");				\
	exit_program(-1);														\
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
		line_count = 1;
		compilation_success = true;

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

		identifier_stack = array_new(sizeof(char *), 0);
		if (identifier_stack == NULL) {
			printf("identifier_stack is null.\n");
			rval = 1;
			goto main_end;
		}

		labels = map_array_new(2, sizeof(Addr), 0);
		if (labels == NULL) {
			printf("Labels is null.\n");
			rval = 1;
			goto main_end;
		}

		strings = array_new(sizeof(char *), 0);
		if (strings == NULL) {
			printf("Identifiers is null.\n");
			rval = 1;
			goto main_end;
		}

		control_stack = array_new(sizeof(Addr), 0);
		if (control_stack == NULL) {
			printf("Control stack is null.\n");
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

%token UNDERLINE NEWLINE IDENTIFIER INT_LITERAL FLOAT_LITERAL HEX_LITERAL STRING_LITERAL PRINT BYTE INT UINT LONG ULONG FLOAT DOUBLE BOOL STRING PURE QUIT EXIT TRUE FALSE STACK COMMANDS VM_SET_BYTE VM_SET_INT VM_SET_UINT VM_SET_FLOAT VM_MALLOC VM_FREE VM_ADD VM_SUB VM_MULT VM_DIV VM_JUMP VM_JCOND VM_POP VM_PUSH VM_PUSH_BYTE VM_PUSH_INT VM_PUSH_UINT VM_PUSH_FLOAT VM_AND VM_OR VM_XOR VM_NOT VM_EXIT DUMP GOTO NOT AND OR IF WHILE EQUAL NEQUAL GEQ LEQ CONTINUE BREAK RETURN
%left '+' '-'
%left '*' '/' '%'
%left '!' NOT
%left '&' AND 
%left OR XOR '|' '^'
%left EQUAL NEQUAL LEQ GEQ '<' '>'

%%

program
	: sentences
	{
		if (!interactive_mode) {
			printf("Finished compiling.\n");
			if (compilation_success) {
				printf("Compilation successful.\n");
				printf("Now running.\n");
				vm_run(vm);
			}
			else {
				printf("Compilation Failed. Exiting with status -1.\n");
				exit_program(-1);
			}
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
			default:
				printf("no type\n");
			}
		}
	}
	| sentences error end_sentence
	{
		printf("Error at line %lu\n", line_count);
	}
	| sentences label end_sentence
	| sentences end_sentence
	| sentences function_declaration end_sentence
	| sentences command end_sentence
	| sentences vm_command end_sentence
	{
		// if it is interactive mode, execute after each line.
		if (interactive_mode) {
			vm_run(vm);
		}
	}
	| sentences GOTO IDENTIFIER end_sentence
	{
		// if label is already defined in variables, set jump to that label's value;
		// else, set jump to 0, and push its commands index to labels.

		// TODO: don't forget to pop stack variables when exiting scopes.
		// Entering scopes should be a problem when skipping variable initializations.

		char *identifier = $3;

		Addr addr;
		size_t size;
		if (map_get(
			variables,
			identifier, strlen(identifier),
			&addr, &size
		)) {
			vm_push_cmd_jump(vm, addr);
		}
		else {
			vm_push_cmd_jump(vm, 0);

			Addr jump_addr = vm->commands->length - 1;
			if (map_array_push(labels, identifier, strlen(identifier), &jump_addr) < 0) {
				CRITICAL_ERROR("label push failed.");
			}
		}
	}
	| sentences if_block
	| sentences while_block
	| sentences block
	| sentences CONTINUE
	| sentences BREAK
	;


if_block
	: if_statement block
	{
		// lookup the address of the conditional jump and set it to jump here.
		Addr index = 0;
		array_pop(control_stack, &index);

		Command command;
		array_get(vm->commands, index, &command);
		command.addr = vm->commands->length;
		array_set(vm->commands, index, &command);

		vm_push_cmd_pop(vm);
		stack_track--;
	}
	;

if_statement
	: IF expression
	{
		// set a jump conditional to 0.
		// at the end of the if block, retroactively set that 0 as the actual command address.
		Addr bool_addr = $2;
		
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_not(vm, bool_addr, stack_track);

		Addr if_addr = vm->commands->length;
		if (array_push(control_stack, &if_addr) < 0) {
			CRITICAL_ERROR("If control_stack push failed.");
		}
		vm_push_cmd_jcond(vm, 0, stack_track);
	}
	;


while_block
	: while_statement block
	{
		Addr index = 0;
		array_pop(control_stack, &index);

		Command command;
		array_get(vm->commands, index, &command);
		command.addr = vm->commands->length + 2;
		array_set(vm->commands, index, &command);

		vm_push_cmd_pop(vm);
		vm_push_cmd_jump(vm, index - 3);
		vm_push_cmd_pop(vm);
		stack_track--; // only one, because one pop when looping, one pop when done
	}
	;

while_statement
	: WHILE expression
	{
		Addr bool_addr = $2;
		
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_not(vm, bool_addr, stack_track);

		Addr while_addr = vm->commands->length;
		if (array_push(control_stack, &while_addr) < 0) {
			CRITICAL_ERROR("While control_stack push failed.");
		}
		vm_push_cmd_jcond(vm, 0, stack_track);
	}
	;


block
	: start_block sentences end_block
	;
start_block
	: '{'
	{
		size_t level = array_push(stack_scope, &stack_track);
		array_push(identifiers_scope, &identifier_stack->length);
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

		for (int i = identifier_stack->length; i > position; i--) {
			// remove variables from stack and from map (compile time)
			char *vname = NULL;
			array_pop(identifier_stack, &vname);
			map_remove(variables, vname, strlen(vname));
		}
	}
	;


function_declaration
	: IDENTIFIER  param_list ':' type
	{
		char *identifier = $1;
		printf("function declaration\n");
	}
	;

param_list
	: param_list_content ')'

param_list_content
	: param_list_content ',' IDENTIFIER ':' type
	{
		char *identifier = $3;
	}
	| '(' IDENTIFIER ':' type
	{
		char *identifier = $2;
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
			PRINT_ERROR("Identifier '%s' already declared.", identifier);
		}

		array_push(identifier_stack, &identifier);

		if (!map_put (
			variables,
			identifier, strlen(identifier),
			&vm->commands->length, sizeof(vm->commands->length)
		)){
			CRITICAL_ERROR("Could not push identifier %s to variables.", identifier);
		}

		if (map_array_contains_array(labels, identifier, strlen(identifier))) {
			Array *array = NULL;
			map_array_get_array(labels, identifier, strlen(identifier), &array);

			for (int i = 0; i < array->length; i++) {
				Addr index = 0;
				array_get(array, i, &index);

				Command command;
				array_get(vm->commands, index, &command);
				command.addr = vm->commands->length;
				array_set(vm->commands, index, &command);
			}
		}
	}

declaration
	: IDENTIFIER ':' type
	{
		char *identifier = $1;
		int type = $3;

		Addr addr = 0;
		size_t size = 0;
		if (map_get(
			variables,
			identifier, strlen(identifier),
			&addr, &size
		)) {
			PRINT_ERROR("Identifier '%s' already declared.", identifier);
		}
		else {
			array_push(identifier_stack, &identifier);

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
	}
	| IDENTIFIER ':' type '=' expression
	{
		char *identifier = $1;
		int type = $3;
		Addr rregaddr = $5;

		Addr addr = 0;
		size_t size = 0;
		if (map_get(
			variables,
			identifier, strlen(identifier),
			&addr, &size
		)) {
			PRINT_ERROR("Identifier '%s' already declared.", identifier);
		}
		else {
			array_push(identifier_stack, &identifier);

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
			PRINT_ERROR("Identifier '%s' undeclared.", identifier);
		}
		else {
			vm_push_cmd_assign(vm, lregaddr, rregaddr);
		}
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
	}
	| boolean
	{
		$$ = $1;
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
			PRINT_ERROR("Identifier '%s' undeclared.", identifier);
			addr = null_addr;
		}

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
		// rest
	}
	| expression '&' expression
	{
		// bitwise and
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_and(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| expression '|' expression
	{
		// bitwise or
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_or(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| '!' expression
	{
		// bitwise not
		Addr rvaladdr = $2;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_not(vm, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| expression '^' expression
	{
		// bitwise xor
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_xor(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| expression AND expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_and(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| expression OR expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_or(vm, lvaladdr, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| NOT expression
	{
		Addr rvaladdr = $2;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_not(vm, rvaladdr, stack_track);
		$$ = stack_track;
	}
	| expression '<' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_less(vm, lvaladdr, rvaladdr, stack_track);

		$$ = stack_track;
	}
	| expression '>' expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_greater(vm, lvaladdr, rvaladdr, stack_track);

		$$ = stack_track;
	}
	| expression EQUAL expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_equal(vm, lvaladdr, rvaladdr, stack_track);

		$$ = stack_track;
	}
	| expression NEQUAL expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_nequal(vm, lvaladdr, rvaladdr, stack_track);

		$$ = stack_track;
	}
	| expression LEQ expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_leq(vm, lvaladdr, rvaladdr, stack_track);

		$$ = stack_track;
	}
	| expression GEQ expression
	{
		Addr lvaladdr = $1;
		Addr rvaladdr = $3;
		stack_track++;
		vm_push_cmd_push(vm);
		vm_push_cmd_geq(vm, lvaladdr, rvaladdr, stack_track);

		$$ = stack_track;
	}
	;

command
	: PRINT IDENTIFIER
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
			PRINT_ERROR("Identifier '%s' undeclared.", identifier);
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
	| VM_EXIT
	{
		vm_push_cmd_exit(vm);
	}
	| EXIT
	{
		if (interactive_mode)
			exit_program(0);
		else
			vm_push_cmd_exit(vm);
	}
	| QUIT
	{
		if (interactive_mode)
			exit_program(0);
		else
			vm_push_cmd_exit(vm);
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
	{
		line_count++;
	}
	| ';'
	;
