/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:   
		  MOV	  R5, #0		  // R5 will hold the largest string of 1's so far
          MOV     R3, #TEST_NUM   // load the data word ...
LOOP:	  LDR     R1, [R3]        // into R1
		  CMP	  R1, #0		  // check if at the end of list
		  BEQ 	  END
		  MOV     R0, #0          // R0 will hold the result of ones subroutine
		  BL	  ONES
		  ADD	  R3, #4		  // get the address of next word
		  CMP     R0, R5 	      // check if larger string of 1's is found
		  MOVGT	  R5, R0 		  // if larger update R5
		  B 	  LOOP

END:      B       END 
          
ONES:     CMP     R1, #0          // loop until the data contains no more 1's
          MOVEQ   PC, LR             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       ONES         

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
		  .word   0x00000000	  // end of list

          .end                            
