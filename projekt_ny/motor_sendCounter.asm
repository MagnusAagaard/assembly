.include "m32def.inc"

.def	counter=R20
.def	nyCounter=R21
.def	rigtigCounter=R22

.org	0
	JMP	RESET

.org	0x02
	JMP	ISR_EX0

.ORG	URXCaddr
	RJMP	URXC_INT_HANDLER

.org	0x2A				;skip vektor tabel
;Initialiser programmet
RESET:
	LDI	rigtigCounter,0

;PORTD setup
	ldi	R16,0b10000000		;Alternativt: SBI DDRD,7 (timer2). Port D pin 7 er PWM outputtet der går til motor-output
	out	DDRD,R16

;initialiser stacks			;Skal bruges til CALL
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16
	SEI

;Extern interrupt
	LDI	R16,(1<<INT0)
	OUT	GICR,R16
	LDI	R16,0b00000011		;Sætter til at trigge på rising-edge
	OUT	MCUCR,R16

;Initialiser BT com
	ldi	R16,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)
	out	UCSRB,R16
	LDI	R16,(1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)
	out	UCSRC,R16
	ldi	R16,0x67
	out	UBRRL,R16

;PWM setup - initialiser timer2
	ldi	R16,0b01101001		;Ved at sætte TCCR2 registret i denne indstilling: fast PWM-mode, invertered, no prescalar
	out	TCCR2,R16		;Farten/duty cyclen på motoren kan nu styres ved at ændre værdien i OCR2
	RJMP	MAIN

COUNTERINC:
	MOV	nyCounter,counter
	INC	rigtigCounter
	RJMP	MAIN

MAIN:
	CP	nyCounter,counter
	BRNE	COUNTERINC
	MOV	nyCounter,counter
	CALL	COUNTERSEND
	RJMP	MAIN

STOPMOTOR:
	LDI	R16,0
	OUT	OCR2,R16
	RJMP	MAIN

COUNTERSEND:
	SBIS	UCSRA,UDRE
	RJMP	COUNTERSEND
	OUT	UDR,rigtigCounter
	CALL	DELAY
	RET

DELAY:
	ldi	R19,2		;Delay på ca. 4*250*250*4 clock cycles (1/16 sek. ved 16MHz)
DELAY3:
	ldi	R18,200
DELAY2:
	ldi	R17,200
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
	inc	counter
	RETI

URXC_INT_HANDLER:				
	IN	R16,UDR		
	CPI	R16,'0'
	BREQ	STOP
	CPI	R16,'1'
	BREQ	START
	RETI

STOP:
	LDI	R16,0
	OUT	OCR2,R16
	RETI
START:
	LDI	counter,10
	LDI	nyCounter,10
	LDI	R16,105
	OUT	OCR2,R16
	RETI
