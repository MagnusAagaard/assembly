.include "m32def.inc"

.def	rigtigCounter=R20
.def	ACCdata=R21
.def	boolSving=R22
.def	antalSving=R23
.def	nyCounter=R14
.def	counter=R15

.org	0
	JMP	RESET

.org	0x02
	JMP	ISR_EX0

.ORG	URXCaddr
	RJMP	URXC_INT_HANDLER

.org	0x2A				;skip vektor tabel
;Initialiser programmet
RESET:
	LDI	R16,0
	mov	counter,R16		;Counter til 0
	mov	rigtigCounter,R16
	mov	nyCounter,R16

;PORTD setup
	ldi	R16,0b10000000		;Alternativt: SBI DDRD,7 (timer2). Port D pin 7 er PWM outputtet der går til motor-output
	out	DDRD,R16
	SBI	PORTD,2
	ldi	R16,0b10000000
	out	DDRC,R16

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

;PWM setup - initialiser timer2
	ldi	R16,0b01101001		;Ved at sætte TCCR2 registret i denne indstilling: fast PWM-mode, Non-invertered, no prescalar
	out	TCCR2,R16		;Farten/duty cyclen på motoren kan nu styres ved at ændre værdien i OCR2
	ldi	R16,0
	out	OCR2,R16

;Initialiser BT com
	ldi	R16,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)
	out	UCSRB,R16
	LDI	R16,(1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)
	out	UCSRC,R16
	ldi	R16,0x67
	out	UBRRL,R16

;ADC-setup
	LDI	R16,0
	OUT	DDRA,R16		;PORT A som input (ADC port)
	LDI	R16,0b11000000		;Vref 2.56V, højre justeret, PA0
	OUT	ADMUX,R16		
	LDI	R16,0b11100111		;ADC enable, ADC start conversion, ADC-auto-trigger, prescalar /128
	OUT	ADCSR,R16
	RJMP	LOOP

COUNTERINC:
	MOV	nyCounter,counter
	INC	rigtigCounter
	RJMP	LOOP

LOOP:
	CP	nyCounter,counter
	BRNE	COUNTERINC		;Hvis counter har ændret sig, så har vi passeret målstregen
	CPI	rigtigCounter,2
	BREQ	MAIN
	RJMP	LOOP
	
MAIN:
	CALL	CONVERT
	CALL	SEND
	CPI	antalSving,1
	BREQ	STADIGISVING
	CPI	boolSving,1
	BREQ	ERISVING
	CPI	boolSving,2
	BREQ	ERIETANDETSVING
	CPI	ACCdata,50
	BRLO	ETSVING
	CPI	ACCdata,110
	BRSH	ANDETSVING
	CLR	antalSving
	RJMP	LOOP

ETSVING:
	INC	antalSving
	LDI	boolSving,1
	RJMP	LOOP

ANDETSVING:
	INC	antalSving
	LDI	boolSving,2
	RJMP	LOOP

ERISVING:
	CPI	ACCdata,200
	BRSH	LOOP
	CPI	ACCdata,75		;ud af lave sving
	BRSH	UDAFSVING
	RJMP	LOOP

ERIETANDETSVING:
	CPI	ACCdata,70		;ud af høje sving
	BRLO	UDAFSVING
	RJMP	LOOP

UDAFSVING:
	CLR	boolSving
	CLR	antalSving
	CALL	SENDUDAFSVING
	RJMP	LOOP

STADIGISVING:
	CPI	boolSving,1
	BREQ	STADIGISVING1
	RJMP	STADIGISVING2

STADIGISVING1:
	CPI	ACCdata,200
	BRSH	SKIPNED
	CPI	ACCdata,45		;anden værdi for sving
	BRSH	CLEARANDRETURN
SKIPNED:
	INC	antalSving
	CALL	SENDSVING		;sæt hastighed/gem data
	RJMP	LOOP
STADIGISVING2:
	CPI	ACCdata,75
	BRLO	CLEARANDRETURN
	INC	antalSving
	CALL	SENDSVING		;sæt hastighed/gem data
	RJMP	LOOP

CLEARANDRETURN:
	CLR	antalSving
	CLR	boolSving
	RJMP	LOOP


CONVERT:
	SBIS	ADCSR,ADIF		;Læs ADC når den er færdig med at konvertere
	RJMP	CONVERT
	SBI	ADCSR,ADIF		;Clear flag
	IN	ACCdata,ADCL
	IN	R16,ADCH
	CALL	DELAY
	RET

SENDSVING:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SENDSVING
	LDI	R16,1
	;OUT	UDR,R16
	RET

SENDUDAFSVING:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SENDUDAFSVING
	LDI	R16,10
	;OUT	UDR,R16
	RET

SEND:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SEND
	OUT	UDR,ACCdata
	RET
	

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
	LDI	R16,10
	MOV	nyCounter,R16
	MOV	counter,R16
	LDI	R16,105
	OUT	OCR2,R16
	RETI

DELAY:
	ldi	R19,2		;Delay på ca. 4*200*200*2 clock cycles (1/50 sek. ved 16MHz)
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
