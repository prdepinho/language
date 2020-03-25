#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "hash.h"
#include "array.h"
#include "map_array.h"
#include "vm.h"

int main(void){

#if false
	{
		VM *vm = vm_new();
		printf("vm created\n");

		{
			Addr a = vm_push_int(vm, 42);
			Addr b = vm_push_int(vm, 58);
			Addr c = vm_add(vm, a, b);

			Int aval = vm_get_int(vm, a);
			Int bval = vm_get_int(vm, b);
			Int cval = vm_get_int(vm, c);

			printf("a: %ld \n", aval);
			printf("b: %ld \n", bval);
			printf("c: %ld \n", cval);

			printf("length: %ld\n", vm->stack->length);
			printf("pop: %ld\n", vm_pop(vm));
			printf("pop: %ld\n", vm_pop(vm));
			printf("pop: %ld\n", vm_pop(vm));
			printf("length: %ld\n", vm->stack->length);
		}

		vm_delete(vm);
		printf("vm deleted\n");
	}
#endif

#if false
	{
		VM *vm = vm_new();

		Command cmd;

		cmd.code = CMD_SET_INT;
		cmd.addr = 0;
		cmd.int_arg = 42;
		vm_push_cmd(vm, cmd);

		cmd.code = CMD_SET_INT;
		cmd.addr = 0;
		cmd.int_arg = 58;
		vm_push_cmd(vm, cmd);

		cmd.code = CMD_ADD;
		cmd.addr = -2;
		cmd.addr_arg = -1;
		vm_push_cmd(vm, cmd);

		vm_run(vm);

		Int aval = vm_get_int(vm, -3);
		Int bval = vm_get_int(vm, -2);
		Int cval = vm_get_int(vm, -1);

		printf("a: %ld \n", aval);
		printf("b: %ld \n", bval);
		printf("c: %ld \n", cval);

		printf("length: %ld\n", vm->stack->length);
		printf("pop: %ld\n", vm_pop(vm));
		printf("pop: %ld\n", vm_pop(vm));
		printf("pop: %ld\n", vm_pop(vm));
		printf("length: %ld\n", vm->stack->length);
	
		vm_delete(vm);
	}
#endif

#if false
	{
		size_t data_size = sizeof(int);
		size_t initial_length = 10;

		printf("Test array\n");
		Array *array = array_new(data_size, initial_length);

		int in;
		int out;

		in = 10;
		array_set(array, 0, &in);

		in = 42;
		array_set(array, 2, &in);

		array_get(array, 0, &out);
		printf("%d\n", out);

		array_get(array, 1, &out);
		printf("%d\n", out);

		array_get(array, 2, &out);
		printf("%d\n", out);


		array_delete(array);
		printf("Done\n");

		printf("Test stack\n");
		array = array_new(sizeof(int), 0);

		for (int i = 0; i < 10; i++){
			in = i * 10;
			int rval = array_push(array, &in);
			printf("rval: %d. push %d to array length: %zu, capacity: %zu\n", rval, in, array->length, array->capacity);
		}

		{
			int rval = array_peek(array, &out);
			printf("rval: %d. peek %d from array length: %zu, capacity: %zu\n", rval, out, array->length, array->capacity);
		}

		for (int i = 0; i < 10; i++){
			int rval = array_pop(array, &out);
			printf("rval: %d. pop %d from array length: %zu, capacity: %zu\n", rval, out, array->length, array->capacity);
		}

		int rval = array_pop(array, &out);
		printf("rval: %d. pop %d from array length: %zu, capacity: %zu\n", rval, out, array->length, array->capacity);

		array_delete(array);
		printf("Done\n");

	}
#endif

#if false
	{
		printf("test\n");
		Array *stack = array_new(sizeof(int), 0);

		for (int a = 0; a < 10; a++) {
			array_push(stack, &a);
		}
		printf("length: %lu\n", stack->length);

		for (int i = 0; i < stack->length; i++) {
			int a;
			array_get(stack, i, &a);
			printf(" %d\n", a);
		}
		printf("length: %lu\n", stack->length);
		printf("\n");

		int length = stack->length + 1;
		for (int i = 0; i < length; i++) {
			int a;
			array_pop(stack, &a);
			printf(" %d\n", a);
			printf("length: %lu\n", stack->length);
		}

		array_delete(stack);

	}
#endif

#if false
	{
		Map *map = map_new(2);
		if (map == NULL){
			fprintf(stderr, "Map is null\n");
			goto map_array_test_end;
		}

		// map "foo" and [42]
		{
			Array *array = array_new(sizeof(int), 0);
			if (array == NULL) {
				fprintf(stderr, "array is null\n");
				goto map_array_test_end;
			}

			int i = 42;
			array_push(array, &i);
			map_put(map, "foo", 4, &array, sizeof(array));
		}

		// add 777 to the array
		{
			Array *array = NULL;
			size_t array_size = 0;
			map_get(map, "foo", 4, &array, &array_size);
			int i = 777;
			array_push(array, &i);
		}

		// get the values out of the array from the map
		{
			Array *array = NULL;
			size_t array_size = 0;
			!map_get(map, "foo", 4, &array, &array_size);

			int i = 0;
			for (int j = 0; j < array->length; j++) {
				array_get(array, j, &i);
				printf("i: %d\n", i);
			}

			if (array != NULL)
				array_delete(array);
		}


map_array_test_end:
		if (map != NULL)
			map_delete(map);
		return 0;
		
	}
#endif
#if true
	{
		MapArray *map = map_array_new(2, sizeof(int), 0);
		if (map == NULL)
			goto map_array_class_test_end;

		{
			int i = 120;
			map_array_push(map, "spam", 5, &i);
		}

		{
			Array *array = NULL;
			if (!map_array_get_array(map, "spam", 5, &array))
				printf("map_array_get fail\n");
			else {
				int i = 0;
				array_peek(array, &i);
				printf("array length: %lu\n", array->length);
				printf("i: %d\n", i);
			}

		}

map_array_class_test_end:
		if (map != NULL)
			map_array_delete(map);
		return 0;
	}
#endif

#if false
	{
		Map *map = map_new(1024);
		if (map == NULL) {
			fprintf(stderr, "Map is null");
			return 1;
		}
		const char *key = "foo";
		size_t klen = strlen(key);
		char value[2048];
		size_t vlen = 0;
		int rval;

		printf("testing\n");

		rval = map_get(map, "inexistent", 10, value, &vlen);
		printf("(%d) %s: %s\n", rval, "inexistent", value);

		rval = map_put(map, key, klen, "bar", 3);
		rval = map_put(map, "spam", 4, "spam", 4);
		rval = map_put(map, "matrix reloaded", 15, "nabucodonossor", 14);

		rval = map_get(map, key, klen, value, &vlen);
		printf("(%d) %s: %s (%lu)\n", rval, key, value, vlen);

		rval = map_get(map, "matrix reloaded", 15, value, &vlen);
		printf("(%d) %s: %s (%lu)\n", rval, "matrix reloaded", value, vlen);

		map_delete(map);
		printf("finished\n");
	}
#endif

	// ---------------------------


#if false
	{
		Map *map = map_new(2048);
		if (map == NULL) {
			fprintf(stderr, "Map is null");
			return 1;
		}

#if false
		{
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
		}
#endif

#if false
		{
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
		}
#endif

		map_delete(map);
	}
#endif

	return 0;
}
