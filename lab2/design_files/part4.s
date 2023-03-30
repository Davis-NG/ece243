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
			
/* code for Part III (shown) */
		  .text                   // executable code follows
          .global _start   
_start:   
		  MOV	  R5, #0		  // R5 will hold the largest string of 1's
		  MOV	  R6, #0		  // R6 will hold the largest string of 0's
		  MOV	  R7, #0		  // R7 will hold the largest string of alternating 1’s and 0’s	
		  LDR	  R8, =0xaaaaaaaa // const to find to help find string of alternating 1’s and 0’s (0x5555555 can also work)
          MOV     R4, #TEST_NUM   // load the data word ...
LOOP:	  LDR     R1, [R4]        // into R1
		  CMP	  R1, #0		  // check if at the end of list
		  BEQ 	  DISPLAY
		  BL	  ONES
		  CMP     R0, R5 	      // check if larger string of 1's is found
		  MOVGT	  R5, R0 		  // if larger update R5
		  LDR	  R1, [R4]		  // load same data word
		  BL	  ZEROS
		  CMP     R0, R6 	      // check if larger string of 0's is found
		  MOVGT	  R6, R0		  // if larger update R6
		  LDR	  R1, [R4]		  // load same data word
		  BL	  ALTERNATE
		  CMP     R0, R7 	      // check if larger string of alternating 1’s and 0’s is found
		  MOVGT	  R7, R0 		  // if larger update R7
		  ADD	  R4, #4		  // get the address of next word
		  B 	  LOOP

END:      B       END 
          
ALTERNATE:PUSH	  {LR}
		  EOR	  R1, R8		  // if alternating 1's and 0's are alligned with 0xaaaaaaaa they will become oned
		  BL	  ONES			  // so count longest consective 1's 
		  MOV	  R3, R0
		  LDR	  R1, [R4]
		  EOR	  R1, R8		  // if alternating 1's and 0's are alligned with 0xaaaaaaaa they will become zeroed
		  BL 	  ZEROS			  // so count longest consective of 0's
		  CMP	  R3, R0
		  MOVGT	  R0, R3		  // depending on which is larger, that is the number of alternating 1’s and 0’s
		  CMP	  R0, #1		  // corner case
		  MOVEQ   R0, #0
		  POP	  {LR}
          MOV	  PC, LR
		  
ZEROS:    PUSH 	  {LR}
		  MVN	  R1, R1		  // invert
		  BL	  ONES			  // pass through the ones subroutine
		  POP	  {LR}
		  MOV	  PC, LR

ONES:     MOV     R0, #0          // R0 will hold the result
LOOP1:	  CMP     R1, #0          // loop until the data contains no more 1's
          MOVEQ   PC, LR             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       LOOP1

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0
            MOV     R0, R5          // display R5 on HEX1-0
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

            //code for R6 (not shown)
            MOV     R0, R6          // display R6 on HEX3-2
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE
			LSL		R0, #16
            ORR     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #24
            ORR     R4, R0
			
            STR     R4, [R8]        // display the numbers from R6 and R5
            LDR     R8, =0xFF200030 // base address of HEX5-HEX4
            
            //code for R7 (shown)
            MOV     R0, R7          // display R7 on HEX5-4
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
            STR     R4, [R8]        // display the number from R7
			B		END

TEST_NUM: .word   0x103fff0f 
		  .word   0x103fe00f
		  .word	  0xfffffffe
		  .word   0xffffffff
		  .word   0b1010
		  .word   0xefffffff
		  .word   0b1111100011111
		  .word   0xffabe232
		  .word   0x1
		  .word	  0x00001000
		  .word	  0x11101111
		  .word	  0b11101111
		  .word	  0xaaaaaaaa
		  .word   0x00000000	  // end of list

          .end                            