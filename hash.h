#ifndef __HASH_H__
#define __HASH_H__

#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>

typedef struct Bucket {
	size_t klen;
	uint8_t *key;
	size_t vlen;
	uint8_t *value;
} Bucket;

typedef struct Map {
	size_t length;
	size_t hash_mask; 
	Bucket *buckets;
} Map;

/* length must be a power of 2. */
Map *map_new(size_t length);
void map_delete(Map *map);

int map_put(Map *map,
		const uint8_t *key, size_t klen,
		const uint8_t *value, size_t vlen);
int map_get(Map *map,
		const uint8_t *key, size_t klen,
		uint8_t *out_value, size_t *out_vlen);

uint32_t jenkins_one_at_a_time_hash(const uint8_t* key, size_t length);

#endif
