# for (int i = 0; i < 10; i++) print(i);

VM_PUSH
VM_SET_INT 1 0		# i = 0

VM_PUSH
VM_SET_INT 2 10		# 10

VM_PUSH
VM_SET_INT 3 1		# 1

PRINT 1				# print(i)

VM_ADD 1 3 1		# i++

VM_PUSH
VM_SUB 2 1 4		# 10 - i

VM_JCOND 7 4		# jump to PRINT 1 if (10 - i) == 0


STACK
