.include "m32def.inc"

.def	tick=R17
.def	tick_5hz=R18
.def	tick_2hz=R19
.def	tick_1hz=R20

.equ	sega=0b10111111
.equ	segd=0b11111101
.equ	segg=0b11011111

.org	$0000
	RJMP	RESET

.org	0x014
	RJMP	TIM0_COMPA	;Timer0 compare match interrupt vector

;Initialiser programmet
RESET:

; PORTB setup
	LDI	R16,0xFF
	OUT	DDRB,R16			;PORTB = output
	OUT	PORTB,R16			;Sluk LED fra start (aktive lave)

;PWM setup - initialiser timer2
	ldi	R16,9
	out	OCR0,R16			;ved at loade 9 ind får vi 10 ticks = 10 ms
	ldi	R16,0b00001101			;Clear on compare, clck/1024 (1 kHz)
	out	TCCR0,R16			

	LDI	R16,(1<<OCIE0)			;Compare match interrupts
	OUT	TIMSK,R16
	SEI

;initialisér stack pointeren skal gøres for at call virker
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16

;Start progamløkken
LOOP:
	CPI	tick,1
	BRGE	toggle
	RJMP	LOOP

toggle:
	dec	tick
	CALL	hz_5
	CALL	hz_2
	CALL	hz_1
	rjmp	LOOP

hz_5:
	inc	tick_5hz
	CPI	tick_5hz,20
	BRGE	toggle_5hz
back5hz:
	RET

toggle_5hz:
	clr	tick_5hz
	in	R16,PINB
	ldi	R21,sega
	com	R21
	EOR	R16,R21
	OUT	PORTB,R16
	rjmp	back5hz
hz_2:
	inc	tick_2hz
	CPI	tick_2hz,50
	BRGE	toggle_2hz
back2hz:
	RET

toggle_2hz:
	clr	tick_2hz
	in	R16,PINB
	ldi	R21,segg
	com	R21
	EOR	R16,R21
	OUT	PORTB,R16
	rjmp	back2hz

hz_1:
	inc	tick_1hz
	CPI	tick_1hz,100
	BRGE	toggle_1hz
back1hz:
	RET

toggle_1hz:
	clr	tick_1hz
	in	R16,PINB
	ldi	R21,segd
	com	R21
	EOR	R16,R21
	OUT	PORTB,R16
	rjmp	back1hz

TIM0_COMPA:
	inc	tick
	RETI

