.include "m32def.inc"

.equ seg0=0b10100000
.equ seg1=0b11110011
.equ seg2=0b10010100
.equ seg3=0b10010001
.equ seg4=0b11000011
.equ seg5=0b10001001
.equ seg6=0b10001000
.equ seg7=0b10110011
.equ seg8=0b10000000
.equ segE=0b10001100

;Initialiser programmet
RESET:

; PORTC setup
	ldi		R16, 0x00			; 
	out		DDRC, R16			; Set PORTC as input
	ldi		R16, 255			;
	out 		PORTC,R16 			; Enable pull-up on PORTC

; PORTB setup
	out 	DDRB,R16 			; PORTB = output

	rjmp	LOOP


;Start progamløkken
LOOP:

	in	R16,PINC		;Indlæs PINC til R16
	cpi	R16,0b11111111		;Sammenligner R16 med den binære værdi for 0.
	breq	TURN0			;Hvis ovenstående er sand, hopper vi til TURN0
	cpi	R16,0b11111110		;Sammenligner R16 med den binære værdi for første pin
	breq	TURN1			;Hvis sand, hopper til TURN1
	cpi	R16,0b11111101		;Sammenligner R16 med den binære værdi for anden pin, osv...
	breq	TURN2
	cpi	R16,0b11111011
	breq	TURN3
	cpi	R16,0b11110111
	breq	TURN4
	cpi	R16,0b11101111
	breq	TURN5
	cpi	R16,0b11011111
	breq	TURN6
	cpi	R16,0b10111111
	breq	TURN7
	cpi	R16,0b01111111
	breq	TURN8			
	ldi	R16,segE		;Hvis ingen af ovenstående er sande, må mindst to pinne være switchet, derfor skrives der E.			
	out	PORTB, R16		;Vis det på displayet (port B)
	rjmp	LOOP

TURN0:
	ldi	R16,seg0		;R16 = seg0 (den binære værdi for at vise 0 på displayet)
	out	PORTB, R16		;Vis på displayet.
	rjmp	LOOP

TURN1:
	ldi	R16,seg1
	out	PORTB, R16
	rjmp	LOOP
TURN2:
	ldi	R16,seg2
	out	PORTB, R16
	rjmp	LOOP
TURN3:
	ldi	R16,seg3
	out	PORTB, R16
	rjmp	LOOP
TURN4:
	ldi	R16,seg4
	out	PORTB, R16
	rjmp	LOOP
TURN5:
	ldi	R16,seg5
	out	PORTB, R16
	rjmp	LOOP
TURN6:
	ldi	R16,seg6
	out	PORTB, R16
	rjmp	LOOP
TURN7:
	ldi	R16,seg7
	out	PORTB, R16
	rjmp	LOOP
TURN8:
	ldi	R16,seg8
	out	PORTB, R16
	rjmp	LOOP

