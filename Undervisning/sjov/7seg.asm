.include "m32def.inc"

;Initialiser programmet
RESET:

; PORTC setup
	ldi		R16, 0x00			; 
	out		DDRC, R16			; Set PORTC as input
	ldi		R16, 255			;
	out 	PORTC,R16 			; Enable pull-up on PORTC

; PORTB setup
	out 	DDRB,R16 			; PORTB = output

	rjmp	LOOP


;Start progamløkken
LOOP:
	ldi	R17,0xFF
	in	R16,PINC		;Indlæs PINC til R16
	sub	R17,R16			;Når alle pins er slukkede er værdien 255. Så snart en pin bliver tændt,
	brne	TURN			;falder værdien og derved hopper den til TURN så snart værdien er større end 1
	out	PORTB, R16		;Vis det på displayet (port B)
	rjmp	LOOP

TURN:
	ldi	R16,127
	out	PORTB, R16
	rjmp	LOOP
