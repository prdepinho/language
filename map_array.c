#include "map_array.h"
#include <stdio.h>


MapArray *map_array_new(size_t map_initial_length, size_t array_element_size, size_t array_initial_length) {
	MapArray *map = (MapArray*) malloc(sizeof(MapArray));
	if (map == NULL)
		goto map_array_new_exception;

	map->map = map_new(map_initial_length);
	if (map->map == NULL)
		goto map_array_new_exception;

	map->array_element_size = array_element_size;
	map->array_initial_length = array_initial_length;
	return map;

map_array_new_exception:
	if (map->map != NULL)
		map_delete(map->map);
	if (map != NULL)
		free(map);
	return NULL;
}
void map_array_delete(MapArray *map) {
	for (int i = 0; i < map->map->length; i++) {
		if (map->map->buckets[i].key != 0) {
			Array *array = (Array*) map->map->buckets[i].value;
			array_delete(array);
		}
	}
	map_delete(map->map);
	free(map);
}

int map_array_contains(MapArray *map, const void *key, size_t klen) {
	void *value = NULL;
	size_t vlen = 0;
	return map_get(map->map, key, klen, &value, &vlen);
}

int map_array_get_array(MapArray *map,
		const void *key, size_t klen,
		Array **out_array)
{
	Array *array = NULL;
	size_t array_size = 0;
	if (!map_get(map->map, key, klen, &array, &array_size))
	{
		array = array_new(map->array_element_size, map->array_initial_length);
		if (array == NULL)
			return 0;
		if (!map_put(map->map, key, klen, &array, sizeof(array)))
			return 0;
	}
	*out_array = array;
	return 1;
}

int map_array_push(MapArray *map,
		const void *key, size_t klen,
		void *element)
{
	Array *array = NULL;
	if (!map_array_get_array(map, key, klen, &array))
		return 0;
	return array_push(array, element);
}

int map_array_set(MapArray *map,
		const void *key, size_t klen,
		int index, void *element) 
{
	Array *array = NULL;
	if (!map_array_get_array(map, key, klen, &array))
		return 0;
	array_set(array, index, element);
	return 1;
}

int map_array_get(MapArray *map,
		const void *key, size_t klen,
		int index, void *out_element)
{
	Array *array = NULL;
	if (!map_array_get_array(map, key, klen, &array))
		return 0;
	array_get(array, index, out_element);
	return 1;
}

int map_array_peek(MapArray *map,
		const void *key, size_t klen,
		void *out_element)
{

	Array *array = NULL;
	if (!map_array_get_array(map, key, klen, &array))
		return -1;
	return array_peek(array, out_element);
}

int map_array_pop(MapArray *map,
		const void *key, size_t klen,
		void *out_element)
{

	Array *array = NULL;
	if (!map_array_get_array(map, key, klen, &array))
		return -1;
	return array_pop(array, out_element);
}
