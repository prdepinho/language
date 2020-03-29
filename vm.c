#include "vm.h"
#include <stdio.h>

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
	while (vm->cmd_ptr < vm->commands->length) {
		Command cmd;
		array_get(vm->commands, vm->cmd_ptr, &cmd);
		vm_execute(vm, cmd);
		vm->cmd_ptr++;
	}
	return 0;
}

Addr vm_execute(VM *vm, Command cmd) {
	switch(cmd.code) {
	case CMD_COPY:
		{
		Register reg = vm_get(vm, cmd.addr_arg);
		vm_set(vm, cmd.addr, reg);
		break;
		}
	case CMD_ASSIGN:
		vm_assign(vm, cmd.addr, cmd.addr_arg);
		break;
	case CMD_SET_BYTE:
		{
		Register reg;
		reg.type = TYPE_BYTE;
		reg.byte_value = cmd.byte_arg;
		vm_set(vm, cmd.addr, reg);
		break;
		}

	case CMD_SET_UINT:
		{
		Register reg;
		reg.type = TYPE_UINT;
		reg.uint_value = cmd.uint_arg;
		vm_set(vm, cmd.addr, reg);
		break;
		}

	case CMD_SET_INT: 
		{
		Register reg;
		reg.type = TYPE_INT;
		reg.int_value = cmd.int_arg;
		vm_set(vm, cmd.addr, reg);
		break;
		}

	case CMD_SET_FLOAT:
		{
		Register reg;
		reg.type = TYPE_FLOAT;
		reg.float_value = cmd.float_arg;
		vm_set(vm, cmd.addr, reg);
		break;
		}

	case CMD_MALLOC:
		break;

	case CMD_FREE:
		break;

	case CMD_ADD:
		return vm_add(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_SUB:
		return vm_sub(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_MULT:
		return vm_mult(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_DIV:
		return vm_div(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_JUMP:
		return vm_jump(vm, cmd.addr);

	case CMD_JCOND:
		return vm_jcond(vm, cmd.addr, cmd.addr_arg);
	
	case CMD_AND:
		return vm_and(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_OR:
		return vm_or(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_XOR:
		return vm_xor(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_NOT:
		return vm_not(vm, cmd.addr, cmd.raddr);
	
	case CMD_RSHIFT:
		return vm_lshift(vm, cmd.addr, cmd.addr_arg, cmd.raddr);
	
	case CMD_LSHIFT:
		return vm_lshift(vm, cmd.addr, cmd.addr_arg, cmd.raddr);
	
	case CMD_GREATER:
		return vm_greater(vm, cmd.addr, cmd.addr_arg, cmd.raddr);
	
	case CMD_LESS:
		return vm_less(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_EQUAL:
		return vm_equal(vm, cmd.addr, cmd.addr_arg, cmd.raddr);
	
	case CMD_GEQ:
		return vm_geq(vm, cmd.addr, cmd.addr_arg, cmd.raddr);
	
	case CMD_LEQ:
		return vm_leq(vm, cmd.addr, cmd.addr_arg, cmd.raddr);

	case CMD_PUSH:
		vm_push(vm);
		break;

	case CMD_POP:
		vm_pop(vm);
		break;
	
	case CMD_STACK:
		vm_stack_dump(vm);
		break;
	
	case CMD_COMMANDS:
		vm_commands_dump(vm);
		break;
	
	case CMD_PRINT:
		vm_register_dump(vm, cmd.addr);
		break;

	}
	return 0;
}

Addr vm_push_cmd(VM *vm, Command cmd) {
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_copy(VM *vm, Addr addr, Addr addr_arg) {
	Command cmd;
	cmd.code = CMD_COPY;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_assign(VM *vm, Addr addr, Addr addr_arg) {
	Command cmd;
	cmd.code = CMD_ASSIGN;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_set_byte(VM *vm, Addr addr, Byte byte_arg) {
	Command cmd;
	cmd.code = CMD_SET_BYTE;
	cmd.addr = addr;
	cmd.byte_arg = byte_arg;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_set_int(VM *vm, Addr addr, Int int_arg) {
	Command cmd;
	cmd.code = CMD_SET_INT;
	cmd.addr = addr;
	cmd.int_arg = int_arg;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_set_uint(VM *vm, Addr addr, UInt uint_arg) {
	Command cmd;
	cmd.code = CMD_SET_UINT;
	cmd.addr = addr;
	cmd.uint_arg = uint_arg;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_set_float(VM *vm, Addr addr, Float float_arg) {
	Command cmd;
	cmd.code = CMD_SET_FLOAT;
	cmd.addr = addr;
	cmd.float_arg = float_arg;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_add(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_ADD;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_sub(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_SUB;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_mult(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_MULT;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_div(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_DIV;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_jump(VM *vm, Addr addr) {
	Command cmd;
	cmd.code = CMD_JUMP;
	cmd.addr = addr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_jcond(VM *vm, Addr addr, Addr addr_arg) {
	Command cmd;
	cmd.code = CMD_JCOND;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_push(VM *vm) {
	Command cmd;
	cmd.code = CMD_PUSH;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_pop(VM *vm) {
	Command cmd;
	cmd.code = CMD_POP;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_and(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_AND;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_or(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_OR;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_xor(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_XOR;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_not(VM *vm, Addr addr, Addr raddr) {
	Command cmd;
	cmd.code = CMD_NOT;
	cmd.addr = addr;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_rshift(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_RSHIFT;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_lshift(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_LSHIFT;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_greater(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_GREATER;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_less(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_LESS;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_equal(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_EQUAL;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_geq(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_GEQ;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_leq(VM *vm, Addr addr, Addr addr_arg, Addr raddr) {
	Command cmd;
	cmd.code = CMD_LEQ;
	cmd.addr = addr;
	cmd.addr_arg = addr_arg;
	cmd.raddr = raddr;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_stack(VM *vm) {
	Command cmd;
	cmd.code = CMD_STACK;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_commands(VM *vm) {
	Command cmd;
	cmd.code = CMD_COMMANDS;
	return array_push(vm->commands, &cmd);
}

Addr vm_push_cmd_print(VM *vm, Addr addr) {
	Command cmd;
	cmd.code = CMD_PRINT;
	cmd.addr = addr;
	return array_push(vm->commands, &cmd);
}

void vm_clear_commands(VM *vm) {
	vm->commands->length = 0;
}

void vm_assign(VM *vm, Addr lval_addr, Addr rval_addr) {
	Register lval;
	Register rval;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:  lval.byte_value = rval.byte_value; break;
				case TYPE_UINT:  lval.byte_value = (Byte) rval.uint_value; break;
				case TYPE_INT:   lval.byte_value = (Byte) rval.int_value; break;
				case TYPE_FLOAT: lval.byte_value = (Byte) rval.float_value; break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:  lval.uint_value = (UInt) rval.byte_value; break;
				case TYPE_UINT:  lval.uint_value = rval.uint_value; break;
				case TYPE_INT:   lval.uint_value = (UInt) rval.int_value; break;
				case TYPE_FLOAT: lval.uint_value = (UInt) rval.float_value; break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:  lval.int_value = (Int) rval.byte_value; break;
				case TYPE_UINT:  lval.int_value = (Int) rval.uint_value; break;
				case TYPE_INT:   lval.int_value = rval.int_value; break;
				case TYPE_FLOAT: lval.int_value = (Int) rval.float_value; break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:  lval.float_value = (Float) rval.byte_value; break;
				case TYPE_UINT:  lval.float_value = (Float) rval.uint_value; break;
				case TYPE_INT:   lval.float_value = (Float) rval.int_value; break;
				case TYPE_FLOAT: lval.float_value = rval.float_value; break;
			}
			break;
	}

	array_set(vm->stack, lval_addr, &lval);
}

Addr vm_push(VM *vm) {
	Register reg;
	return array_push(vm->stack, &reg);
}

Addr vm_push_byte(VM *vm, Byte value) {
	Register reg;
	reg.type = TYPE_BYTE;
	reg.byte_value = value;
	return array_push(vm->stack, &reg);
}

Addr vm_push_int(VM *vm, Int value) {
	Register reg;
	reg.type = TYPE_INT;
	reg.int_value = value;
	return array_push(vm->stack, &reg);
}

Addr vm_push_uint(VM *vm, UInt value) {
	Register reg;
	reg.type = TYPE_UINT;
	reg.uint_value = value;
	return array_push(vm->stack, &reg);
}

Addr vm_push_float(VM *vm, Float value) {
	Register reg;
	reg.type = TYPE_FLOAT;
	reg.float_value = value;
	return array_push(vm->stack, &reg);
}

void vm_set_byte(VM *vm, Addr index, Byte value) {
	Register reg;
	array_get(vm->stack, index, &reg);
	reg.byte_value = value;
	array_set(vm->stack, index, &reg);
}

void vm_set_uint(VM *vm, Addr index, UInt value) {
	Register reg;
	array_get(vm->stack, index, &reg);
	reg.uint_value = value;
	array_set(vm->stack, index, &reg);
}

void vm_set_int(VM *vm, Addr index, Int value) {
	Register reg;
	array_get(vm->stack, index, &reg);
	reg.int_value = value;
	array_set(vm->stack, index, &reg);
}

void vm_set_float(VM *vm, Addr index, Float value) {
	Register reg;
	array_get(vm->stack, index, &reg);
	reg.float_value = value;
	array_set(vm->stack, index, &reg);
}

Addr vm_add(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

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

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_sub(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

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

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_mult(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

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

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_div(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

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

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_jump(VM *vm, Addr addr) {
	vm->cmd_ptr = addr - 1;  // -1 because it is going to increment afterwards (see vm_run()).
	return addr;
}

Addr vm_jcond(VM *vm, Addr cmd_addr, Addr bool_addr) {
	Register reg;
	array_get(vm->stack, bool_addr, &reg);
	switch (reg.type) {
		case TYPE_BYTE:
			if (reg.byte_value)
				return vm_jump(vm, cmd_addr);
			break;
		case TYPE_UINT:
			if (reg.uint_value)
				return vm_jump(vm, cmd_addr);
			break;
		case TYPE_INT:
			if (reg.int_value)
				return vm_jump(vm, cmd_addr);
			break;
		case TYPE_FLOAT:
			if ((Int) reg.float_value)
				return vm_jump(vm, cmd_addr);
			break;
		default:
			return 0;
	}
}

Addr vm_and(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value & rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) & rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) & rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value & ((Byte) rval.float_value);
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value & ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value & rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) & rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value & (UInt) rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value & ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value & ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value & rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value & (Int) rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = ((Byte) lval.float_value) & rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.float_value = ((UInt) lval.float_value) & rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.float_value = ((Int) lval.float_value) & rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.float_value) & ((UInt) rval.float_value);
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_or(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value | rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) | rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) | rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value | ((Byte) rval.float_value);
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value | ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value | rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) | rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value | (UInt) rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value | ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value | ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value | rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value | (Int) rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = ((Byte) lval.float_value) | rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.float_value = ((UInt) lval.float_value) | rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.float_value = ((Int) lval.float_value) | rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.float_value) | ((UInt) rval.float_value);
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_xor(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value ^ rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) ^ rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) ^ rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value ^ ((Byte) rval.float_value);
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value ^ ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value ^ rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) ^ rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value ^ (UInt) rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value ^ ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value ^ ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value ^ rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value ^ (Int) rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = ((Byte) lval.float_value) ^ rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.float_value = ((UInt) lval.float_value) ^ rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.float_value = ((Int) lval.float_value) ^ rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.float_value) ^ ((UInt) rval.float_value);
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_not(VM *vm, Addr lval_addr, Addr raddr) {
	Register lval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);

	switch (result.type) {
		case TYPE_BYTE:
			result.type = TYPE_BYTE;
			result.byte_value = !lval.byte_value;
			break;
		case TYPE_UINT:
			result.type = TYPE_UINT;
			result.uint_value = !lval.uint_value;
			break;
		case TYPE_INT:
			result.type = TYPE_INT;
			result.int_value = !lval.int_value;
			break;
		case TYPE_FLOAT:
			result.type = TYPE_UINT;
			result.uint_value = !((UInt) lval.float_value);
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_rshift(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value << rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) << rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) << rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value << ((Byte) rval.float_value);
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value << ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value << rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) << rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value << (UInt) rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value << ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value << ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value << rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value << (Int) rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = ((Byte) lval.float_value) << rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.float_value = ((UInt) lval.float_value) << rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.float_value = ((Int) lval.float_value) << rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.float_value) << ((UInt) rval.float_value);
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_lshift(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value >> rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) >> rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) >> rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value >> ((Byte) rval.float_value);
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value >> ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value >> rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) >> rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value >> (UInt) rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value >> ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value >> ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value >> rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value >> (Int) rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = ((Byte) lval.float_value) >> rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.float_value = ((UInt) lval.float_value) >> rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.float_value = ((Int) lval.float_value) >> rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.float_value) >> ((UInt) rval.float_value);
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_greater(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value > rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) > rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) > rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) > rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value > ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value > rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) > rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) > rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value > ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value > ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value > rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) > rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value > ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value > ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value > ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value > rval.float_value;
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_less(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value < rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) < rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) < rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) < rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value < ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value < rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) < rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) < rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value < ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value < ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value < rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) < rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value < ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value < ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value < ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value < rval.float_value;
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_equal(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value == rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) == rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) == rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) == rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value == ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value == rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) == rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) == rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value == ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value == ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value == rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) == rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value == ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value == ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value == ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value == rval.float_value;
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_geq(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value >= rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) >= rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) >= rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) >= rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value >= ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value >= rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) >= rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) >= rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value >= ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value >= ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value >= rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) >= rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value >= ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value >= ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value >= ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value >= rval.float_value;
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Addr vm_leq(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr) {
	Register lval;
	Register rval;
	Register result;
	array_get(vm->stack, lval_addr, &lval);
	array_get(vm->stack, rval_addr, &rval);

	switch (lval.type) {
		case TYPE_BYTE:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_BYTE;
					result.byte_value = lval.byte_value <= rval.byte_value;
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = ((UInt) lval.byte_value) <= rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.byte_value) <= rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.byte_value) <= rval.float_value;
					break;
			}
			break;
		case TYPE_UINT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value <= ((Byte) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_UINT;
					result.uint_value = lval.uint_value <= rval.uint_value;
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = ((Int) lval.uint_value) <= rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.uint_value) <= rval.float_value;
					break;
			}
			break;
		case TYPE_INT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_INT;
					result.int_value = lval.int_value <= ((Int) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value <= ((Int) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_INT;
					result.int_value = lval.int_value <= rval.int_value;
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = ((Float) lval.int_value) <= rval.float_value;
					break;
			}
			break;
		case TYPE_FLOAT:
			switch (rval.type) {
				case TYPE_BYTE:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value <= ((Float) rval.byte_value);
					break;
				case TYPE_UINT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value <= ((Float) rval.uint_value);
					break;
				case TYPE_INT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value <= ((Float) rval.int_value);
					break;
				case TYPE_FLOAT:
					result.type = TYPE_FLOAT;
					result.float_value = lval.float_value <= rval.float_value;
					break;
			}
			break;
	}

	array_set(vm->stack, raddr, &result);
	return raddr;
}

Register vm_pop(VM *vm) {
	Register reg;
	array_pop(vm->stack, &reg);
	return reg;
}

Register vm_get(VM *vm, Addr index) {
	Register reg;
	array_get(vm->stack, index, &reg);
	return reg;
}

Register vm_reg(VM *vm, Addr index) {
	Register reg;
	Addr addr = vm->stack->length - index;
	array_get(vm->stack, addr, &reg);
	return reg;
}

void vm_set(VM *vm, Addr index, Register reg) {
	array_set(vm->stack, index, &reg);
}

void vm_stack_dump(VM *vm) {
	for (int i = 0; i < vm->stack->length; i++) {
		printf("%4d: ", i);
		Register reg = vm_get(vm, i);
		switch (reg.type) {
		case TYPE_BYTE:
			printf("(byte)     %10d\n", reg.byte_value);
			break;
		case TYPE_UINT:
			printf("(uint)     %10lu\n", reg.uint_value);
			break;
		case TYPE_INT:
			printf("(int)      %10ld\n", reg.int_value);
			break;
		case TYPE_FLOAT:
			printf("(float)    %10f\n", reg.float_value);
			break;
		default:
			printf("(undefined) \n");
			break;
		}
	}
	printf("Total: %lu\n", vm->stack->length);
}

void vm_commands_dump(VM *vm) {
	printf("%5s%10s %13s %10s %10s\n", "", "command", "addr", "arg", "raddr");
	for (int i = 0; i < vm->commands->length; i++) {
		if (i == vm->cmd_ptr)
			printf("> %4d: ", i);
		else
			printf("  %4d: ", i);
		Command cmd;
		array_get(vm->commands, i, &cmd);
		switch (cmd.code) {
		case CMD_COPY:
			printf("%-10s", "copy");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10s", "-");
			break;
		case CMD_ASSIGN:
			printf("%-10s", "assign");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10s", "-");
			break;
		case CMD_SET_BYTE:
			printf("%-10s", "set_byte");
			printf(" %10ld", cmd.addr);
			printf(" %10d", cmd.byte_arg);
			printf(" %10s", "-");
			break;
		case CMD_SET_UINT:
			printf("%-10s", "set_uint");
			printf(" %10ld", cmd.addr);
			printf(" %10lu", cmd.uint_arg);
			printf(" %10s", "-");
			break;
		case CMD_SET_INT:
			printf("%-10s", "set_int");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.int_arg);
			printf(" %10s", "-");
			break;
		case CMD_SET_FLOAT:
			printf("%-10s", "set_float");
			printf(" %10ld", cmd.addr);
			printf(" %10f", cmd.float_arg);
			printf(" %10s", "-");
			break;
		case CMD_ADD:
			printf("%-10s", "add");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10ld", cmd.raddr);
			break;
		case CMD_SUB:
			printf("%-10s", "sub");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10ld", cmd.raddr);
			break;
		case CMD_MULT:
			printf("%-10s", "mult");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10ld", cmd.raddr);
			break;
		case CMD_DIV:
			printf("%-10s", "div");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10ld", cmd.raddr);
			break;
		case CMD_AND:
			printf("%-10s", "and");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10ld", cmd.raddr);
			break;
		case CMD_OR:
			printf("%-10s", "or");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10ld", cmd.raddr);
			break;
		case CMD_XOR:
			printf("%-10s", "xor");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10ld", cmd.raddr);
			break;
		case CMD_NOT:
			printf("%-10s", "not");
			printf(" %10ld", cmd.addr);
			printf(" %10s", "-");
			printf(" %10ld", cmd.raddr);
			break;
		case CMD_JUMP:
			printf("%-10s", "jump");
			printf(" %10ld", cmd.addr);
			printf(" %10s", "-");
			printf(" %10s", "-");
			break;
		case CMD_JCOND:
			printf("%-10s", "jcond");
			printf(" %10ld", cmd.addr);
			printf(" %10ld", cmd.addr_arg);
			printf(" %10s", "-");
			break;
		case CMD_POP:
			printf("%-10s", "pop");
			printf(" %10s", "-");
			printf(" %10s", "-");
			printf(" %10s", "-");
			break;
		case CMD_PUSH:
			printf("%-10s", "push");
			printf(" %10s", "-");
			printf(" %10s", "-");
			printf(" %10s", "-");
			break;
		case CMD_STACK:
			printf("%-10s", "stack");
			printf(" %10s", "-");
			printf(" %10s", "-");
			printf(" %10s", "-");
			break;
		case CMD_COMMANDS:
			printf("%-10s", "commands");
			printf(" %10s", "-");
			printf(" %10s", "-");
			printf(" %10s", "-");
			break;
		case CMD_PRINT:
			printf("%-10s", "print");
			printf(" %10ld", cmd.addr);
			printf(" %10s", "-");
			printf(" %10s", "-");
			break;
		}
		printf("\n");
	}
	if (vm->cmd_ptr == vm->commands->length)
		printf(">\n");
	printf("Total: %lu\n", vm->commands->length);
}

void vm_register_dump(VM *vm, Addr addr) {
	if (addr >= 0 && addr < vm->stack->length) {
		Register reg = vm_get(vm, addr);
		printf("#%li: ", addr);
		switch (reg.type) {
		case TYPE_BYTE:
			printf("(byte) %d\n", reg.byte_value);
			break;
		case TYPE_UINT:
			printf("(uint) %lu\n", reg.uint_value);
			break;
		case TYPE_INT:
			printf("(int) %ld\n", reg.int_value);
			break;
		case TYPE_FLOAT:
			printf("(float) %f\n", reg.float_value);
			break;
		default:
			printf("default\n");
			break;
		}
	}
	else {
		printf("Out of stack\n");
	}
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
