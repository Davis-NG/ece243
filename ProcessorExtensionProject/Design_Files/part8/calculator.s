.define SW_ADDRESS 0x30
.define HEX_ADDRESS 0x20
.define	LED_ADDRESS 0x10

start:	mvt 	r3, #SW_ADDRESS		// switches
		mvt 	r4, #LED_ADDRESS		// leds
		mvt   	sp, #0x10   		// sp = 0x1000 = 4096

main: 	ld 	r0, [r3]
		mvt	r1, #0x1	
		and 	r0, r1			// 8th switch decides
		cmp 	r0, r1
		beq 	val1
		b 	main	
val1: 
		ld 	r0, [r3]
		and 	r0, #0x7f			// can use first 7 switch to input
		
		mv 	r2, r0				// r2 has the first number
		st	r0, [r4]
		//bl 	current_val
		b 	wait

wait: 		
		ld 	r0, [r3]	
		and 	r0, r1			// 8th switch decides
		cmp 	r0, r1
		beq 	wait
		b 	val2
val2:		
		ld 	r0, [r3]	
		and 	r0, r1			// 8th switch decides
		cmp	r0, r1
		bne	val2
		ld 	r0, [r3]
		and 	r0, #0x7f			// can use first 7 switch to input
		
		mv 	r1, r0				// r1 has the 2nd number
		st	r0, [r4]
		//bl 	current_val
		push r1
		mvt r1, #0x1

wait_inst:	ld 	r0, [r3]	
		and r0, r1			// 8th switch decides
		cmp	r0, r1
		beq	wait_inst

inst: 	ld 	r0, [r3]	
		and 	r0, r1			// 8th switch decides
		cmp 	r0, r1
		bne	inst
		pop r1

		ld	r0, [r3]			// instruction
		and 	r0, #0x1
		cmp 	r0, #0x1			// add
		beq 	add
			
		ld	r0, [r3]			// instruction
		and 	r0, #0x2
		cmp 	r0, #0x2			
		beq 	sub
			
		ld	r0, [r3]			// instruction
		and 	r0, #0x4
		cmp 	r0, #0x4			
		beq 	mul
			
		ld	r0, [r3]			// instruction
		and 	r0, #0x8
		cmp 	r0, #0x8			
		beq 	div

		ld	r0, [r3]			// instruction
		and 	r0, #0x10
		cmp 	r0, #0x10			
		beq 	tri

		ld	r0, [r3]			// instruction
		and 	r0, #0x20
		cmp 	r0, #0x20			
		beq 	square
		
		ld	r0, [r3]			// instruction
		and 	r0, #0x40
		cmp 	r0, #0x40			
		beq 	run_sum

		ld	r0, [r3]			// instruction
		and 	r0, #0x80
		cmp 	r0, #0x80			
		beq 	log

	
		b 	inst
	// r0 has the answer		
add: 	add 	r2, r1
		mv 	r0, r2
		st 	r0, [r4]
		b 	next
			
sub: 		
		sub	r2, r1
		mv 	r0, r2
		st 	r0, [r4]
		b 	next
			
mul:	mv 	r0, #0
		cmp r2, #0
		beq	zero
		cmp r1, #0
		beq	zero
mul2:		
		cmp r1, #0
		beq done_mul
		add r0, r2
		sub	r1, #1
		b 	mul2

done_mul:
		st 	r0, [r4]
		b 	next

log:	mv 		r1, #0
log2:	lsr 	r2, #1
		cmp 	r2, #0
		beq 	donelog
		add 	r1, #1
		b	log2
donelog:	mv 	r0, r1
		st 	r0, [r4]
		b	next
square: 	mv 	r1, r2
		b 	mul

run_sum:	mv 	r1, r3
		cmp 	r2, r3
		beq 	next
		mv 	r3, r2
sum2:	add 	r3, #1
		add 	r2, r3
		cmp 	r3, r1
		beq	done_sum 
		b 	sum2
done_sum:	mv 	r0, r2
		st 	r0, [r4]
		b	next
square: 	mv 	r3, r2
		b 	mul
run_sum:	mv 	r1, r3
		cmp 	r2, r3
		beq 	next
		mv 	r3, r2
sum2:		add 	r3, #1
		add 	r2, r3
		cmp 	r3, r1
		beq	done_sum 
		b 	sum2
done_sum:	mv 	r0, r2
		st 	r0, [r4]
		b 	next	
tri:		mv 	r1, #0
tri2:		
		cmp 	r3, #0
		beq 	done_tri
		add 	r1, r2
		sub	r3, #1
		b 	tri2

done_tri:	mv 	r0, r1
		lsr 	r0, #1
		st 	r0, [r4]
		b 	next		
zero:		mv 	r0, #0
		b 	next

tri:		mv 	r0, #0
tri2:		
		cmp 	r1, #0
		beq 	done_tri
		add 	r0, r2
		sub	r1, #1
		b 	tri2

done_tri:
		lsr 	r0, #1
		st 	r0, [r4]
		b 	next		
zero:	mv 	r0, #0
		b 	next


//subroutine to perform the integer division r2 / r4.
 //returns: quotient in r0, and remainder in r1 			
			
div: 		cmp 	r3, #0
		beq 	error
		mv 	r1, #0
cont: 		cmp	r2, r3
		bmi	div_end
		sub 	r2, r3
		add 	r1, #1
		b 	cont


div_end:    	mv	r0, r1     // quotient in r0 (remainder in r1)
		mv	r1, r2
            	st 	r0, [r4]
		b 	next

next: 	ld 	r1, [r3]
		mvt	r2, #0x1
		and 	r1, r2			// 8th switch decides
		cmp	r1, r2
		beq	next
		//b main

DISPLAY:
		bl DIV10	
		mvt 	r3, #HEX_ADDRESS		// HEX
		// 1st hex
		mv 	r4, #DATA
		add	r4, r0
		ld 	r4, [r4]
		st 	r4, [r3]			// display on hex
		mv 	r0, r1			// move remainder into r0 
		bl DIV10
	
		// 2nd hex
		add 	r3, #1
		mv	r4, #DATA
		add 	r4, r0
		ld 	r4, [r4]
		st 	r4, [r3]			// display on hex
		mv 	r0, r1			// move remainder into r0 
		bl DIV10

		// 3rd hex
		add 	r3, #1
		mv 	r4, #DATA
		add 	r4, r0
		ld 	r4, [r4]
		st 	r4, [r3]			// display on hex
		mv 	r0, r1			// move remainder into r0 
		bl DIV10
	
		// 4th hex
		add 	r3, #1 
		mv 	r4, #DATA
		add 	r4, r0
		ld 	r4, [r4]
		st 	r4, [r3]			// display on hex
		mv 	r0, r1			// move remainder into r0 
		bl DIV10
	
		// 5th hex
		add	r3, #1
		mv 	r4, #DATA
		add 	r4, r0
		ld 	r4, [r4]
		st 	r4, [r3]			// display on hex
		mv 	r0, r1			// move remainder into r0 
		bl DIV10
	
		// 6th hex
		add	r3, #1
		mv 	r4, #DATA
		add 	r4, r0
		ld 	r4, [r4]
		st 	r4, [r3]			// display on hex
		mv 	pc, #start

// subroutine DIV10
 //       This subroutine divides the number in r0 by 10
 //       The algorithm subtracts 10 from r0 until r0 < 10, and keeps count in r1
//       This subroutine also changes r2
//  input: r0 
//  returns: quotient Q in r1, remainder R in r0 

DIV10: push r2
		mv r1, #0		//init Q

DLOOP: 		mv r2, #9		// check if r0 is < 10 yet
		sub r2, r0
		bcc RETDIV		// if so, then return

INC: 		add r1, #1		// but if not, increment Q
		sub r0, #10		// r0 -=10
		b DLOOP

RETDIV: 
		pop r2
		mv pc, r6			// return results

DATA: 	
		.word	0b00111111		// 0
		.word	0b00000110		// 1
		.word 	0b01011011		// 2
		.word 	0b01001111		// 3
		.word	0b01100110		// 4
		.word	0b01101101		// 5
		.word 	0b01111101		// 6
		.word 	0b00000111		// 7
		.word 	0b01111111		// 8
		.word	0b01100111		// 9
