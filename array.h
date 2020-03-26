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

/* Delete array. */
void array_delete(Array *array);


/* Set an element at an index in the array. Return the pointer to it. A negative index works backwards. */
void *array_set(Array *array, int index, void *element);

/* Get an element at an index in the array. Return the pointer to it. A negative index works backwards. */
void *array_get(Array *array, int index, void *out_element);


/* Push an element to the array. Return the element's index. */
long array_push(Array *array, void *element);

/* Get the element at the end of the array. Return the element's index. */
long array_peek(Array *array, void *out_element);

/* Get and remove the element at the end of the array. Return the element's index. */
long array_pop(Array *array, void *out_element);

/* Returns 1 if element is in the array, otherwise return 0. */
int array_contains(Array *array, void *element);

#endif /* __array_h__ */
