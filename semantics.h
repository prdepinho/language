#ifndef __semantics_h__
#define __semantics_h__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include "hash.h"

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
	Type type;
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

int init();

void finalize();

Map *get_variables();

void declare_variable(const char *identifier, int type);

int assign_number(const char *identifier, double number);

int assign_string_literal(const char* identifier, const char *string_literal);

int assign_boolean(const char *identifier, int bool_value);

int get_value(const char *identifier, double *out_value);

void exit_program(int exit_code);

#endif /* __semantics_h__ */
