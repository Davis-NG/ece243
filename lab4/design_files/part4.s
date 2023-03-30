               .equ      EDGE_TRIGGERED,    0x1
               .equ      LEVEL_SENSITIVE,   0x0
               .equ      CPU0,              0x01    // bit-mask; bit 0 represents cpu0
               .equ      ENABLE,            0x1

               .equ      KEY0,              0b0001
               .equ      KEY1,              0b0010
               .equ      KEY2,              0b0100
               .equ      KEY3,              0b1000

               .equ      IRQ_MODE,          0b10010
               .equ      SVC_MODE,          0b10011

               .equ      INT_ENABLE,        0b01000000
               .equ      INT_DISABLE,       0b11000000

/*********************************************************************************
 * Initialize the exception vector table
 ********************************************************************************/
                .section .vectors, "ax"

                B        _start             // reset vector
                .word    0                  // undefined instruction vector
                .word    0                  // software interrrupt vector
                .word    0                  // aborted prefetch vector
                .word    0                  // aborted data vector
                .word    0                  // unused vector
                B        IRQ_HANDLER        // IRQ interrupt vector
                .word    0                  // FIQ interrupt vector

/* ********************************************************************************
 * This program demonstrates use of interrupts with assembly code. The program 
 * responds to interrupts from a timer and the pushbutton KEYs in the FPGA.
 *
 * The interrupt service routine for the timer increments a counter that is shown
 * on the red lights LEDR by the main program. The counter can be stopped/run by 
 * pressing any of the KEYs.
 ********************************************************************************/
                .text
                .global  _start
_start:        
                /* Set up stack pointers for IRQ and SVC processor modes */
                MOV      R1, #0b11010010         // interrupts masked, MODE = IRQ
             	MSR      CPSR_c, R1              // change to IRQ mode
             	LDR      SP, =0x40000            // set IRQ stack pointe
				/* Change to SVC (supervisor) mode with interrupts disabled */
             	MOV      R1, #0b11010011         // interrupts masked, MODE = SVC
             	MSR      CPSR_c, R1              // change to supervisor mode
             	LDR      SP, =0x20000            // set SVC stack
				
                BL       CONFIG_GIC         // configure the ARM generic interrupt controller

                BL       CONFIG_PRIV_TIMER  // configure the timer
                BL       CONFIG_TIMER       // configure the FPGA interval timer
                BL       CONFIG_KEYS        // configure the pushbutton KEYs

                /* enable IRQ interrupts in the processor */
                MOV      R0, #0b01010011         // IRQ unmasked, MODE = SVC
            	MSR      CPSR_c, R0 

                LDR      R5, =0xFF200000    // LEDR base address
                LDR      R6, =0xFF200020    // HEX3-0 base address
LOOP:
                LDR      R3, COUNT          // global variable
                STR      R3, [R5]           // light up the red lights
                LDR      R4, HEX_code       // global variable
                STR      R4, [R6]           // show the time in format SS:DD

                B        LOOP
				
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

SEG7_CODE:  LDR     R1, =BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

/* Global variables */
                .global  COUNT
COUNT:          .word    0x0                // used by timer
                .global  RUN
RUN:            .word    0x1                // initial value to increment COUNT
                .global  TIME
TIME:           .word    0x0                // used for real-time clock
                .global  HEX_code
HEX_code:       .word    0x0

/* Configure the A9 Private Timer to create interrupts every 0.25 seconds */
CONFIG_PRIV_TIMER:
                LDR		R0,	=0xFFFEC600
				LDR 	R1,=50000000	   	// counter will be loaded with 50M -> 0.25 sec count up 
				STR 	R1, [R0]		   	// put it into the Load Register of the Counter
				MOV		R1, #0b111			// turn on A, E and I bits in counter control register
				STR 	R1, [R0,#8]			// store 0b111 into timer control reg 
                MOV     PC, LR
                   
/* Configure the FPGA interval timer to create interrupts at 0.01 second intervals */
CONFIG_TIMER:
                LDR		 R0, =0xFF202000
				LDR		 R1, =16960			// Timer runs on a 100 MHz clock -> load 1M to count 0.01 seconds 		
				STR		 R1, [R0, #0x8]		// Had to break 1M into two 16 bit values and load into high and low addresses
				MOV		 R1, #15
				STR		 R1, [R0, #0xC]
				MOV		 R1, #0b0111		// Turn on START, CONT, and ITO bits
				STR		 R1, [R0, #0x4]		// store in timer control reg
                MOV      PC, LR

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:
                LDR      R0, =0xFF200050         // pushbutton KEY base address
             	MOV      R1, #0xF                // set interrupt mask bits
             	STR      R1, [R0, #0x8]          // interrupt mask register is (base + 8) 
                MOV      PC, LR

/*--- IRQ ---------------------------------------------------------------------*/
IRQ_HANDLER:	PUSH     {R0-R12, LR}

				/* Read the ICCIAR in the CPU interface */
                LDR      R4, =0xFFFEC100
                LDR      R5, [R4, #0x0C]         // read the interrupt ID
				
CHECK_KEYS:		CMP      R5, #73
				BNE 	 CHECK_PRIV_TIMER
				BL		 KEY_ISR
				B 		 EXIT_IRQ

CHECK_PRIV_TIMER:	
				CMP		 R5, #29
				BNE		 CHECK_TIMER
				BL		 PRIV_TIMER_ISR
				B		 EXIT_IRQ
				
CHECK_TIMER:	CMP		 R5, #72
				BNE		 UNEXPECTED
				BL		 TIMER_ISR
				B		 EXIT_IRQ

UNEXPECTED:     BNE      UNEXPECTED              // if not recognized, stop here

EXIT_IRQ:		/* Write to the End of Interrupt Register (ICCEOIR) */
                STR      R5, [R4, #0x10]

				POP      {R0-R12, LR}
                SUBS     PC, LR, #4


/****************************************************************************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine toggles the RUN global variable.
 ***************************************************************************************/
                .global  KEY_ISR
KEY_ISR:        
                LDR		 R2, =0xFF200050
				LDR		 R1, [R2, #0xC]
				
				CMP		 R1, #1
				BEQ		 KEYZERO
				
				CMP 	 R1, #0b10
				BEQ		 KEYONE
				
				CMP		 R1, #0b100
				BEQ		 KEYTWO
				
				CMP		 R1, #0b1000
				BEQ		 KEYTHREE
				
KEYZERO:       	LDR		 R0, =RUN			  // toggle value of RUN
				LDR		 R3, [R0]
				EOR		 R3, #1
				STR		 R3, [R0]
				B		 EXIT_KEY

KEYONE:			LDR		 R3, =0xFFFEC600	  // Double the rate
				LDR		 R0, [R3]
				LSR		 R0, #1				  // Divide by 2
				STR		 R0, [R3]			  // load new value
				STR      R0, [R3, #0x4]		  // reset timer
				B		 EXIT_KEY
				
KEYTWO:			LDR		 R3, =0xFFFEC600	  // half the rate
				LDR		 R0, [R3]
				LSL		 R0, #1				  // multiple by 2
				STR		 R0, [R3]			  // load new value
				STR		 R0, [R3, #0x4]		  // reset timer
				B 		 EXIT_KEY
				
KEYTHREE:		LDR		 R3, =0xFF202000
				LDR		 R0, [R3, #0x4]
				EOR		 R0, #0b1100		  // flip stop and start bits to pause or unpause
				STR		 R0, [R3, #0x4]
				
EXIT_KEY:		STR		 R1, [R2, #0xC]		  // reset edgecapture reg 
                MOV      PC, LR

/******************************************************************************
 * A9 Private Timer interrupt service routine
 *                                                                          
 * This code toggles performs the operation COUNT = COUNT + RUN
 *****************************************************************************/
                .global  PRIV_TIMER_ISR
PRIV_TIMER_ISR:
                LDR		 R1, =RUN
				LDR		 R1, [R1]
				LDR		 R0, =COUNT
				LDR		 R2, [R0]
				ADD		 R1, R2
				STR		 R1, [R0]
				
				MOV		 R3, #0x1
				LDR		 R1, =0xFFFEC600
				STR		 R3, [R1, #0xC]
				
                MOV      PC, LR

/******************************************************************************
 * Interval timer interrupt service routine
 *                                                                          
 * This code performs the operation ++TIME, and produces HEX_code
 *****************************************************************************/
                .global  TIMER_ISR
TIMER_ISR:		PUSH	 {R4-R12, LR}

                LDR		 R3, =TIME
				LDRH	 R5, [R3]			// hundredths of a second
				LDRH	 R6, [R3, #2] 		// Seconds
				ADD		 R5, #1
				CMP		 R5, #100
				BLT		 DISPLAY
				MOV		 R5, #0
				ADD 	 R6, #1
				CMP		 R6, #60
				BLT		 DISPLAY
				MOV		 R6, #0
				
DISPLAY:		STRH 	 R5, [R3]			// update time
				STRH	 R6, [R3, #0x2]
				
				MOV      R0, R5          // display R5 on HEX1-0
            	BL       DIVIDE          // ones digit will be in R0; tens  digit in R1
				
            	MOV      R9, R1          // save the tens digit
            	BL       SEG7_CODE       
            	MOV      R4, R0          // save bit code
            	MOV      R0, R9          // retrieve the tens digit, get bit code
				
            	BL       SEG7_CODE       
            	LSL      R0, #8
            	ORR      R4, R0

            	//code for R6 (shown)
            	MOV      R0, R6          // display R6 on HEX3-2
            	BL       DIVIDE          // ones digit will be in R0; tens digit in R1
                                    
            	MOV      R9, R1          // save the tens digit
            	BL       SEG7_CODE
				LSL		 R0, #16
            	ORR      R4, R0          // save bit code
            	MOV      R0, R9          // retrieve the tens digit, get bit code
                                     	
            	BL       SEG7_CODE       
            	LSL      R0, #24
            	ORR      R4, R0
			 
				LDR		 R3, =HEX_code	 // update HEX_code
            	STR      R4, [R3]        // and store into memory
				
				
				LDR		 R3, =0xFF202000	// Reset TimeOut bit
				MOV		 R0, #0				 
				STR		 R0, [R3]
		
				
				POP		 {R4-R12, LR}
                MOV      PC, LR

/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                /* Enable A9 Private Timer interrupts */
                MOV      R0, #29
                MOV      R1, #CPU0
                BL       CONFIG_INTERRUPT
                
                /* Enable FPGA Timer interrupts */
                MOV      R0, #72
                MOV      R1, #CPU0
                BL       CONFIG_INTERRUPT

                /* Enable KEYs interrupts */
                MOV      R0, #73
                MOV      R1, #CPU0
                /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
                BL       CONFIG_INTERRUPT

                /* configure the GIC CPU interface */
                LDR      R0, =0xFFFEC100        // base address of CPU interface
                /* Set Interrupt Priority Mask Register (ICCPMR) */
                LDR      R1, =0xFFFF            // enable interrupts of all priorities levels
                STR      R1, [R0, #0x04]
                /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
                 * allows interrupts to be forwarded to the CPU(s) */
                MOV      R1, #1
                STR      R1, [R0]
    
                /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
                 * allows the distributor to forward interrupts to the CPU interface(s) */
                LDR      R0, =0xFFFED000
                STR      R1, [R0]    
    
                POP      {PC}
/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
                PUSH     {R4-R5, LR}
    
                /* Configure Interrupt Set-Enable Registers (ICDISERn). 
                 * reg_offset = (integer_div(N / 32) * 4
                 * value = 1 << (N mod 32) */
                LSR      R4, R0, #3               // calculate reg_offset
                BIC      R4, R4, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED100
                ADD      R4, R2, R4               // R4 = address of ICDISER
    
                AND      R2, R0, #0x1F            // N mod 32
                MOV      R5, #1                   // enable
                LSL      R2, R5, R2               // R2 = value

                /* now that we have the register address (R4) and value (R2), we need to set the
                 * correct bit in the GIC register */
                LDR      R3, [R4]                 // read current register value
                ORR      R3, R3, R2               // set the enable bit
                STR      R3, [R4]                 // store the new register value

                /* Configure Interrupt Processor Targets Register (ICDIPTRn)
                  * reg_offset = integer_div(N / 4) * 4
                  * index = N mod 4 */
                BIC      R4, R0, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED800
                ADD      R4, R2, R4               // R4 = word address of ICDIPTR
                AND      R2, R0, #0x3             // N mod 4
                ADD      R4, R2, R4               // R4 = byte address in ICDIPTR

                /* now that we have the register address (R4) and value (R2), write to (only)
                 * the appropriate byte */
                STRB     R1, [R4]
    
                POP      {R4-R5, PC}
                .end   

