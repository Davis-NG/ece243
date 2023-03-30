/* Program that finds the largest number in a list of integers	*/
            
            .text                   // executable code follows
            .global _start                  
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R2, [R4, #4]    // R2 holds the number of elements in the list
            MOV     R3, #NUMBERS    // R3 points to the start of the list
			LDR 	R0, [R3]		// R0 holds the largest number rn
            BL      LARGE           
			STR     R0, [R4]        // R0 holds the subroutine return value

END:        B       END             

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the list
 *             R1 has the address of the start of the list
 * Returns: R0 returns the largest item in the list */
LARGE:      
			SUBS	R2, #1 		// decrement counter
			BEQ	FINAL			// branch to final if R2 is 0
								// if not 0, continue 
			ADD		R3, #4		// update the address of R3
			LDR		R1, [R3]	
			CMP		R0, R1
			BGE		LARGE
			MOV		R0, R1
			B		LARGE

FINAL:
			MOV		PC, LR		// store number in R0
			


RESULT:     .word   0           
N:          .word   7           // number of entries in the list
NUMBERS:    .word   4, 19, 3, 6  // the data
            .word   1, 8, 24                 

            .end                            
