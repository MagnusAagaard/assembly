; ***********************************
; * Written for MIC ATmega32A board
; * Output the value of switches 0-3
; * as hex value on 7-segment display
; ***********************************
.include "m32def.inc"

.org	0
	rjmp	init

.org	0x60
digits:
	.db 	0b10100000,0b11110011	; 0 and 1
	.db 	0b10010100,0b10010001	; 2 and 3
	.db 	0b11000011,0b10001001	; 4 and 5
	.db 	0b10001000,0b10110011	; 6 and 7
	.db 	0b10000000,0b10000011	; 8 and 9
	.db 	0b10000010,0b11001000	; A and b
	.db 	0b10101100,0b11010000	; C and d
	.db 	0b10001100,0b10001110	; E and F
	.db 	0, 0			; zeros in case of overflow

init:
	ldi 	R16,HIGH(RAMEND) 	
	out 	SPH,R16 			
	ldi 	R16,LOW(RAMEND)		
	out 	SPL,R16 			
	
	; PORTC setup
	ldi		R16, 0x00			; 
	out		DDRC, R16			; Set PORTC as input
	ldi		R16, 255			;
	out 	PORTC,R16 			; Enable pull-up on PORTC
			
	; PORTB setup
	out 	DDRB,R16 			; PORTB = output
	ldi		R16, 0x55
	out		PORTB, R16			; Turn LEDS off

	rjmp	main

; ***********************************
; * Main program
; ***********************************
main:
	in	R16,PINC 				; read port C
	lsr	R16					;shifter bits til højre
	lsr	R16
	com	R16						; take complement to accomodate active low
	ldi 	R17, 0x0F			; load mask
	and 	R16, R17			; mask out high nibble

	ldi	ZH,high(digits<<1)		; make high byte of Z point at address of digit 0
	ldi 	ZL,low(digits<<1)	; make low byte of Z point at address of digit 0

	add	ZL, R16					; Offset Z to point at the digit corresponding to switches
	ldi	R16, 0					; Load zero
	adc	ZH, R16					; Add high byte of Z with carry

	lpm	R16, Z					; Load the data that Z points to
	out	PORTB, R16				; Display data on port
	rjmp	main				; Loop forever


