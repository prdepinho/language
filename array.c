#include "array.h"

static int array_extend(Array *array){
	size_t old_capacity = array->capacity;
	size_t new_capacity = (array->capacity > 0) ? array->capacity * 2 : 2;

	void *old_heap = array->heap;
	void *new_heap = malloc(new_capacity * array->data_size);
	if (new_heap == NULL)
		return 1;

	memcpy(new_heap, old_heap, old_capacity * array->data_size);
	free(old_heap);

	array->heap = new_heap;
	array->capacity = new_capacity;

	return 0;
}

Array *array_new(size_t data_size, size_t initial_length){
	Array *array = (Array*) malloc(sizeof(Array));
	if (array == NULL)
		return NULL;

	array->length = initial_length;
	array->capacity = initial_length;
	array->data_size = data_size;
	array->heap = malloc(array->length * array->data_size);
	if (array->heap == NULL) {
		free(array);
		return NULL;
	}

	memset(array->heap, 0, array->length * array->data_size);
	return array;
}

void array_delete(Array *array){
	free(array->heap);
	free(array);
}


int array_set(Array *array, int index, void *element){
	memcpy(array->heap + index * array->data_size, element, array->data_size);
	return 0;
}

int array_get(Array *array, int index, void *out_element){
	memcpy(out_element, array->heap + index * array->data_size, array->data_size);
	return 0;
}

int array_push(Array *array, void *element){
	if (array->capacity == array->length){
		int rval = array_extend(array);
		if (rval)
			return 1;
	}
	array_set(array, array->length++, element);
	return 0;
}

int array_peek(Array *array, void *out_element){
	if (array->length == 0)
		return 1;
	array_get(array, array->length -1, out_element);
	return 0;
}

int array_pop(Array *array, void *out_element){
	if (array->length == 0)
		return 1;
	array_get(array, --array->length, out_element);
	return 0;
}

