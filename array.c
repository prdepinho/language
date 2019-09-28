#include "array.h"

Array *array_new(size_t data_size, size_t initial_length){
	Array *array = (Array*) malloc(sizeof(Array));
	if (array == NULL)
		return NULL;

	array->length = 0;
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


int array_set(int index, void *element){
	memcpy(array->heap + index * array->data_size, element, array->data_size);
	return 0;
}

int array_get(int index, void *out_element){
	memcpy(out_element, array->heap + index * array->data_size, array->data_size);
	return 0;
}

int array_push(void *element){
	return 0;
}

int array_peek(void *out_element){
	return 0;
}

int array_pop(void *out_element){
	return 0;
}

