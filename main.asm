.data
welcome_msg:		.asciiz "\nI am the hangman. Let's play a game...\n"
player_prompt:		.asciiz "\n\nPlease enter a letter > "
repeat_msg:			.asciiz "\nGo again? Y/N > "
win_msg:			.asciiz "\nYou win!"
invalid_msg:		.asciiz "\nInvalid input. Try again!\n"
bye: 				.asciiz "\nToodles! ;)"

hangman:			.asciiz "\n ___   you lose!\n|   | /\n|    \n|  /|\\\n|  / \\\n|_____\n\n"
					
					.align	2
head_loc:			.word	30
head_char:			.ascii "O"

word_1:				.asciiz	"ABLAH"
					.align	2
word_array:			.word	word_1

buffer:				.space	2
guessed_letters:	.space	26

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

	la		$t0, word_array
	lw		$t1, 0($t0)

	li		$s0, 0					# 0 wrong guesses
	move	$s1, $t1
	jal		game_loop				# play the game!
	
	j		again
	
####################################################################################################
# function: welcome
# purpose: to welcome the user to our program
# registers used:
#	$v0 - syscall codes
#	$a0 - passing arugments to subroutines
#	$ra	- return address
####################################################################################################	
welcome:							# 
	la	$a0, welcome_msg			# load welcome message
	li	$v0, 4						# 
	syscall							# and print
									#
	jr	$ra							# return to caller
									#
####################################################################################################
# function: game_loop
# purpose: to get the column the player would like to drop their token in.
# registers used:
####################################################################################################
game_loop:
	move	$s2, $ra					# save return address for nesting
	jal		display_board				# and validate
	move	$ra, $s2					# restore return address for nesting
	
	move	$s2, $ra					# save return address for nesting
	jal		get_input					# 
	move	$ra, $s2					# restore return address for nesting

	move	$s2, $ra					# save return address for nesting
	la		$a0, buffer					# move returned user input to argument
	jal		upper						# and validate
	la		$t0, buffer
	lb		$v0, 0($t0)
	move	$ra, $s2					# restore return address for nesting
	
	move	$s2, $ra					# save return address for nesting
	move	$a0, $v0					# move returned user input to argument
	jal		validate_input				# and validate
	move	$ra, $s2					# restore return address for nesting
	beq		$v1, 1, game_loop			# if invalid play, try again
	
	beq		$s0, 6, game_over
	
	j		game_loop
	
game_over:
	jr $ra
	
####################################################################################################
# function: game_loop
# purpose: to get the column the player would like to drop their token in.
# registers used:
####################################################################################################
display_board:
	la		$a0, hangman
	li		$v0, 4
	syscall
	
	la	$t0, word_1
	li	$t7, 1							# do you win?
	li	$t8, 0							# letter in word?
	
	word_length_loop:	
		lb	$t1, 0($t0)
		beq	$t1, 0, word_loop_done

		li		$t2, 'A'				# subtract 'A' to get shift offset for alphabet
		sub		$t2, $t1, $t2			#
				
		la	$t3, guessed_letters
		add	$t3, $t3, $t2
		lb	$t2, 0($t3)					# to pull whether the letter has been guessed
		
		beq $t1, $t2, letter_guessed
		
		li		$a0, '_'
		li		$t7, 0
		
		j	print_char
		
		letter_guessed:
			move	$a0, $t1
			li		$t8, 1
		
		print_char:
			li		$v0, 11
			syscall
			
			li		$a0, ' '
			syscall
			
			addi	$t0, $t0, 1
		
			j	word_length_loop
	word_loop_done:
		beq		$t7, 1, you_win
		beq		$t8, 1, no_hang
		addi	$s0, $s0, 1

		no_hang:
		jr		$ra
		
		you_win:
			la	$a0, win_msg
			li	$v0, 4
			syscall
			
			j again
####################################################################################################
# function: get_input
# purpose: to get the column the player would like to drop their token in.
# registers used:
####################################################################################################
get_input:									#
		la		$a0, player_prompt			#
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
											#
####################################################################################################
# function: validate_input
# purpose: to ensure input is a valid column.
# registers used:
####################################################################################################
validate_input:								#
		move	$t0, $a0					#
											#
		li		$t1, 'Z'					#
		bgt 	$t0, $t1, invalid_play		# if it is greater than '4' then invalid
		li		$t1, 'A'					# 
		blt 	$t0, $t1, invalid_play		# if it is less than '1' then invalid
											#
		sub		$t2, $t0, $t1				# get index of letter in alphabet
											#
		la		$t3, guessed_letters		#
		add		$t3, $t3, $t2				#
		lb		$t4, 0($t3)					#
		beq		$t0, $t4, invalid_play		#
		sb		$t0, 0($t3)					#
											#		
		move	$v0, $t0					# return the validated user input value
											#
		jr		$ra							#
											#
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
	beq $t0, $t1, main			# If yes, go back to the start of main
	li $t1, 'N'					# store the value of ASCII 'N' for comparison
	beq $t0, $t1, end			# If no, goodbye!
								#
	again_invalid:				#
		la $a0, invalid_msg		#
		li $v0, 4				#
		syscall					#
								#
		j again					#
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
