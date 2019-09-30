#ifndef __ARRAY_H__
#define __ARRAY_H__

#include <stdlib.h>
#include <string.h>

/* A self-expanding array of bytes. */

typedef struct Array {
	void *heap;
	size_t length;
	size_t capacity;
	size_t data_size;
} Array;

/* Set initial_length to 0 to use it as a stack. */
Array *array_new(size_t data_size, size_t initial_length);
void array_delete(Array *array);

int array_set(Array *array, int index, void *element);
int array_get(Array *array, int index, void *out_element);

int array_push(Array *array, void *element);
int array_peek(Array *array, void *out_element);
int array_pop(Array *array, void *out_element);

#endif /* __array_h__ */
