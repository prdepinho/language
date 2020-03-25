#ifndef __MAP_ARRAY_H__
#define __MAP_ARRAY_H__

#include "hash.h"
#include "array.h"

/*
 * A map that maps any key type to an array type. 
 * Methods in this class take care of creating, managing and destroying its array values. 
 * */
typedef struct MapArray {
	Map *map;
	size_t array_element_size;
	size_t array_initial_length;
} MapArray;


// map_initial_length must be a power of 2.
MapArray *map_array_new(size_t map_initial_length, size_t array_element_size, size_t array_initial_length);
void map_array_delete(MapArray *map);

// return 1 for failure, 0 for success.
int map_array_get_array(MapArray *map,
		const void *key, size_t klen,
		Array **out_array);

// return the index of the element if successful, else -1;
int map_array_push(MapArray *map,
		const void *key, size_t klen,
		void *element);

#endif /* __MAP_ARRAY_H__ */
