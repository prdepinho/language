#include <stdio.h>
#include <string.h>
#include "hash.h"

int main(void){

	{
#if false
		Map *map = map_new(1024);
		if (map == NULL) {
			fprintf(stderr, "Map is null");
			return 1;
		}
		const char *key = "foo";
		size_t klen = strlen(key);
		char value[2048];
		size_t vlen = 0;

		map_put(map, key, klen, "bar", 3);
		map_put(map, "spam", 4, "spam", 4);
		map_put(map, "matrix reloaded", 15, "nabucodonossor", 14);

		map_get(map, key, klen, value, &vlen);
		printf("%s: %s (%lu)\n", key, value, vlen);

		map_get(map, "matrix reloaded", 15, value, &vlen);
		printf("%s: %s (%lu)\n", "matrix reloaded", value, vlen);

		map_delete(map);
#endif
	}

	// ---------------------------


	{
		Map *map = map_new(2048);
		if (map == NULL) {
			fprintf(stderr, "Map is null");
			return 1;
		}

		uint32_t key = 1234;
		size_t klen = sizeof(uint32_t);
		uint32_t value = 1234;
		size_t vlen = sizeof(uint32_t);

		size_t tests = 1000;
		for (int i = 0; i < tests; ++i){
			key = i;
			value = i;
			map_put(map, (uint8_t*)&key, klen, (uint8_t*)&value, vlen);
		}
		for (int i = 0; i < tests; ++i){
			key = i;
			map_get(map, (uint8_t*)&key, klen, (uint8_t*)&value, &vlen);
			printf("resutl: %u: %u\n", key, value);
			if (key != value){
				printf("CLASH: %u: %u\n", key, value);
				break;
			}
		}
#if false
		uint32_t keys[] = {9, 32};
		for (int i = 0; i < 2; ++i){
			key = keys[i];
			value = keys[i];
			map_put(map, (uint8_t*)&key, klen, (uint8_t*)&value, vlen);
		}
		for (int i = 0; i < 2; ++i){
			key = keys[i];
			map_get(map, (uint8_t*)&key, klen, (uint8_t*)&value, &vlen);
			printf("resutl: %u: %u\n", key, value);
		}
#endif

		map_delete(map);


	}



	return 0;
}
