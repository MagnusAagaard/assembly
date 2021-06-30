;Extern Interrupt

.include "m32def.inc"

.org 0
	rjmp MAIN

.org 0x02
	rjmp ISR_EX0

.org 0x2A
MAIN:
;initialiser stacks
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16

;PORTC output
	ldi	R16, 0xFF
	out	DDRC, R16
	SBI	PORTD,2

;Enabgle interrupt på INT0
	ldi R20,(1<<INT0)
	out	GICR, R20
;Sætter til at trigger på rising-edge
	LDI	R20,0b00000011
	OUT	MCUCR,R20
	sei
;Out til PIN PC3 (PORTC.3)
	ldi	R21, 0b00001000
	ldi	R22, 0

LOOP:
	out PORTC, R22

	rjmp LOOP

DELAY:
	ldi	R19,4			;Delay på ca. 250*250*20 clock cycles (ved 1Mhz = 5 sek.)
DELAY3:
	ldi	R18,250
DELAY2:
	ldi	R17,250
DELAY1:	
	NOP				;Tom cycle
	DEC	R17			;Decrement
	BRNE	DELAY1			;Kører 250 gange (R17's værdi)
	dec	R18
	BRNE	DELAY2
	dec	R19
	BRNE	DELAY3
	ret

ISR_EX0:
	out	PORTC, R21
	call DELAY

	reti
