/* Program that counts consecutive 1's */

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
		  BEQ 	  END
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
		  .word   0x00000000	  // end of list

          .end                            
