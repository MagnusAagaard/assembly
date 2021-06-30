.include "m32def.inc"

.def	counter=R20
.def	ACCdata=R21
.def	OUTreg=R22

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
	SBI	PORTD,2
	ldi	R16,0b10000000
	out	DDRC,R16

;initialiser stacks			;Skal bruges til CALL
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16
	ldi	XL,LOW(0x140)
	ldi	XH,HIGH(0x140)
	ldi	YL,LOW(0x140)
	ldi	YH,HIGH(0x140)
	SEI

;Extern interrupt
	LDI	R16,(1<<INT0)
	OUT	GICR,R16
	LDI	R16,0b00000011		;Sætter til at trigge på rising-edge
	OUT	MCUCR,R16

;PWM setup - initialiser timer2
	ldi	R16,0b01101001		;Ved at sætte TCCR2 registret i denne indstilling: fast PWM-mode, Non-invertered, no prescalar
	out	TCCR2,R16		;Farten/duty cyclen på motoren kan nu styres ved at ændre værdien i OCR2
	;ldi	R16,0
	;out	OCR2,R16

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

LOOP:
	CALL	SEND
	cpi	counter,11
	BREQ	CONVERT
	cpi	counter,12
	BREQ	OPTIMER
	cpi	counter,13
	BRSH	NULSTIL
	RJMP	LOOP

CONVERT:
	SBIS	ADCSR,ADIF		;Læs ADC når den er færdig med at konvertere
	RJMP	CONVERT
	SBI	ADCSR,ADIF		;Clear flag
	IN	ACCdata,ADCL
	IN	R16,ADCH
	ST	X+,ACCdata
	LDI	R19,1
	CALL	DELAY
	RJMP	LOOP

OPTIMER:
	CALL	SEND
	LD	ACCdata,Y+
	CPI	ACCdata,40
	BRLO	SVING
	CPI	ACCdata,80
	BRSH	SVING
	CALL	LIGEUD
	RJMP	LOOP

NULSTIL:
	ldi	counter,11
	ldi	R16,75
	out	OCR2,R16
	RJMP	LOOP

SVING:
	LDI	R16,40
	OUT	OCR2,R16
	LDI	R19,1
	CALL	DELAY
	RJMP	LOOP

LIGEUD:
	LDI	R16,90
	OUT	OCR2,R16
	LDI	R19,1
	CALL	DELAY
	RET

SEND:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SEND
	LD	OUTreg,Y
	OUT	UDR,counter
	;LDI	R19,1
	;CALL	DELAY
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
	CPI	R16,'2'
	BREQ	COUNTER11
	CPI	R16,'3'
	BREQ	COUNTER12
	RETI

COUNTER11:
	LDI	counter,11
	RETI

COUNTER12:
	LDI	counter,12
	RETI

STOP:
	LDI	R16,0
	OUT	OCR2,R16
	RETI
START:
	LDI	counter,10
	LDI	R16,75
	OUT	OCR2,R16
	RETI

DELAY:
	;ldi	R19,20		;Delay på ca. 4*250*250*4 clock cycles (1/16 sek. ved 16MHz)
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
