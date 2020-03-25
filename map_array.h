#ifndef __MAP_ARRAY_H__
#define __MAP_ARRAY_H__

#include "hash.h"
#include "array.h"

/*
 * A map that maps any key type to an array type. 
 * Methods that access a mapped array create a new array if it was null.
 * These arrays are destroyed by map_array_delete.
 * */
typedef struct MapArray {
	Map *map;
	size_t array_element_size;
	size_t array_initial_length;
} MapArray;


// map_initial_length must be a power of 2.
MapArray *map_array_new(size_t map_initial_length, size_t array_element_size, size_t array_initial_length);
void map_array_delete(MapArray *map);

// return 1 for when map contains key, 0 otherwise.
int map_array_contains(MapArray *map, const void *key, size_t klen);

// return 1 for failure, 0 for success.
int map_array_get_array(MapArray *map,
		const void *key, size_t klen,
		Array **out_array);

// return the index of the element if successful, else -1;
int map_array_push(MapArray *map,
		const void *key, size_t klen,
		void *element);

int map_array_set(MapArray *map,
		const void *key, size_t klen,
		int index, void *element);

int map_array_get(MapArray *map,
		const void *key, size_t klen,
		int index, void *out_element);

int map_array_peek(MapArray *map,
		const void *key, size_t klen,
		void *out_element);

int map_array_pop(MapArray *map,
		const void *key, size_t klen,
		void *out_element);

#endif /* __MAP_ARRAY_H__ */
