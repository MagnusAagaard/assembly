.include "m32def.inc"

.def	counter=R20
.def	OUTreg=R21
.def	tidH=R25
.def	tidL=R24

.org	0
	JMP	RESET

.org	0x02
	JMP	ISR_EX0

.ORG	URXCaddr
	RJMP	URXC_INT_HANDLER

.org	0x2A				;skip vektor tabel
;Initialiser programmet
RESET:
	ldi	counter,0		;Counter til 0

;PORTD setup
	ldi	R16,0b10000000		;Alternativt: SBI DDRD,7 (timer2). Port D pin 7 er PWM outputtet der går til motor-output
	out	DDRD,R16

;initialiser stacks			;Skal bruges til CALL
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16
	SEI

;PWM setup - initialiser timer2
	ldi	R16,0b01101001		;Ved at sætte TCCR2 registret i denne indstilling: fast PWM-mode, invertered, no prescalar
	out	TCCR2,R16		;Farten/duty cyclen på motoren kan nu styres ved at ændre værdien i OCR2

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

SEND:
	CALL	SENDBLUE
	CPI	counter,11
	BREQ	STOPOGSEND
	RJMP	SEND

SENDBLUE:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SENDBLUE
	OUT	UDR,counter
	LDI	R19,1
	CALL	DELAY
	RET

STOPOGSEND:
	LDI	R16,0
	OUT	OCR2,R16
	RJMP	SEND

URXC_INT_HANDLER:			
	IN	R23,UDR
	CPI	R23,'G'
	BREQ	TEST
	CPI	R24,1
	BREQ	TEST2
	CPI	R24,2
	BREQ	HASTIGHED	
	RETI

TEST:
	LDI	R24,1
	RETI

TEST2:
	CPI	R23,'H'
	BREQ	TEST3
	CPI	R23,'J'
	BREQ	STOP
	RETI

TEST3:
	LDI	R24,2
	RETI

HASTIGHED:
	LDI	counter,10
	OUT	OCR2,R23
	CLR	R24
	RETI

STOP:
	LDI	R24,0
	OUT	OCR2,R24
	RETI

ISR_EX0:
	inc	counter
	RETI

DELAY:
	;ldi	R19,2		;Delay på ca. 4*250*250*4 clock cycles (1/16 sek. ved 16MHz)
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

;Grunden til det ikke virker når vi tjekker på forkert data er, at vi får så meget forkert data ind, at 9599 at byte'sne vi får ind er forkerte og kun 1 rigtig. Det gør at outputtet bliver domineret af det forkerte data
