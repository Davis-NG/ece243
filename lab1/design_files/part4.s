/* Program that converts a binary number to decimal */
           
           .text               // executable code follows
           .global _start
_start:
            MOV    R4, #N
            MOV    R5, #Digits  // R5 points to the decimal digits storage location
            LDR    R4, [R4]     // R4 holds N
            MOV    R0, R4       // parameter for DIVIDE goes in R0
			MOV	   R6, #0		// R6 holds the place values: 0 for ones, 1 for tens, etc
LOOP:		MOV	   R1, #10
            BL     DIVIDE		// First time divide is called R0 will hold the ones digit
			STRB   R0, [R5, R6] // Second time - R0 will hold the tens digit
			ADD    R6, #1		// So increment R6 after storing
			CMP	   R1, #0		// If quotient is 0 we are done converting
			BEQ	   END
			MOV	   R0, R1		// Otherwise divide the quotient by ten again
			B 	   LOOP
END:        B      END

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0 */
DIVIDE:     MOV    R2, #0
CONT:       CMP    R0, R1
            BLT    DIV_END
            SUB    R0, R1
            ADD    R2, #1
            B      CONT
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR

N:          .word  6969         // the decimal number to be converted
Digits:     .space 4          // storage space for the decimal digits

            .end
