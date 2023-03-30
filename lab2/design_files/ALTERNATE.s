/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:   MOV	  SP, #0x20000                          
          MOV     R4, #TEST_NUM   // load the data word ...
          LDR     R1, [R4]        // into R1
		  LDR	  R8, =0xaaaaaaaa
		  BL	  ALTERNATE
		  B		  END
		  
ALTERNATE:PUSH	  {LR}
		  EOR	  R1, R8		  // if alternating 1's and 0's are alligned with 0xaaaaaaaa they will become oned
		  BL	  ONES			  // so count longest consective 1's 
		  MOV	  R3, R0
		  LDR	  R1, [R4]
		  EOR	  R1, R8		  // if alternating 1's and 0's are alligned with 0xaaaaaaaa they will become zeroed
		  BL 	  ZEROS			  // so count longest consective of 0's
		  CMP	  R3, R0
		  MOVGT	  R0, R3		  // depending on which is larger, that is the number of alternating 1’s and 0’s
		  CMP	  R0, #1
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

END:      B       END             

TEST_NUM: .word   0b11101111

          .end                            