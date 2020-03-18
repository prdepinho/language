#include "semantics.h"

Map *variables = NULL;

double get_number(Variable var) {
	switch(var.type){ \
	case TYPE_BYTE:   return (double) var.byte_value; break;
	case TYPE_INT:    return (double) var.int_value; break;
	case TYPE_UINT:   return (double) var.uint_value; break;
	case TYPE_LONG:   return (double) var.long_value; break;
	case TYPE_ULONG:  return (double) var.ulong_value; break;
	case TYPE_FLOAT:  return (double) var.float_value; break;
	case TYPE_DOUBLE: return var.double_value; break;
	case TYPE_BOOL: return 0.f; break;
	case TYPE_STRING: return 0.f; break;
	}
	return 0.f;
}

int set_string_literal(Variable *var, const char *string_literal) {
	size_t string_size = strlen(string_literal);
	var->type = TYPE_STRING;
	var->string_value = (char*) malloc(string_size * sizeof(char));
	if (var->string_value == NULL)
		return 1;
	memcpy(var->string_value, string_literal, string_size * sizeof(char));
	return 0;
}

int init(){
	variables = map_new(2);
	if (variables == NULL) {
		return 1;
	}
	return 0;
}

void finalize(){
	map_delete(variables);
}

Map *get_variables(){
	return variables;
}

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

int assign_variable(const char *identifier, const Variable var) {
	Variable declared_var;
	size_t var_size;
	{
		int rval = map_get(
			variables,
			identifier, strlen(identifier),
			&declared_var, &var_size
		);
		if (rval){
			fprintf(stderr, "Variable '%s' has not been declared.\n", identifier);
			return 1;
		}
	}

	switch(var.type) {
		case TYPE_BOOL:
			switch(declared_var.type) {
				case TYPE_BOOL:      declared_var.bool_value = var.bool_value; break;
				case TYPE_STRING:    printf("Cannot assign bool to string.\n"); return 2; break;
				default:			 printf("Cannot assign bool to number.\n"); return 2; break;
			}
			break;
		case TYPE_STRING:
			switch(declared_var.type) {
				case TYPE_STRING:    declared_var.string_value = var.string_value; break;
				case TYPE_BOOL:      printf("Cannot assign string to bool.\n"); return 2; break;
				default:			 printf("Cannot assign string to number.\n"); return 2; break;
			}
			break;
		default:
			switch(declared_var.type) {
				case TYPE_BYTE:      declared_var.byte_value = (uint8_t) get_number(var); break;
				case TYPE_INT:       declared_var.int_value = (int32_t) get_number(var); break;
				case TYPE_UINT:      declared_var.int_value = (uint32_t) get_number(var); break;
				case TYPE_LONG:      declared_var.long_value = (int64_t) get_number(var); break;
				case TYPE_ULONG:     declared_var.long_value = (uint64_t) get_number(var); break;
				case TYPE_FLOAT:     declared_var.float_value = (float) get_number(var); break;
				case TYPE_DOUBLE:    declared_var.double_value = (double) get_number(var); break;
				case TYPE_BOOL:      printf("Cannot assign number to bool\n"); return 2; break;
				case TYPE_STRING:    printf("Cannot assign number to string\n"); return 2; break;
			}
			break;
	}

	int rval = map_put(
		variables,
		identifier, strlen(identifier),
		&declared_var, sizeof(Variable)
	);
	if (rval) {
		fprintf(stderr, "out of memory for variables.\n");
	}
	return 0;
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

int get_variable(const char *identifier, Variable *var) {
	size_t var_size;
	int rval = map_get(
		variables,
		identifier, strlen(identifier),
		var, &var_size
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

void print_variable(const Variable var) {
	switch(var.type){
		case TYPE_BYTE: printf("0x%x\n", var.byte_value); break;
		case TYPE_INT: printf("%d\n", var.int_value); break;
		case TYPE_UINT: printf("%u\n", var.int_value); break;
		case TYPE_LONG: printf("%ld\n", var.long_value); break;
		case TYPE_ULONG: printf("%lu\n", var.long_value); break;
		case TYPE_FLOAT: printf("%f\n", var.float_value); break;
		case TYPE_DOUBLE: printf("%f\n", var.double_value); break;
		case TYPE_BOOL: printf("%s (%u)\n", var.bool_value ? "true" : "false", var.bool_value); break;
		case TYPE_STRING: printf("%s\n", var.string_value); break;
	}
}

void _exit_program(int exit_code) {
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

