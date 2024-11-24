.data
welcome_msg:	.asciiz "\nWelcome to Connect Four. Let's start a two player game...\n"
repeat_msg:		.asciiz "\nGo again? Y/N > "
invalid_msg:	.asciiz "\nInvalid input. Try again!\n"
bye: 			.asciiz "\nToodles! ;)"

hangman:		.asciiz "\n ___   you lose!\n|   | /\n|    \n|  /|\\\n|  / \\\n|_____"

head_loc:		.word	30
head_char:		.ascii "O"

word_1:		.asciiz	"blah"
word_array:	.word	word_1

buffer:			.space	2

.globl main

.text
####################################################################################################
# function: main
# purpose: to control program flow
# registers used:
#	$a0 - argument passed
#	$s0 - decimal places found in get_int
####################################################################################################
main:								#
	jal		welcome					# welcome the user

	li		$a0, 0					# 0 wrong guesses
	j		game_loop_prep			# play the game!
		
####################################################################################################
# function: get_input
# purpose: to get the column the player would like to drop their token in.
# registers used:
####################################################################################################
get_input:									#
		li		$v0, 4						#
		syscall								# print player prompt
											#
		li		$v0, 8						#
		la		$a0, buffer					#
		li		$a1, 2						#
		syscall								# get player input
											#
		lb		$v0, 0($a0)					# load first byte from buffer
		jr		$ra							#
		
####################################################################################################
# function: invalid_play
# purpose: to raise an invalid play flag and return to caller
# registers used:
####################################################################################################
invalid_play:					#
	la	$a0, invalid_msg		# 
	li	$v0, 4					#
	syscall						# print invalid message
								#
	li	$v1, 1					# set invalid flag
								#
	jr $ra						# and return to caller
								#
####################################################################################################
# function: reset_buffer
# purpose: to reset the buffer for stability and security
# registers used:
#	$t0 - buffer address
#	$t1 - buffer length
#	$t2 - reset value (0)
#	$t3 - iterator
####################################################################################################	
reset_buffer:									#
	move		$t0, $a0						# buffer to $t0
	move		$t1, $a1						# buffer_size to $t1
	li			$t2, 0							# to reset values in buffer
	li 			$t3, 0							# initialize iterator
	reset_buffer_loop:							#
		bge 	$t3, $t1, reset_buffer_return	#
		sw		$t2, 0($t0)						# store a 0
		addi	$t0, $t0, 4						# next word in buffer
		addi 	$t3, $t3, 1						# iterate it!
		j reset_buffer_loop 					# and loop!
	reset_buffer_return:						#
		jr 		$ra								#
												#
####################################################################################################
# macro: upper
# purpose: to make printing messages more eloquent
# registers used:
#	$t0 - string to check for upper case
#	$t1 - ascii 'a', 'A'-'Z' is all lower value than 'a'
# variables used:
#	%message - message to be printed
####################################################################################################		
upper:							#
	move $s0, $ra				#
	move $t0, $a0				# load the buffer address
	li $t1, 'a'					# lower case a to compare
	upper_loop:					#
		lb $t2, 0($t0)			# load next byte from buffer
		blt $t2, $t1, is_upper	# bypass uppercaserizer if character is already upper case (or invalid)
		to_upper:				# 
			subi $t2, $t2, 32	# Convert to uppercase (ASCII difference between 'a' and 'A' is 32)
		is_upper:				#
			sb $t2, 0($t0)		# store byte
		addi $t0, $t0, 1		# next byte
		bne $t2, 0, upper_loop	# if not end of buffer go again!
	move $ra, $s0				#
	jr $ra						#
								#
####################################################################################################
# function: again
# purpose: to user to repeat or close the program
# registers used:
#	$v0 - syscall codes
#	$a0 - message storage for print and buffer storage
#	$t0 - stores the memory address of the buffer and first character of the input received
#	$t1 - ascii 'a', 'Y', and 'N'
####################################################################################################
again:							#		
	la $a0, repeat_msg			#
	li $v0, 4					#
	syscall						#
								#
	la $a0, buffer				#
	la $a1, 2					#
	li $v0, 8					#
	syscall						#
								#
	la $a0, buffer				#
	jal upper					# load the buffer for string manipulation
								#
	la $t0, buffer				#
	lb $t0, 0($t0)				#
	li $t1, 'Y'					# store the value of ASCII 'Y' for comparison
	beq $t0, $t1, re_enter		# If yes, go back to the start of main
	li $t1, 'N'					# store the value of ASCII 'N' for comparison
	beq $t0, $t1, end			# If no, goodbye!
	j again_invalid				# if invalid try again...
								#
	again_invalid:				#
		la $a0, invalid_msg		#
		li $v0, 4				#
		syscall					#
								#
####################################################################################################
# function: end
# purpose: to eloquently terminate the program
# registers used:
#	$v0 - syscall codes
#	$a0 - message addresses
####################################################################################################	
end:	 					#
	la		$a0, bye		#
	li		$v0, 4			#
	syscall					#
							#
	li 		$v0, 10			# system call code for returning control to system
	syscall					# GOODBYE!
							#
####################################################################################################	
	
# get memory locations for body parts and lose message
# test sb for body part