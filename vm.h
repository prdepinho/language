#ifndef __VM_H__
#define __VM_H__

#include <stdlib.h>
#include <stdint.h>
#include "array.h"
#include "types.h"

/**
 * Commands for the virtual machine. A command has three arguments: addr, *_arg and raddr.
 * See Command struct below for detail.
 */
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
	CMD_AND = 13,		// Set to raddr the bitwise AND operator between addr and addr_arg.
	CMD_OR = 14,		// Set to raddr the bitwise OR operator between addr and addr_arg.
	CMD_XOR = 15,		// Set to raddr the bitwise XOR operator between addr and addr_arg.
	CMD_NOT = 16,		// Set to raddr the bitwise NOT operator of addr.
	CMD_PUSH = 17,		// Push an undefined value in the stack.
	CMD_POP = 18,		// Pop a value from the stack.
	CMD_STACK = 19,		// Dump the stack.
	CMD_COMMANDS = 20,	// Dump the command list.
	CMD_PRINT = 21,		// Dump the value of addr.
};
// and, or, xor, not, compare

/**
 * Variable types.
 */
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
 * Add a command to the machine with vm_push_cmd.
 * Alternatively, use the vm_push_cmd_* to push specific commands to the vm without messing with the structures.
 * Run the machine with vm_execute.
 * Clear the commands with vm_clear_commands.
 * 
 */
typedef struct VM {
	Addr cmd_ptr;		// The current point of execution. Points to an element in commands.
	Array *commands;	// The list of commands to execute. An array of Command objects.
	Array *stack;		// The memory of the machine. An array of Register objects.
} VM;


// Public functions:

VM *vm_new();
void vm_delete(VM *vm);

int vm_run(VM *vm);
Addr vm_execute(VM *vm, Command cmd);
Addr vm_push_cmd(VM *vm, Command cmd);
void vm_clear_commands(VM *vm);

// The following vm_push_cmd_* functions are there to help push commands to the machine.
// Parameters addr, addr_arg and raddr are absolute addresses and refer to the stack.

void vm_push_cmd_set_byte(VM *vm, Addr addr, Byte byte_arg); 
void vm_push_cmd_set_int(VM *vm, Addr addr, Int int_arg); 
void vm_push_cmd_set_uint(VM *vm, Addr addr, UInt uint_arg); 
void vm_push_cmd_set_float(VM *vm, Addr addr, Float float_arg); 

void vm_push_cmd_add(VM *vm, Addr addr, Addr addr_arg, Addr raddr); 
void vm_push_cmd_sub(VM *vm, Addr addr, Addr addr_arg, Addr raddr); 
void vm_push_cmd_mult(VM *vm, Addr addr, Addr addr_arg, Addr raddr); 
void vm_push_cmd_div(VM *vm, Addr addr, Addr addr_arg, Addr raddr); 

void vm_push_cmd_jump(VM *vm, Addr addr);
void vm_push_cmd_jcond(VM *vm, Addr addr, Addr addr_arg); 

void vm_push_cmd_push(VM *vm);
void vm_push_cmd_pop(VM *vm);

void vm_push_cmd_and(VM *vm, Addr addr, Addr addr_arg, Addr raddr);
void vm_push_cmd_or(VM *vm, Addr addr, Addr addr_arg, Addr raddr);
void vm_push_cmd_xor(VM *vm, Addr addr, Addr addr_arg, Addr raddr);
void vm_push_cmd_not(VM *vm, Addr addr, Addr raddr);

void vm_push_cmd_stack(VM *vm);
void vm_push_cmd_commands(VM *vm);
void vm_push_cmd_print(VM *vm, Addr addr);


// Private functions:

// Tranforms negative (relative) addr in absolute addr in the stack.
#define VM_ABS_ADDR(vm, addr) {if (addr < 0) return vm->stack->length + addr; else return addr;}

void vm_stack_dump(VM *vm);
void vm_commands_dump(VM *vm);
void vm_register_dump(VM *vm, Addr addr);

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
Addr vm_and(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr);
Addr vm_or(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr);
Addr vm_xor(VM *vm, Addr lval_addr, Addr rval_addr, Addr raddr);
Addr vm_not(VM *vm, Addr lval_addr, Addr raddr);

Register vm_pop(VM *vm);
Register vm_get(VM *vm, Addr index);	// get a register in absolute address.
Register vm_reg(VM *vm, Addr index);	// get a register in relative address.

void vm_set(VM *vm, Addr index, Register reg);

Addr vm_get_addr(VM *vm, Addr index);
Byte vm_get_byte(VM *vm, Addr index);
UInt vm_get_uint(VM *vm, Addr index);
Int vm_get_int(VM *vm, Addr index);
Float vm_get_float(VM *vm, Addr index);
void *vm_get_ptr(VM *vm, Addr index);

#endif /* __VM_H__ */
