# Program #11: Connect Four
# Author: Lazlo F. Steele
# Due Date : Nov. 23, 2024 Course: CSC2025-2H1
# Created: Nov. 22, 2024
# Last Modified: Nov. 26, 2024
# Functional Description: Play hangman.
# Language/Architecture: MIPS 32 Assembly
####################################################################################################
# Algorithmic Description:
#	welcome user
#	generate random number from 0-9
#	load word from word array at index of random number
#	while player has not won or lost:
#		display game state
#		if all letters have been guessed you win!
#		choose letter
#			if letter is not valid or has been guessed then try again
#			otherwise:
#				if letter is not in word add a missed guess
#				otherwise pass
#			add any additional body parts if needed
#			if 6 missed guesses you lose!
#	play again?
####################################################################################################

					.data
welcome_msg:		.asciiz "\nI am the hangman. Let's play a game...\n"
player_prompt:		.asciiz "\n\nPlease enter a letter > "
repeat_msg:			.asciiz "\nGo again? Y/N > "
win_msg:			.asciiz "\nYou win!"
invalid_msg:		.asciiz "\nInvalid input. Try again!\n"
bye: 				.asciiz "\nToodles! ;)"

hangman:			.asciiz "\n ___            \n|   |  \n|    \n|     \n|     \n|_____\n\n"
hangman_template:	.asciiz "\n ___            \n|   |  \n|    \n|     \n|     \n|_____\n\n"
					
					.align	2
lose_loc1:			.word	5
lose_loc2:			.word	24
head_loc:			.word	30
body_loc:			.word	36
larm_loc:			.word	35
rarm_loc:			.word	37
lleg_loc:			.word	42
rleg_loc:			.word	44

					.align	0
head_char:			.ascii "O"
body_char:			.ascii "|"
larmleg_char:		.ascii "/"
rarmleg_char:		.ascii "\\"
lose_msg:			.ascii "   you lose!"


word_1:				.asciiz	"BONKERS"
word_2:				.asciiz "PREPARATION"
word_3:				.asciiz "DISTRIBUTOR"
word_4:				.asciiz "DEVELOPER"
word_5:				.asciiz "POPULAR"
word_6:				.asciiz "BOUNCE"
word_7:				.asciiz "RAILROAD"
word_8:				.asciiz "DEFENDANT"
word_9:				.asciiz "LIGHTER"
word_10:			.asciiz "OFFSET"

					.align	2
word_array:			.word	word_1, word_2, word_3, word_4, word_5, word_6, word_7, word_8, word_9, word_10

buffer:				.space	2
guessed_letters:	.space	26

					.globl main

					.text
####################################################################################################
# function: main
# purpose: to control program flow
# registers used:
#	$a0 - argument passed
#	$s0 - wrong guesses
#	$s1 - secret word!
####################################################################################################
main:								#
	jal		welcome					# welcome the user
									#
	jal		get_random_word			# and validate
									#
	li		$s0, 0					# 0 wrong guesses
	move	$s1, $v0				#
	j		game_loop				# play the game!	
									#
####################################################################################################
# function: get_random_word
# purpose: to return a random word from a list stored in .data
# registers used:
#	$v0 - syscall codes, return value
#	$a0 - passing arugments to subroutines
#	$a1 - passing arguments to subroutines
#	$t0 - word array
#	$t1 - bits n bobs
#	$ra	- return address
####################################################################################################	
get_random_word:				#
	la		$t0, word_array		# load the word array
								#
	li		$v0, 30				# get time in milliseconds to use for seed
	syscall						#
								#
	move	$t1, $a0			# save the lower 32-bits of time
								#
	li		$a0, 1				# random generator 1
	move	$a1, $t1 			# seed is the time stored in $t1
	li		$v0, 40				# 
	syscall						# save generator
								#
	li		$a0, 1				# load generator 1
	li		$a1, 9				# random int from 0-9
	li		$v0, 42				#
	syscall						# generate it! for use in offset
								#
	move	$t1, $a0			# move the offset to $t0
								#
	mul		$t1, $t1, 4			# multiply by four for word offset
	add		$t0, $t0, $t1		# add the offset to the start of the word array
	lw		$v0, 0($t0)			# load the word (address of secret word) to $v0
								#
	jr	$ra						# return to caller
								#
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
game_loop:								#
	li		$v1, 0						# reset invalid play flag
										#
	move	$s2, $ra					# save return address for nesting
	jal		display_board				# and display game state!
	move	$ra, $s2					# restore return address for nesting
										#
	move	$s2, $ra					# save return address for nesting
	jal		get_input					# and get input!
	move	$ra, $s2					# restore return address for nesting
										#
	move	$s2, $ra					# save return address for nesting
	la		$a0, buffer					# load buffer
	jal		upper						# and convert to upper case
	la		$t0, buffer					# load buffer to $t0
	lb		$v0, 0($t0)					# load upper case character to $v0
	move	$ra, $s2					# restore return address for nesting
										#
	move	$s2, $ra					# save return address for nesting
	move	$a0, $v0					# move returned user input to argument
	jal		validate_input				# and validate
	move	$ra, $s2					# restore return address for nesting
	beq		$v1, 1, game_loop			# if invalid play, try again
										#
	move	$s2, $ra					# save return address for nesting
	move	$a0, $v0					# move returned user input to argument
	jal		check_guess					# and check for letter in word
	move	$ra, $s2					# restore return address for nesting
										#
	move	$s2, $ra					# save return address for nesting
	jal		add_body_part				# add body parts if needed
	move	$ra, $s2					# restore return address for nesting
										#
	beq		$s0, 6, game_over			# if 6 guesses game over
										#
	j		game_loop					# let's do the time warp again!
										#
####################################################################################################
# function: game_over
# purpose: you lose.
# registers used:
####################################################################################################
game_over:						#
	la $t1, hangman				# load the hangman graphic
								#
	lw	$t0, lose_loc1			# get location in string of where the lose message goes
	add $t1, $t1, $t0			# offset the hangman graphic
								#
	la	$t4, lose_msg			# load the lose message
	li	$t3, 0					# initialize iterator for characters in message
	you_lose_loop:				#
		beq	$t3, 12, you_lose	# if the iterator has hit end of the message move on
		lb $t2, 0($t4)			# load the next character of the lose message
		sb $t2, 0($t1)			# store it in the next character of the hangman graphic
								#
		addi $t1, $t1, 1		# iterate the graphic
		addi $t3, $t3, 1		# iterate the iterator
		addi $t4, $t4, 1		# iterate the message
								#
		j	you_lose_loop		# and do the time warp again!
								#
	you_lose:					#
		la $t1, hangman			# load the hangman graphic
		lw	$t0, lose_loc2		# load the location for a speech line
								# 
		add	$t1, $t1, $t0		# offset the graphic
								#
		lb $t2, larmleg_char	# load a left limb for speech line
		sb $t2, 0($t1)			# store in the location
								#
		la		$a0, hangman	# load the hangman graphic to print
		li		$v0, 4			#
		syscall					# print it!
								#
	j		again				# try again???
								#
####################################################################################################
# function: display_board
# purpose: to display the state of the game.
# registers used:
####################################################################################################
display_board:							#
	la		$a0, hangman				# load the hangman graphic
	li		$v0, 4						#
	syscall								# and print!
										#
	move	$t0, $s1					# make a working copy of the secret word
	li		$t7, 1						# win flag
										# 
	word_length_loop:					#
		lb	$t1, 0($t0)					# load the next character of the secret word
		beq	$t1, 0, word_loop_done		# if null terminated then done!
										#
		li		$t2, 'A'				# subtract 'A' to get shift offset for alphabet
		sub		$t2, $t1, $t2			# 
										#
		la	$t3, guessed_letters		# load guessed letters
		add	$t3, $t3, $t2				# offset to the current working letter
		lb	$t2, 0($t3)					# to pull whether the letter has been guessed
										#
		beq $t1, $t2, letter_guessed	# if guessed then go to print that letter
										#
		li		$a0, '_'				# otherwise load a '_' to print
		li		$t7, 0					# and you have not won... yet
										#
		j	print_char					# go to print!
										#
		letter_guessed:					#
			move	$a0, $t1			# load the current letter to display
										#
		print_char:						#
			li		$v0, 11				# 
			syscall						# print the loaded character
										#
			li		$a0, ' '			#
			syscall						# print a space
										#
			addi	$t0, $t0, 1			# iterate the working secret word
										#
			j	word_length_loop		# and do the time warp again
										#
	word_loop_done:						#
		beq		$t7, 1, you_win			# did you win?
										#
		jr		$ra						# if not continue the game
										#
		you_win:						# if you did:
			la	$a0, win_msg			# 
			li	$v0, 4					#
			syscall						# display a victory message
										#
			j again						# and play again???
										#
####################################################################################################
# function: check_guess
# purpose: to get the column the player would like to drop their token in.
# registers used:
####################################################################################################
check_guess:							#
	move	$t0, $s1					# load working copy of secret word
	move	$t1, $v0					# load current guess
										#
	check_guess_loop:					#
		lb	$t2, 0($t0)					# load the next character of the secret word
		beq $t2, $t1, check_guess_done	# if they are equal, move along
										#
		addi $t0, $t0, 1				# iterate the secret word
		beqz	$t2, letter_missed		# if reached end of word then guess wrong
										#
		j	check_guess_loop			# do the timewarp again!
										#
	letter_missed:						#
		addi	$s0, $s0, 1				# add a wrong guess
	check_guess_done:					#
		jr	$ra							# and go back home
										#
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
add_body_part:					#
	la $t1, hangman				# load hangman graphic
								#
	beq		$s0, 1, add_head	# if 1 wrong guess add the head
	beq		$s0, 2, add_body	# if 2 then add the body
	beq		$s0, 3, add_l_arm	# if 3...
	beq		$s0, 4, add_r_arm	# and so on
	beq		$s0, 5, add_l_leg	# and so forth
	beq		$s0, 6, add_r_leg	# etc... etc...
								#
	jr		$ra					# if no wrong guesses then go home!
								#
	add_head:					# each of these is the same idea...
		lw	$t0, head_loc		# where in the graphic would the head go?
		add $t1, $t1, $t0		# offset graphic by that much
		lb $t2, head_char		# load the body part character
		sb $t2, 0($t1)			# store the body part character in that space
								#
		jr	$ra					# and go home!
								#
	add_body:					#
		lw	$t0, body_loc		#
		add $t1, $t1, $t0		#
		lb $t2, body_char		#
		sb $t2, 0($t1)			#
								#
		jr	$ra					#
								#
	add_l_arm:					#
		lw	$t0, larm_loc		#
		add $t1, $t1, $t0		#
		lb $t2, larmleg_char	#
		sb $t2, 0($t1)			#
								#
		jr	$ra					#
								#
	add_r_arm:					#
		lw	$t0, rarm_loc		#
		add $t1, $t1, $t0		#
		lb $t2, rarmleg_char	#
		sb $t2, 0($t1)			#
								#
		jr	$ra					#
								#
	add_l_leg:					#
		lw	$t0, lleg_loc		#
		add $t1, $t1, $t0		#
		lb $t2, larmleg_char	#
		sb $t2, 0($t1)			#
								#
		jr	$ra					#
								#
	add_r_leg:					#
		lw	$t0, rleg_loc		#
		add $t1, $t1, $t0		#
		lb $t2, rarmleg_char	#
		sb $t2, 0($t1)			#
								#
		jr	$ra					#
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
	beq $t0, $t1, reenter		# If yes, go back to the start of main
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
# function: reenter
# purpose: to clear program to default values for re-entry
# registers used:
#	$v0 - syscall codes
#	$a0 - message addresses
####################################################################################################	
reenter:									#
	la	$t0, hangman_template				# load template graphic
	la	$t1, hangman						# load working graphic
											#
	li	$t3, 0								# initialize iterator for the letters of alphabet
	la	$t4, guessed_letters				# load the guessed letters
	li	$t5, 0								# value to reset guessed letters
											#
	reset_hangman_loop:						#
		lb	$t2, 0($t0)						# load next character of working graphic
		beqz $t2, reset_guessed_letters		# if null termination then move on
											#
		sb	$t2, 0($t1)						# store next character of template graphic
											#
		addi $t0, $t0, 1					# iterate the template
		addi $t1, $t1, 1					# iterate the working graphic
											#
		j	reset_hangman_loop				# do the timewarp... etc...
											#
	reset_guessed_letters:					#
		beq	$t3, 26, reset_done				# if iterator has reached end of the alphabet then done
											#
		sb	$t5, 0($t4)						# store a 0
											#
		addi	$t3, $t3, 1					# iterate the iterator
		addi	$t4, $t4, 1					# iterate the alphabet
											#
		j reset_guessed_letters				# timewarp
											#
	reset_done:								#
	j	main								# truly do the timewarp again
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

