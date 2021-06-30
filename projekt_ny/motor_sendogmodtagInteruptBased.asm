.include "m32def.inc"

.CSEG
	RJMP	RESET
.ORG	URXCaddr
	RJMP	URXC_INT_HANDLER
.ORG	40

;Initialiser programmet
RESET:

;PORTD setup
	ldi	R16,0b10000000		;Alternativt: SBI DDRD,7 (timer2). Port D pin 7 er PWM outputtet der går til motor-output
	out	DDRD,R16

;initialiser stacks			;Skal bruges til CALL
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16

;PWM setup - initialiser timer2
	ldi	R16,0b01111001		;Ved at sætte TCCR2 registret i denne indstilling: fast PWM-mode, invertered, no prescalar
	out	TCCR2,R16		;Farten/duty cyclen på motoren kan nu styres ved at ændre værdien i OCR2

;Initialiser BT com
	ldi	R16,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)
	out	UCSRB,R16
	LDI	R16,(1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)
	out	UCSRC,R16
	ldi	R16,0x67
	out	UBRRL,R16

	LDI	R27,'K'
	SEI

LOOPMODTAG:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	LOOPMODTAG
	OUT	UDR,R27
	LDI	R27,'K'
	CALL	DELAY
	RJMP	LOOPMODTAG

URXC_INT_HANDLER:			;Forbliver i interuptet?? (Manglede at tømme UDR ved IN)	
	IN	R16,UDR		
	MOV	R27,R16			;Må ikke outte i interruptet, skaber problemer :)
	RETI

DELAY:
	ldi	R19,64			;Delay på ca. 250*250*20 clock cycles (ved 1Mhz = 5 sek.)
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

;Grunden til det ikke virker når vi tjekker på forkert data er, at vi får så meget forkert data ind, at 9599 at byte'sne vi får ind er forkerte og kun 1 rigtig. Det gør at outputtet bliver domineret af det forkerte data
