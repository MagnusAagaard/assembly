.include "m32def.inc"

.equ	segNone=0b00000000
.equ	sega=0b10111111
.equ	segb=0b11110111
.equ	segc=0b11111011
.equ	segd=0b11111101
.equ	sege=0b11111110
.equ	segf=0b11101111

.equ	tal1=34
.equ	tal2=95
.equ	tal3=76
.equ	tal4=18
.equ	tal5=22
.equ	mul_tal=26

.def	mul_reg=R20
.def	tal1H=R19
.def	tal1L=R18
.def	tal2H=R17
.def	tal2L=R16


;Initialiser programmet
RESET:

; PORTB setup
	ldi	R16,0xFF
	out 	DDRB,R16 			; PORTB = output

; PORTD setup
	ldi	R16,0b10111011
	out	DDRD,R16			;PORTD pin 2 og 6 = input
	out	PORTD,R16

;initialisér stack pointeren skal gøres for at call virker
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16


;Start progamløkken
	CALL	SUMQ7			;Finder summen
	CALL	MULQ14			;Dividerer
LOOP:	CALL	PRINT_DIODE		;Evig loop til at printe til dioden
	rjmp	LOOP

SUMQ7:					;Lægger alle tal sammen i tal1H og tal1L (R18:R19)
	ldi	tal1H,HIGH(tal1)
	ldi	tal1L,LOW(tal1)
	ldi	tal2H,HIGH(tal2)
	ldi	tal2L,LOW(tal2)

	add	tal1L,tal2L
	adc	tal1H,tal2H

	ldi	tal2H,HIGH(tal3)
	ldi	tal2L,LOW(tal3)
	add	tal1L,tal2L
	adc	tal1H,tal2H

	ldi	tal2H,HIGH(tal4)
	ldi	tal2L,LOW(tal4)
	add	tal1L,tal2L
	adc	tal1H,tal2H

	ldi	tal2H,HIGH(tal5)
	ldi	tal2L,LOW(tal5)
	add	tal1L,tal2L
	adc	tal1H,tal2H

	RET

MULQ14:
	ldi	mul_reg,mul_tal
	mul	tal1L,mul_reg		;bliver gemt i R0:R1
	movw	R16,R0			;rykker R0:R1 til R16:R17
	RET

PRINT_DIODE:
	in	R25,PIND		;Læser inputtet fra port D (knapperne)
	com	R25			;Inputtet complementeres for vores skyld
	cpi	R25,0			;Hvis ingen knapper er tændt, er inputtet 0xFF, com = 0
	BREQ	SLUK_DIODE
	cpi	R25,0b01000000		;Hvis knap 1 (S11, PD2) aktiveres, skal MSB af resultatet vises
	BREQ	DIODE1
	cpi	R25,0b00000100		;Hvis knap 2 (S10, PD6) aktiveres, skal LSB af resultatet vises
	BREQ	DIODE2

	RET

SLUK_DIODE:
	ldi	R25,0xFF
	out	PORTB,R25
	RET

DIODE1:
	out	PORTB,R17
	RET

DIODE2:
	out	PORTB,R16
	RET	
	
