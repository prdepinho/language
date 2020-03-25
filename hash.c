#include "hash.h"
#include <stdio.h>

#if DEBUG
static void print_bucket(Bucket *bucket) {
	char *string = (char*)malloc(sizeof(char) * bucket->klen);
	strncpy(string, (char*)bucket->key, bucket->klen);
	long value;
	memcpy(&value, bucket->value, sizeof(value));
	printf("%10s: %ld\n", string, value);
	free(string);
}

static void print_buckets(Bucket *buckets, size_t length) {
	printf("map length: %lu {\n", length);

	for (int i = 0; i < length; i++) {
		printf("%5d: ", i);
		Bucket *bucket = &buckets[i];

		if (bucket->key != 0) {
			print_bucket(bucket);
		}
		else {
			printf("%10s\n", "-");
		}
	}
	printf("}\n");
}
#endif

static int map_extend(Map *map){
	size_t old_length = map->length;
	size_t new_length = (map->length > 0) ? map->length * map->length : 2;

	Bucket *old_buckets = map->buckets;
	Bucket *new_buckets = (Bucket*) malloc(new_length * sizeof(Bucket));
	if (new_buckets == NULL)
		return 0;
	memset(new_buckets, 0, new_length * sizeof(Bucket));

	map->buckets = new_buckets;
	map->length = new_length;

	for (int i = 0; i < old_length; ++i){
		if(old_buckets[i].key != 0){
			map_put(
				map,
				old_buckets[i].key,
				old_buckets[i].klen,
				old_buckets[i].value,
				old_buckets[i].vlen
			);
			free(old_buckets[i].key);
			free(old_buckets[i].value);
		}
	}
	free(old_buckets);

	return 1;
}

Map *map_new(size_t length){
	Map *map = (Map*) malloc(sizeof(Map));
	if (map == NULL)
		return NULL;

	map->length = length;

	size_t power = 0;
	uint32_t mask = 1;
	while((length >> power) != 1) { mask <<= 1; mask++; power++; }
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
		const void *key, size_t klen,
		const void *value, size_t vlen)
{
	uint32_t complete_hash = jenkins_one_at_a_time_hash(key, klen);
	uint32_t hash = complete_hash & map->hash_mask;

	uint32_t home_hash = hash;

	while (
			map->buckets[hash].key != 0 &&
			memcmp(map->buckets[hash].key, key, klen) != 0
	) {
		hash = (hash + 1) % map->length;
		if (hash == home_hash) {
			if (!map_extend(map))
				return 0;
		}
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
	return 1;
}

int map_get(Map *map,
		const void *key, size_t klen,
		void *out_value, size_t *out_vlen)
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
			return 0;
	}

	if (map->buckets[hash].key == 0)
		return 0;

	*out_vlen = map->buckets[hash].vlen;
	memcpy(out_value, map->buckets[hash].value, *out_vlen);
	return 1;
}

int map_remove(Map *map,
		const void *key, size_t klen)
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
			return 0;
	}

	if (map->buckets[hash].key == 0)
		return 0;

	free(map->buckets[hash].key);
	map->buckets[hash].key = 0;
	free(map->buckets[hash].value);
	map->buckets[hash].value = 0;

	return 1;
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
