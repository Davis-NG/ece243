.global _start
.equ  KEY_BASE, 0xFF200050
.equ  HEX_BASE, 0xFF200020
.equ  MPCORE_PRIV_TIMER, 0xFFFEC600 // base of private timer

_start: 	LDR		R12, =KEY_BASE
			LDR		R11, =HEX_BASE
			LDR		R10, =MPCORE_PRIV_TIMER
			MOV		R5, #0				// counter
			MOV 	R2, #1
			LDR 	R3,=50000000	   	// counter will be loaded with 50M -> 0.25 sec count up 
			STR 	R3, [R10]		   	// put it into the Load Register of the Counter
			MOV		R3, #0b011			// turn on A and E bits in counter control register
			STR 	R3, [R10,#8]		// store 0b11 into timer control reg
					
WAIT:		LDR 	R3,[R10,#0xC]	   	// get the full status register
			ANDS	R3, #0x1		   	// isolate bit 0
			BEQ  	WAIT		   		// wait till F bit is 1
		 
			STR  	R3,[R10,#0xC]	   	// arrive here only if r3 bit 0 = 1
                  		   				// write that 1 into 0xffec50C
			           					// to turn off F flag in status reg 
			LDR		R0, [R12, #0xC]
			ANDS	R0, #0xF
			BNE		PAUSE
			ADD		R5, #1
			CMP		R5, #100
			BLT		DISPLAY
			MOV		R5, #0
			B		DISPLAY
			
PAUSE:		MOV  	R3, R0			// turn off edge capture bit
			STR 	R3, [R12,#0xC]	
			MOV		R3, #0b010
			STR		R3, [R10, #8]	// turn off enable
LOOP:		LDR		R0, [R12, #0xC]
			ANDS	R0, #0xF
			BNE		RESUME
			B		LOOP
RESUME:		MOV  	R3, R0			// turn off edge capture bit
			STR 	R3, [R12,#0xC]
			MOV		R3, #0b011
			STR		R3, [R10, #8]	// turn on enable
			B		WAIT

/* Display R5 on HEX1-0 */
DISPLAY:    MOV     R0, R5          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0
			
			STR     R4, [R11]        // display the numbers from R5
			B		WAIT

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0 */			
DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, #10
            BLT    DIV_END
            SUB    R0, #10
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR
			
/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment