.define SW_ADDRESS 0x30
.define HEX_ADDRESS 0x20
.define	LED_ADDRESS 0x10

	mvt r4, #SW_ADDRESS		// SWITCHES
	mvt r5, #HEX_ADDRESS		// HEX

	mv  r3, #0			// counter
	mv r6, pc			// return address for subroutine
	mv pc, #BLANK			// call subroutine to blank the HEX displays 

MAIN:	
	mvt r5, #LED_ADDRESS
	add r3, #1
	st r3, [r5]
	mv r0, r3
	mv r6, pc			// return address for subroutine
	b DIV10

DISPLAY:
	mvt r5, #HEX_ADDRESS		// HEX
	// 1st hex
	mv r4, #DATA
	add r4, r0
	ld r4, [r4]
	st r4, [r5]			// display on hex
	mv r0, r1			// move remainder into r0 
	mv r6, pc			// return address for subroutine
	b DIV10
	
	// 2nd hex
	add r5, #1
	mv r4, #DATA
	add r4, r0
	ld r4, [r4]
	st r4, [r5]			// display on hex
	mv r0, r1			// move remainder into r0 
	mv r6, pc			// return address for subroutine
	b DIV10

	// 3rd hex
	add r5, #1
	mv r4, #DATA
	add r4, r0
	ld r4, [r4]
	st r4, [r5]			// display on hex
	mv r0, r1			// move remainder into r0 
	mv r6, pc			// return address for subroutine
	b DIV10
	
	// 4th hex
	add r5, #1 
	mv r4, #DATA
	add r4, r0
	ld r4, [r4]
	st r4, [r5]			// display on hex
	mv r0, r1			// move remainder into r0 
	mv r6, pc			// return address for subroutine
	b DIV10
	
	// 5th hex
	add r5, #1
	mv r4, #DATA
	add r4, r0
	ld r4, [r4]
	st r4, [r5]			// display on hex
	mv r0, r1			// move remainder into r0 
	mv r6, pc			// return address for subroutine
	b DIV10
	
	// 6th hex
	add r5, #1
	mv r4, #DATA
	add r4, r0
	ld r4, [r4]
	st r4, [r5]			// display on hex
	//mv r0, r1			// move remainder into r0 
	//mv r6, pc			// return address for subroutine
	//b DIV10

	mv pc, #SWITCH		// load switches

SWITCH: 
	mvt r4, #SW_ADDRESS		// SWITCHES
	ld r5, [r4]			// read switches
	mvt r2, #0x01
	add r2, #0xFF
	and r5, r2
	add r5, #1			// number of times counter will run
	mv pc, #COUNT			// start with 1 time when the switches value is 0

COUNT:	//mvt r1, #0xFC			// counter value
	mv r1, #0x80


LOOP:	
	sub r1, #1
	bne #LOOP			// countdown
	sub r5, #1				// decrement the number of times running the loop
	bne #COUNT			// loop until 0
	mv pc, #MAIN

 // subroutine DIV10
 //       This subroutine divides the number in r0 by 10
 //       The algorithm subtracts 10 from r0 until r0 < 10, and keeps count in r1
//       This subroutine also changes r2
//  input: r0 
//  returns: quotient Q in r1, remainder R in r0 

DIV10: 
		mv r1, #0		//init Q

DLOOP: 		mv r2, #9		// check if r0 is < 10 yet
		sub r2, r0
		bpl RETDIV		// if so, then return

INC: 		add r1, #1		// but if not, increment Q
		sub r0, #10		// r0 -=10
		b DLOOP

RETDIV: 
		add r6, #1		// adjust the return address
		mv pc, r6			// return results


// Subroutine BLANK

BLANK:	
		mvt r4, #HEX_ADDRESS
		mv r1, #0b00111111
             	st     r1, [r4]              // send to HEX display
             	add    r4, #1                // point to next HEX display
             	st     r1, [r4]              // send to HEX display
            	add    r4, #1                // point to next HEX display
          	st     r1, [r4]              // send to HEX display
             	add    r4, #1                // point to next HEX display
             	st     r1, [r4]              // send to HEX display
            	add    r4, #1                // point to next HEX display
		st     r1, [r4]              // send to HEX display
             	add    r4, #1                // point to next HEX display
             	st     r1, [r4]              // send to HEX display
        
		add r6, #1
		mv pc, r6			// return from subroutine

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