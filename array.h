#ifndef __ARRAY_H__
#define __ARRAY_H__

#include <stdlib.h>

typedef struct Array {
	void *heap;
	size_t length;
	size_t data_size;
} Array;

Array *array_new(size_t data_size, size_t initial_length);
void array_delete(Array *array);

int array_set(int index, void *element);
int array_get(int index, void *out_element);

int array_push(void *element);
int array_peek(void *out_element);
int array_pop(void *out_element);

#endif /* __array_h__ */
