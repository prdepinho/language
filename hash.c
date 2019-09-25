#include "hash.h"
#include <stdio.h>

Map *map_new(size_t length){
	Map *map = (Map*) malloc(sizeof(Map));
	if (map == NULL)
		return NULL;

	map->length = length;

	size_t power = 0;
	uint32_t mask = 1;
	while((length >> power) != 1) { mask <<= 1; mask += 1; power++; }
	mask >>= 1;
	map->hash_mask = mask;

	map->buckets = (Bucket*) malloc(length * sizeof(Bucket));
	if (map->buckets == NULL){
		free(map);
		return NULL;
	}

	memset(map->buckets, 0, length * sizeof(Bucket));
	return map;
}

void map_delete(Map *map){
	for (int i = 0; i < map->length; ++i){
		if(map->buckets[i].key != 0){
			free(map->buckets[i].key);
			free(map->buckets[i].value);
		}
	}
	free(map->buckets);
	free(map);
}

int map_put(Map *map,
		const uint8_t *key, size_t klen,
		const uint8_t *value, size_t vlen)
{
	uint32_t complete_hash = jenkins_one_at_a_time_hash(key, klen);
	uint32_t hash = complete_hash & map->hash_mask;

	uint32_t home_hash = hash;
	while (
			map->buckets[hash].key != 0 &&
			memcmp(map->buckets[hash].key, key, klen) != 0
	) {
		hash = (hash + 1) % map->length;
		if (hash == home_hash)
			return 1;
	}

#ifdef DEBUG
	printf("complete_mask: %u [0x%08x]\n", complete_hash, complete_hash);
	printf("mask: %lu [0x%08lx]\n", map->hash_mask, map->hash_mask);
	printf("hash: %u [0x%08x]\n", hash, hash);
#endif

	map->buckets[hash].key = (uint8_t*) malloc(sizeof(uint8_t) * klen);
	memcpy(map->buckets[hash].key, key, klen);
	map->buckets[hash].klen = klen;
	map->buckets[hash].value = (uint8_t*) malloc(sizeof(uint8_t) * vlen);
	memcpy(map->buckets[hash].value, value, vlen);
	map->buckets[hash].vlen = vlen;
	return 0;
}

int map_get(Map *map,
		const uint8_t *key, size_t klen,
		uint8_t *out_value, size_t *out_vlen)
{
	uint32_t complete_hash = jenkins_one_at_a_time_hash(key, klen);
	uint32_t hash = complete_hash & map->hash_mask;

	uint32_t home_hash = hash;
	while(
			map->buckets[hash].key != 0 &&
			memcmp(map->buckets[hash].key, key, klen) != 0
	){

		hash = (hash + 1) % map->length;
		if (hash == home_hash)
			return 1;
	}

	*out_vlen = map->buckets[hash].vlen;
	memcpy(out_value, map->buckets[hash].value, *out_vlen);
	return 0;
}

/* Taken from Wikipedia no less. */
uint32_t jenkins_one_at_a_time_hash(const uint8_t* key, size_t length) {
	size_t i = 0;
	uint32_t hash = 0;
	while (i != length) {
		hash += key[i++];
		hash += hash << 10;
		hash ^= hash >> 6;
	}
	hash += hash << 3;
	hash ^= hash >> 11;
	hash += hash << 15;
	return hash;
}
