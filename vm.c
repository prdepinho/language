#include "vm.h"

VM *vm_new() {
	VM *vm = NULL;
	Array *commands = NULL;
	Array *stack = NULL;
	
	vm = (VM*) malloc(sizeof(VM));
	if (vm == NULL)
	   	goto vm_new_fail;
	commands = array_new(sizeof(Command), 0);
	if (commands == NULL)
		goto vm_new_fail;
	stack = array_new(sizeof(Register), 0);
	if (stack == NULL)
		goto vm_new_fail;

	vm->commands = commands;
	vm->stack = stack;
	vm->cmd_ptr = 0;
	return vm;

vm_new_fail:
	if (vm != NULL) 
		free(vm);
	if (commands != NULL)
		array_delete(commands);
	if (stack != NULL)
		array_delete(stack);
	return NULL;
}

void vm_delete(VM *vm) {
	array_delete(vm->commands);
	array_delete(vm->stack);
	free(vm);
}

int vm_run(VM *vm) {
	for (vm->cmd_ptr = 0; vm->cmd_ptr < vm->commands->length; vm->cmd_ptr++) {
		Command cmd;
		array_get(vm->commands, vm->cmd_ptr, &cmd);
		vm_execute(vm, cmd);
	}
	return 0;
}

Addr vm_execute(VM *vm, Command cmd) {
	switch(cmd.code) {
	case CMD_SET_BYTE:
		return vm_push_byte(vm, cmd.byte_arg);

	case CMD_SET_UINT:
		return vm_push_uint(vm, cmd.uint_arg);

	case CMD_SET_INT: 
		return vm_push_int(vm, cmd.int_arg);

	case CMD_SET_FLOAT:
		return vm_push_float(vm, cmd.float_arg);

	case CMD_MALLOC:
		break;

	case CMD_FREE:
		break;

	case CMD_ADD:
		return vm_add(vm, cmd.addr, cmd.addr_arg);

	case CMD_SUB:
		return vm_sub(vm, cmd.addr, cmd.addr_arg);

	case CMD_MULT:
		return vm_mult(vm, cmd.addr, cmd.addr_arg);

	case CMD_DIV:
		return vm_div(vm, cmd.addr, cmd.addr_arg);

	case CMD_JUMP:
		return vm_jump(vm, cmd.addr);

	case CMD_JCOND:
		return vm_jcond(vm, cmd.addr, cmd.addr_arg);

	case CMD_POP:
		return vm_pop(vm);

	}
	return 0;
}

size_t vm_push_cmd(VM *vm, Command cmd) {
	return array_push(vm->commands, &cmd);
}


Addr vm_push_byte(VM *vm, Byte value) {
	Register reg;
	reg.type = TYPE_BYTE;
	reg.byte_value = value;
	Addr index = array_push(vm->stack, &reg);
	return index;
}

Addr vm_push_int(VM *vm, Int value) {
	Register reg;
	reg.type = TYPE_INT;
	reg.int_value = value;
	Addr index = array_push(vm->stack, &reg);
	return index;
}

Addr vm_push_uint(VM *vm, UInt value) {
	Register reg;
	reg.type = TYPE_UINT;
	reg.uint_value = value;
	Addr index = array_push(vm->stack, &reg);
	return index;
}

Addr vm_push_float(VM *vm, Float value) {
	Register reg;
	reg.type = TYPE_FLOAT;
	reg.float_value = value;
	size_t index = array_push(vm->stack, &reg);
	return index;
}

Addr vm_add(VM *vm, Addr lval_addr, Addr rval_addr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	// make the addition
	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value + rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) + rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) + rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) + rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value + ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value + rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) + rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) + rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value + ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value + ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value + rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) + rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value + ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value + ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value + ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value + rval.float_value;
					break;
			}
			break;
	}

	Addr index = array_push(vm->stack, &result);
	return index;
}

Addr vm_sub(VM *vm, Addr lval_addr, Addr rval_addr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	// make the addition
	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value - rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) - rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) - rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) - rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value - ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value - rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) - rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) - rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value - ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value - ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value - rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) - rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value - ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value - ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value - ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value - rval.float_value;
					break;
			}
			break;
	}

	Addr index = array_push(vm->stack, &result);
	return index;
}

Addr vm_mult(VM *vm, Addr lval_addr, Addr rval_addr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	// make the addition
	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value * rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) * rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) * rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) * rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value * ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value * rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) * rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) * rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value * ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value * ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value * rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) * rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value * ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value * ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value * ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value * rval.float_value;
					break;
			}
			break;
	}

	Addr index = array_push(vm->stack, &result);
	return index;
}

Addr vm_div(VM *vm, Addr lval_addr, Addr rval_addr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	// make the addition
	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value / rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) / rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) / rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) / rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value / ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value / rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) / rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) / rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value / ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value / ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value / rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) / rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value / ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value / ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value / ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value / rval.float_value;
					break;
			}
			break;
	}

	Addr index = array_push(vm->stack, &result);
	return index;
}

Addr vm_jump(VM *vm, Addr addr) {
	vm->cmd_ptr = addr;
	return addr;
}

Addr vm_jcond(VM *vm, Addr cmd_addr, Addr bool_addr) {
	Register reg;
	array_get(vm->stack, bool_addr, &reg);
	switch (reg.type) {
		case TYPE_BYTE:
			if (reg.byte_value)
				vm_jump(vm, cmd_addr);
			break;
		case TYPE_UINT:
			if (reg.uint_value)
				vm_jump(vm, cmd_addr);
			break;
		case TYPE_INT:
			if (reg.int_value)
				vm_jump(vm, cmd_addr);
			break;
		case TYPE_FLOAT:
			if ((Int) reg.float_value)
				vm_jump(vm, cmd_addr);
			break;
	}
	return 0;
}


Addr vm_pop(VM *vm) {
	Register reg;
	return array_pop(vm->stack, &reg);
}


Addr vm_get_addr(VM *vm, Addr index) {
	Register reg;
	array_get(vm->stack, index, &reg);
	return reg.addr_value;
}

Byte vm_get_byte(VM *vm, Addr index) {
	Register reg;
	array_get(vm->stack, index, &reg);
	return reg.byte_value;
}

UInt vm_get_uint(VM *vm, Addr index) {
	Register reg;
	array_get(vm->stack, index, &reg);
	return reg.uint_value;
}

Int vm_get_int(VM *vm, Addr index) {
	Register reg;
	array_get(vm->stack, index, &reg);
	return reg.int_value;
}

Float vm_get_float(VM *vm, Addr index) {
	Register reg;
	array_get(vm->stack, index, &reg);
	return reg.float_value;
}

void *vm_get_ptr(VM *vm, Addr index) {
	Register reg;
	array_get(vm->stack, index, &reg);
	return reg.ptr_value;
}
