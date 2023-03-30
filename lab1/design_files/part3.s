/* Program that finds the largest number in a list of integers	*/
            
            .text                   // executable code follows
            .global _start                  
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R0, [R4, #4]    // R0 holds the number of elements in the list
            MOV     R1, #NUMBERS    // R1 points to the start of the list
            BL      LARGE           
            STR     R0, [R4]        // R0 holds the subroutine return value

END:        B       END             

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the list
 *             R1 has the address of the start of the list
 * Returns: R0 returns the largest item in the list */
LARGE:      LDR R2, [R1]	// R2 will hold the largest number so far
LOOP:		SUBS R0, #1		// decrement loop counter
			BEQ RETURN		// if decrement loop counter is zero, 'return' from sub routine 
			ADD R1, #4
			LDR R3, [R1]	// get next number in list
			CMP R2, R3		// check if larger number is found
			BGE LOOP
			MOV R2, R3		// if larger, update r2
			B LOOP
RETURN:		MOV R0, R2		// R0 will return with largest number
			MOV PC, LR		// return from subroutine

RESULT:     .word   0           
N:          .word   7           // number of entries in the list
NUMBERS:    .word   4, 5, 3, 6  // the data
            .word   1, 8, 2                 

            .end                            
