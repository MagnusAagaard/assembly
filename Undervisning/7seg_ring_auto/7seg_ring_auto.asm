.include "m32def.inc"

.equ	segNone=0b00000000
.equ	sega=0b10111111
.equ	segb=0b11110111
.equ	segc=0b11111011
.equ	segd=0b11111101
.equ	sege=0b11111110
.equ	segf=0b11101111

.def	reg_debounce=R21
.def	reg_delay1=R22
.def	reg_delay2=R23
.def	inputvalue=R25


;Initialiser programmet
RESET:

; PORTC setup
	ldi		R16, 0x00			; 
	out		DDRC, R16			; Set PORTC as input
	ldi		R16, 255			;
	out 		PORTC,R16 			; Enable pull-up on PORTC

; PORTB setup
	out 	DDRB,R16 			; PORTB = output
	ldi	R16,sega
	out	PORTB,R16			;A er on når den starter

;initialisér stack pointeren skal gøres for at call virker
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16

	rjmp	LOOP


;Start progamløkken
LOOP:
	CALL	READINPUT		;Læs inputtet fra pins
	CALL	DEBOUNCE		;Debounce for at undgå støj
	cpi	inputvalue,segNone	;Hvis ingen switches er flikket, skal displayet stoppe på nuværende værdi
	BREQ	STOP
	CALL	SWITCH			;Hvis en eller flere switches er flicket, skal den skifte
	rjmp	LOOP

STOP:
	rjmp	LOOP

DEBOUNCE:
	ldi	reg_debounce,250	;Debounce skaber et delay på ca. 1 ms.
	DELAY1:
	NOP				;Tom cycle
	DEC	reg_debounce		;Decrement
	BRNE	DELAY1			;Kører 250 gange (R17's værdi)
	RET

SWITCHDELAY:
	mov	reg_delay2,inputvalue	;Delay 3 tager inputvalue*1 ms.
	DELAY3:
	ldi	reg_delay1, 250		;Delay 2 tager 1 ms.
	DELAY2:
	NOP
	DEC	reg_delay1
	BRNE	DELAY2
	DEC	reg_delay2
	BRNE	DELAY3
	RET

READINPUT:
	in	inputvalue,PINC		;Indlæser input til register med navnet inputvalue
	com	inputvalue		;Når ingen switches er flicket er værdien 1111 1111, derfor skal det com
	RET				;for at undgå at den kører med et delay på 255 ms.

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
	RET

SWITCHA:
	ldi	R19,segb
	out	PORTB,R19
	CALL	SWITCHDELAY
	rjmp	LOOP
SWITCHB:
	ldi	R19,segc
	out	PORTB,R19
	CALL	SWITCHDELAY
	rjmp	LOOP
SWITCHC:
	ldi	R19,segd
	out	PORTB,R19
	CALL	SWITCHDELAY
	rjmp	LOOP
SWITCHD:
	ldi	R19,sege
	out	PORTB,R19
	CALL	SWITCHDELAY
	rjmp	LOOP
SWITCHE:
	ldi	R19,segf
	out	PORTB,R19
	CALL	SWITCHDELAY
	rjmp	LOOP
SWITCHF:
	ldi	R19,sega
	out	PORTB,R19
	CALL	SWITCHDELAY
	rjmp	LOOP
