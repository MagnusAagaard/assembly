.include "m32def.inc"

.def	counter=R20

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
	
MAIN:
	CPI	counter,2
	BREQ	LOOP
	CALL	COUNTERSEND
	RJMP	MAIN

COUNTERSEND:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	COUNTERSEND
	OUT	UDR,counter
	LDI	R19,4
	CALL	DELAY
	RET

LOOP:
	SBIS	ADCSR,ADIF		;Læs ADC når den er færdig med at konvertere
	RJMP	LOOP
	SBI	ADCSR,ADIF		;Clear flag
	IN	R17,ADCL
	IN	R16,ADCH
	CPI	R17,40
	BRLO	DIODE
	CPI	R17,80
	BRSH	DIODE
	LDI	R16,0
	OUT	PORTC,R16
RETH:	CALL	SEND
	RJMP	MAIN

SEND:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SEND
	OUT	UDR,R17
	LDI	R19,4
	CALL	DELAY
	RET

STOPACC:
	LDI	R16,0
	OUT	OCR2,R16
	LDI	R19,50
	CALL	DELAY
	LDI	R16,75
	OUT	OCR2,R16
	RJMP	RETH

DIODE:
	LDI	R16,0b10000000
	OUT	PORTC,R16
	RJMP	RETH
	

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
	CLR	counter
	LDI	R16,75
	OUT	OCR2,R16
	RETI

;ISR_EX0:
;	ldi	R17,0
;	out	OCR2,R17
;	call	DELAY
;	ldi	R17,70
;	out	OCR2,R17
;	RETI

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
