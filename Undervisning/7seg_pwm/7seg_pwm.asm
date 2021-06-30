.include "m32def.inc"

.org	$0000
	RJMP	RESET

.org	0x014
	RJMP	TIM0_COMPA	;Timer0 compare match interrupt vector

.org	0x016
	RJMP	TIM0_OVERF	;Timer0 overflow interrupt vector

;Initialiser programmet
RESET:

; PORTB setup
	LDI	R16,0xFF
	OUT	DDRB,R16			;PORTB = output
	OUT	PORTB,R16			;Sluk LED fra start (aktive lave)

;PWM setup - initialiser timer2
	ldi	R16,0b01111001			;Fast PWM-mode, invertered, no prescalar (4 kHz)
	out	TCCR0,R16			;Duty cyclen på LED kan nu styres ved at ændre værdien i OCR0

	LDI	R16,(1<<OCIE0)|(1<<TOIE0)	;Enable Overflow og Compare match interrupts
	OUT	TIMSK,R16
	SEI

;initialisér stack pointeren skal gøres for at call virker
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16

;ADC-setup
	LDI	R16,0
	OUT	DDRA,R16
	LDI	R16,0b11100000
	OUT	ADMUX,R16
	LDI	R16,0b11100100
	OUT	ADCSR,R16

;Start progamløkken
LOOP:
	SBIS	ADCSR,ADIF		;Løkken bruges til at bestemme OCR0 compare værdien
	RJMP	LOOP
	SBI	ADCSR,ADIF
	IN	R16,ADCL
	IN	R16,ADCH
	OUT	OCR0,R16
	RJMP	LOOP

TIM0_COMPA:
	LDI	R16,0xFF		;Hvis timer0 compare match: Sluk LED (aktive lave)
	OUT	PORTB,R16
	RETI

TIM0_OVERF:
	LDI	R16,0b10000000		;Hvis timer0 overflow: Tænd LED (aktive lave)
	OUT	PORTB,R16
	RETI


