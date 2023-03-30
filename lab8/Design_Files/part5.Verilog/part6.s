.define SW_ADDR 0x30
.define LED_ADDR 0x10

	mvt r4, #SW_ADDR		// switches
	mvt r5, #LED_ADDR		// leds
	mv  r2, #0			// counter

MAIN:	add r2, #1
	st r2, [r5]			// display on leds
	mv pc, #SWITCH		// load switches

SWITCH: 
	ld r0, [r4]
	mvt r3, #0x01
	add r3, #0xFF
	and r0, r3
	add r0, #1			// number of times counter will run
	mv pc, #COUNT			// start with 1 time when the switches value is 0

COUNT:	//mvt r1, #0xFC			// counter value
	mv r1, #0x80


LOOP:	sub r1, #1
	bne #LOOP			// countdown
	sub r0, #1			// decrement the number of times running the loop
	bne #COUNT			// loop until 0
	mv pc, #MAIN