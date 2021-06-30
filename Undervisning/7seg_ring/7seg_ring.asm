.include "m32def.inc"

.equ sega=0b10111111
.equ segb=0b11110111
.equ segc=0b11111011
.equ segd=0b11111101
.equ sege=0b11111110
.equ segf=0b11101111


;Initialiser programmet
RESET:

; PORTC setup
	ldi		R16, 0x00			; 
	out		DDRC, R16			; Set PORTC as input
	ldi		R16, 255			;
	out 		PORTC,R16 			; Enable pull-up on PORTC

; PORTB setup
	out 	DDRB,R16 			; PORTB = output
	out	PORTB,R16			;Sluk alle til at starte med

	rjmp	LOOP


;Start progamløkken
LOOP:

	in	R16,PINC		;Indlæser input til R16

	ldi	R17,250			;Indlæser 250 til R17 til delayet
DELAY:
	NOP				;Tom cycle
	DEC	R17			;Decrement
	BRNE	DELAY			;Kører 250 gange (R17's værdi)

	in	R18,PINC		;Indlæser input til R18
	cp	R16,R18			;Sammenligner to registre
	brne	SWITCH			;Hvis en switch er ændret vil R16 og R18 være forskellige og jumper til switch

	rjmp	LOOP

SWITCH:
	in	R20,PINB		;Indlæser displayet, hvilken en der er tændt
	cpi	R20,sega		;Sammenligner displayet med værdien for første seg
	BREQ	SWITCHA			;Hvis første seg er tændt, går til switcha som skifter det til seg b osv..
	cpi	R20,segb
	BREQ	SWITCHB
	cpi	R20,segc
	BREQ	SWITCHC
	cpi	R20,segd
	BREQ	SWITCHD
	cpi	R20,sege
	BREQ	SWITCHE
	cpi	R20,segf
	BREQ	SWITCHF

	ldi	R19,sega
	out	PORTB,R19		;Hvis ingen er tændt, så tænder vi seg a
	rjmp	LOOP

SWITCHA:
	ldi	R19,segb
	out	PORTB,R19
	rjmp	LOOP
SWITCHB:
	ldi	R19,segc
	out	PORTB,R19
	rjmp	LOOP
SWITCHC:
	ldi	R19,segd
	out	PORTB,R19
	rjmp	LOOP
SWITCHD:
	ldi	R19,sege
	out	PORTB,R19
	rjmp	LOOP
SWITCHE:
	ldi	R19,segf
	out	PORTB,R19
	rjmp	LOOP
SWITCHF:
	ldi	R19,sega
	out	PORTB,R19
	rjmp	LOOP
