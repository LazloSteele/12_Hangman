.data
hangman: .asciiz "\n ___   you lose!\n|   | /\n|    \n|  /|\\\n|  / \\\n|_____"
head_loc: .word	30
head_char: .ascii "O"
blah:	.asciiz	"blahblah"
blah_p:	.word	blah


.globl main

.text
main:
	la	$a0, hangman
	li	$v0, 4
	syscall

	lw	$t0, head_loc
	move $t1, $a0
	add $t1, $t1, $t0
	lb $t2, head_char
	sb $t2, 0($t1)

	la	$a0, hangman
	li	$v0, 4
	syscall
	
	
# get memory locations for body parts and lose message
# test sb for body parts