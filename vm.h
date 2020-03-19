#ifndef __VM_H__
#define __VM_H__

#include <stdlib.h>
#include <stdint.h>
#include "array.h"
#include "types.h"

enum CommandCode {
	CMD_SET_BYTE = 1,	// Set byte_arg to addr.
	CMD_SET_INT = 2,	// Set int_arg to addr.
	CMD_SET_UINT = 3,	// Set uint_arg to addr.
	CMD_SET_FLOAT = 4,	// Set float_arg to addr.
	CMD_MALLOC = 5,		// Malloc.
	CMD_FREE = 6,		// Free.
	CMD_ADD = 7,		// Set to raddr the sum of values in addr and addr_arg.
	CMD_SUB = 8,		// Set to raddr the difference of values in addr and addr_arg.	
	CMD_MULT = 9,		// Set to raddr the product of values in addr and addr_arg.
	CMD_DIV = 10,		// Set to raddr the quotient of values in addr and addr_arg.
	CMD_JUMP = 11,		// Set the cmd_ptr of the virtual machine to addr.
	CMD_JCOND = 12,		// Like jump, but only if the value of addr_arg is true.
	CMD_POP = 13		// Pop a value in the stack.
};

enum RegisterType {
	TYPE_INT = 1,
	TYPE_UINT = 2,
	TYPE_FLOAT = 3,
	TYPE_BYTE = 4,
	TYPE_PTR = 5,
	TYPE_ADDR = 6
};

typedef struct Command {
	Byte code;				// Command code in CommandCode enum.
	Addr addr;				// The first argument. An address.
	union {					// The second argument. An address, usually, but may also be a value.
		Addr addr_arg;
		void *ptr_arg;
		Byte byte_arg;
		UInt uint_arg;
		Int int_arg;
		Float float_arg;
	};
	Addr raddr;				// The address of the return value. Used by operators.
} Command;


typedef struct Register {
	uint8_t type;			// The type of the variable in RegisterType enum.
	union {					// The value of the variable.
		Addr addr_value;
		void *ptr_value;
		Byte byte_value;
		UInt uint_value;
		Int int_value;
		Float float_value;
	};
} Register;


/**
 * The virtual machine, which has variable memory, a list of commands and a pointer
 * to the current command in execution.
 *
 * Create a new virtual machine with vm_new and delete it with vm_delete.
 * Add a command to the machine with vm_add_cmd.
 * Run the machine with vm_execute.
 * Clear the commands with vm_clear_commands.
 * 
 */
typedef struct VM {
	Addr cmd_ptr;		// The current point of execution. Points to an element in commands.
	Array *commands;	// The list of commands to execute. An array of Command objects.
	Array *stack;		// The memory of the machine. An array of Register objects.
} VM;


VM *vm_new();
void vm_delete(VM *vm);

int vm_run(VM *vm);
Addr vm_execute(VM *vm, Command cmd);
Addr vm_push_cmd(VM *vm, Command cmd);
void vm_clear_commands(VM *vm);

Addr vm_push(VM *vm);
Addr vm_push_byte(VM *vm, Byte value);
Addr vm_push_int(VM *vm, Int value);
Addr vm_push_uint(VM *vm, UInt value);
Addr vm_push_float(VM *vm, Float value);

void vm_set_byte(VM *vm, Addr index, Byte value);
void vm_set_int(VM *vm, Addr index, Int value);
void vm_set_uint(VM *vm, Addr index, UInt value);
void vm_set_float(VM *vm, Addr index, Float value);

Addr vm_add(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr);
Addr vm_sub(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr);
Addr vm_mult(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr);
Addr vm_div(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr);
Addr vm_jump(VM *vm, Addr addr);
Addr vm_jcond(VM *vm, Addr true_cmd_addr, Addr bool_addr);

Register vm_pop(VM *vm);
Register vm_get(VM *vm, Addr index);
void vm_set(VM *vm, Addr index, Register reg);

Addr vm_get_addr(VM *vm, Addr index);
Byte vm_get_byte(VM *vm, Addr index);
UInt vm_get_uint(VM *vm, Addr index);
Int vm_get_int(VM *vm, Addr index);
Float vm_get_float(VM *vm, Addr index);
void *vm_get_ptr(VM *vm, Addr index);

#endif /* __VM_H__ */
