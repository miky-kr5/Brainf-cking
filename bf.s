 .section .data
ptr:
	.long 0
loop_ptr:
	.long 0
ret_code:
	.long 0
error_str:
	.asciz "%s: fatal error: no input files\n"
bad_file:
	.asciz "File %s could not be opened\n"
mode:
	.asciz "r"
bad_loop:
	.asciz "%s: fatal error: more than 1024 nested loops\n"
skip:
	.long 0 /* Boolean flag to indicate that a badly formatted bf file must be skipped */
debug_str:
	.asciz "Tape[%05d]: % 4d\n"
	
.section .rodata
.align 4
/* Jump table for the exec_bf_inst function */
.L10:
	.long .L0       /* # = 35 */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long .L1       /* + = 43 */
	.long .L2       /* , = 44 */
	.long .L3       /* - = 45 */
	.long .L4       /* . = 46 */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long .L5       /* < = 60 */
	.long epilogue2 /* Default */
	.long .L6       /* > = 62 */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long epilogue2 /* Default */
	.long .L7       /* [ = 91 */
	.long epilogue2 /* Default */
	.long .L8       /* ] = 93 */
	.long epilogue2 /* Default */

.section .bss
	.comm bf_file, 4      /* Address of the current bf file's FILE structure */
	.comm bf_file_name, 4 /* Address of the current bf file name */
	.comm tape, 30000     /* 30000 unsigned byte cells for the tape */
	.comm jmp_stack, 4100 /* 1024 long words to store bf loop adresses + 1 safeguard byte */

.section .text
.globl _start
_start:
	movl (%esp), %ecx  /* Get argc */
	decl %ecx          /* Substract 1 from argc */
	movl 4(%esp), %ebx /* Get program name */
	movl 8(%esp), %edx /* Get argv[1] */

	/* if (argc - 1) == 0 then error */
	cmpl $0, %ecx
	jne eif1
	/* Print error message, set return code and exit */
	pushl %ebx
	pushl $error_str
	call printf
	addl $8, %esp
	movl $1, ret_code
	jmp end

eif1:
	/* Loop through all arguments */
	movl $0, %edi
loop_start:
	/* Reset everything. */
	pushl %eax
	pushl %ecx
	pushl %edx
	pushl $30000
	pushl $0
	pushl $tape
	call memset
	addl $12, %esp
	popl %edx
	popl %ecx
	popl %eax

	pushl %eax
	pushl %ecx
	pushl %edx
	pushl $4100
	pushl $0
	pushl $jmp_stack
	call memset
	addl $12, %esp
	popl %edx
	popl %ecx
	popl %eax

	movl $0, ptr
	movl $0, loop_ptr
	
	/* Process current input file */
	pushl %eax
	pushl %ecx
	pushl %edx
	pushl %edx
	call interpret
	addl $4, %esp
	popl %edx
	popl %ecx
	popl %eax

	/* Get current argument length */
	pushl %ecx
	pushl %edx
	pushl %edi
	pushl %edx
	call strlen
	add $4, %esp
	popl %edi
	popl %edx
	popl %ecx

	/* Skip the characters from current arg + null char at the end */
	addl $1, %eax
	addl %eax, %edx

	/* Increase arg counter and test loop end condition */
	incl %edi
	cmpl %ecx, %edi
	jne loop_start
	
end:
	movl $1, %eax
	movl ret_code, %ebx
	int $0x80

/* This function processes a Brainfuck file one instruction at a time.
   Parameters:	 The name of the file as a C string. */
interpret:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	movl 8(%ebp), %ebx /* Get the file name*/

	/* Open input file */
	pushl %ebx /* Save the file name */
	pushl $mode
	pushl %ebx /* ebx holds the file name*/
	call fopen /* eax will hold the file pointer from now on */
	addl $8, %esp
	popl %ebx /* Restore the file name */
	movl %eax, bf_file /* Store the file ptr in memory */
	movl %ebx, bf_file_name /* Store the file ptr in memory */
	
	/* Check if file is open */
	cmpl $0, %eax
	jne echo
	/* If file is NULL then print an error msg and exit */
	pushl %ebx /* Save the file name */
	pushl %ebx 
	pushl $bad_file
	call printf
	addl $8, %esp
	popl %ebx /* Restore the file name */
	jmp epilogue1
	
	/* Process the file */
echo:
	/* Check if this file must be skipped */
	/* Only happens if max loops is reached */
	movl skip, %esi
	cmpl $0, %esi
	movl $0, skip
	jne close
	
	/* Read 1 byte from the file */
	pushl %ebx /* Save the file name */
	pushl %eax /* Save the file pointer */
        pushl %eax
        call fgetc
        addl $4, %esp
        movl %eax, %ecx /* ecx will hold the char read */
	popl %eax /* Restore the file pointer */
	popl %ebx /* Restore the file name */

	/* Test for EOF */
	pushl %ebx /* Save the file name */
	pushl %eax /* Save the file pointer */
	pushl %ecx /* Save the char */
	pushl %eax
	call feof
	addl $4, %esp
	movl %eax, %edx
	popl %ecx /* Restore the char */
	popl %eax /* Restore the file pointer */
	popl %ebx /* Restore the file name */
	cmpl $0, %edx
	jne close

	/* Execute the corresponding instruction */
	pushl %ebx /* Save the file name */
	pushl %eax /* Save the file pointer */
	pushl %ecx
	call exec_bf_inst
	addl $4, %esp
	popl %eax /* Restore the file pointer */
	popl %ebx /* Restore the file name */
	jmp echo

	/* Close input file */
close:
	pushl %eax
	call fclose
	addl $4, %esp
	
epilogue1:
	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Function that executes a BF instruction by calling the appropiate subroutine
   with a switch construct.
   Parameters:	 The instruction as a char.*/
exec_bf_inst:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	movl 8(%ebp), %ebx /* Get the instruction */

	/* Determine wich case the instruction falls into */
	subl $35, %ebx
	cmpl $58, %ebx
	ja epilogue2
	jmp *.L10(,%ebx, 4)

.L0: /* # = 35 */
	call debug_tape
	jmp epilogue2
.L1: /* + = 43 */
	call add_cell
	jmp epilogue2
.L2: /* , = 44 */
	call input_cell
	jmp epilogue2
.L3: /* - = 45 */
	call sub_cell
	jmp epilogue2
.L4: /* . = 46 */
	call output_cell
	jmp epilogue2
.L5: /* < = 60 */
	call move_left
	jmp epilogue2
.L6: /* > = 62 */
	call move_right
	jmp epilogue2
.L7: /* [ = 91 */
	call bf_loop_start
	jmp epilogue2
.L8: /* ] = 93 */
	call bf_loop_end

/* The function's epilogue doubles as defaut */
epilogue2:
	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: > */
move_right:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* Increase the tape pointer by 1 looping around on cell 29999 */
	movl ptr, %eax
	incl %eax
	cmpl $30000, %eax
	jl end_mr
	movl $0, %eax
end_mr:
	movl %eax, ptr /* Update the tape pointer */

	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: < */
move_left:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* Decrease the tape pointer by 1 looping around on cell 0 */
	movl ptr, %eax
	decl %eax
	cmpl $0, %eax
	jge end_ml
	movl $29999, %eax
end_ml:
	movl %eax, ptr /* Update the tape pointer */

	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: + */
add_cell:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* Just add 1 on the tape */
	movl ptr, %eax
	incb tape(, %eax, 1)

	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: - */
sub_cell:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* Just substract 1 on the tape */
	movl ptr, %eax
	decb tape(, %eax, 1)

	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: . */
output_cell:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* Print wathever is on the tape as ascii */
	movl ptr, %eax
	xorl %ebx, %ebx
	movb tape(, %eax, 1), %bl
	pushl %ebx
	call putchar
	addl $4, %esp

	/* Since we are printing just one char we must flush stoud to make sure it actually prints
	   instead of just being buffered by the OS */
	pushl stdout
	call fflush
	addl $4, %esp
	
	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: , */
input_cell:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* Read one char on stdin */
	xorl %eax, %eax
	call getchar
	movl ptr, %ebx
	movb %al, tape(, %ebx, 1)

input_end:
	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: # */
debug_tape:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* First move the tape pointer 5 positions to the left*/
	movl $0, %edi
.W1:
	call move_left
	incl %edi
	cmpl $5, %edi
	jl .W1

	/* Then loop through the next 11 tape positions and print them */
	movl $0, %edi
print_loop:
	movl ptr, %eax
	xorl %ebx, %ebx
	movb tape(, %eax, 1), %bl
	pushl %ebx
	pushl %eax
	pushl $debug_str
	call printf
	addl $12, %esp
	call move_right
	incl %edi
	cmpl $11, %edi
	jl print_loop

	/* Flush stdout for the same reasons as in . */
	pushl stdout
	call fflush
	addl $4, %esp

	/* Finally restore the tape pointer to it's original position */
	movl $0, %edi
.W2:
	call move_left
	incl %edi
	cmpl $6, %edi
	jl .W2

	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: [ */
bf_loop_start:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	movl loop_ptr, %ebx
	cmpl $1024, %ebx
	jl check_loop
	pushl bf_file_name
	pushl $bad_loop
	call printf
	addl $8, %esp
	movl $1, skip
	jmp epilogue_ls

check_loop:
	call cell_is_zero
	cmpl $0, %eax
	je push_loop
	call find_matching_le
	jmp epilogue_ls

push_loop:	
	pushl %ebx
	pushl bf_file
	call ftell
	addl $4, %esp
	popl %ebx

	movl %eax, jmp_stack(, %ebx, 4)
	incl %ebx
	movl %ebx, loop_ptr

epilogue_ls:
	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Instruction: ] */
bf_loop_end:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* Check if the current cell is 0 and loop if it isn't */
	call cell_is_zero
	cmpl $0, %eax
	je loop

	/* If the current cell is 0 then pop the last loop address */
	movl loop_ptr, %ebx
	decl %ebx
	movl $0, jmp_stack(, %ebx, 4)
	movl %ebx, loop_ptr
	jmp epilogue_le

loop:
	movl bf_file, %eax
	movl loop_ptr, %ebx
	decl %ebx
	movl jmp_stack(, %ebx, 4), %ecx
	pushl $0 /* SEEK_SET */
	pushl %ecx
	pushl %eax
	call fseek
	addl $12, %esp

epilogue_le:
	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* This function returns 1 if the current tape cell is 0, returns 0 otherwise */
cell_is_zero:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	/* Check if the current cell is 0 */
	xorl %ebx, %ebx
	movl ptr, %eax
	movb tape(, %eax, 1), %bl
	cmpb $0, %bl
	jne .FALSE1
.TRUE1:
	movl $1, %eax
	jmp epilogue_cz
.FALSE1:
	movl $0, %eax

epilogue_cz:
	popl %esi
	popl %edi
	popl %ebx
	leave
	ret

/* Function that searches through the BF file in search of the matching ] for a given [.
   NOTE: Doesn't handle mismatched loops */
find_matching_le:
	pushl %ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %edi
	pushl %esi

	movl $1, %ebx
find_loop:
	pushl %ebx
	pushl bf_file
	call fgetc
	addl $4, %esp
	popl %ebx

	/* TODO: Check for EOF and skip file if a premature EOF is found */
	
	cmpl $93, %eax
	jne new_loop
	decl %ebx
	cmpl $0, %ebx
	jne find_loop
	jmp epilogue_fm
new_loop:
	cmpl $91, %eax
	jne find_loop
	addl $1, %ebx
	jmp find_loop
	
epilogue_fm:
	popl %esi
	popl %edi
	popl %ebx
	leave
	ret
