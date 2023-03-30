.global _start
.equ  KEY_BASE, 0xFF200050
.equ  HEX_BASE, 0xFF200020

_start: 	LDR		R12, =KEY_BASE
			LDR		R11, =HEX_BASE
			MOV		R0, #0			// displayed number
			
POLLON:		LDR		R1, [R12]
			
			CMP		R1, #0			// no key pressed
			BEQ		POLLON
			
			CMP		R1, #1			// key zero pressed
			BEQ		ZERO
			
			CMP		R1, #2			// key one pressed
			BEQ		INCRE
			
			
			CMP		R1, #4			// key two pressed
			BEQ		DECRE
			
			
			CMP		R1, #8			// key three pressed
			BEQ 	CLEAR
			
			B		POLLON

// wait until button is released
POLLOFF:	LDR		R1, [R12]
			CMP		R1, #0
			MOVEQ	PC, LR
			B		POLLOFF


ZERO:		BL		POLLOFF
			MOV		R0, #0
			B		DISPLAY
			
INCRE:		BL		POLLOFF
			LDR		R2, [R11]
			CMP		R2, #0
			BEQ		ZERO
			ADD		R0, #1
			CMP		R0, #10
			BLT		DISPLAY
			MOV		R0, #9
			B		DISPLAY
			
DECRE:		BL		POLLOFF
			LDR		R2, [R11]
			CMP		R2, #0
			BEQ		ZERO
			SUB		R0, #1
			CMP		R0, #0
			BGE		DISPLAY
			MOV		R0, #0
			B		DISPLAY
			
CLEAR:		BL		POLLOFF
			LDR		R2, [R11]
			CMP		R2, #0
			BEQ		ZERO
			MOV		R3, #0
			STR		R3, [R11]
			B		POLLON
			

DISPLAY:	MOV		R3, R0
			BL      SEG7_CODE 
            STR		R3, [R11]
			B		POLLON

			
/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */
SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R3         // index into the BIT_CODES "array"
            LDRB    R3, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR 
		

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment