.include "m32def.inc"

.def	counter=R20
.def	antalLigeUd=R6
.def	antalSving=R7

.org	0
	JMP	RESET

.org	0x02
	JMP	ISR_EX0

;Initialiser programmet
RESET:
	ldi	counter,0		;Counter til 0
	LDI	R16,80
	MOV	R1,R16
	MOV	R2,R16
	MOV	R3,R16
	MOV	R4,R16
	MOV	R5,R16

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
	ldi	R16,85
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

;Extern interrupt
	LDI	R16,(1<<INT0)
	OUT	GICR,R16
	LDI	R16,0b00000011		;Sætter til at trigge på rising-edge
	OUT	MCUCR,R16

MAIN:
	;CALL	COUNTERSEND
	cpi	counter,3
	BREQ	CONVERT
	RJMP	MAIN

CONVERT:
	SBIS	ADCSR,ADIF		;Læs ADC når den er færdig med at konvertere
	RJMP	CONVERT
	SBI	ADCSR,ADIF		;Clear flag
	IN	R17,ADCL
	IN	R16,ADCH
	MOV	R1,R17
	CALL	TJEKDATA
	CALL	SEND
	RJMP	MAIN

SEND:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SEND
	OUT	UDR,R17
	LDI	R19,2
	CALL	DELAY
	RET

TJEKDATA:
	LDI	R16,95
	LDI	R18,50
	CALL	TJEKDATA1
	CALL	TJEKDATA2
	CALL	TJEKDATA3
	CALL	TJEKDATA4
	CALL	TJEKDATA5
	LDI	R16,2
	CP	antalSving,R16
	BRSH	GEMSVING
	LDI	R17,1			;Gem dataen her, her sender vi det bare for test
RETNH:	CALL	FLYTDATA
	RET

GEMSVING:
	LDI	R17,10			;Gem dataen her, her sender vi det bare for test
	RJMP	RETNH

FLYTDATA:
	MOV	R5,R4
	MOV	R4,R3
	MOV	R3,R2
	MOV	R2,R1
	LDI	R16,0
	MOV	antalSving,R16
	MOV	antalLigeUd,R16
	RET

TJEKDATA1:
	CP	R1,R16
	BRSH	SVING
	CP	R1,R18
	BRLO	SVING
	INC	antalLigeUd
	RET

TJEKDATA2:
	CP	R2,R16
	BRSH	SVING
	CP	R2,R18
	BRLO	SVING
	INC	antalLigeUd
	RET

TJEKDATA3:
	CP	R3,R16
	BRSH	SVING
	CP	R3,R18
	BRLO	SVING
	INC	antalLigeUd
	RET

TJEKDATA4:
	CP	R4,R16
	BRSH	SVING
	CP	R4,R18
	BRLO	SVING
	INC	antalLigeUd
	RET

TJEKDATA5:
	CP	R5,R16
	BRSH	SVING
	CP	R5,R18
	BRLO	SVING
	INC	antalLigeUd
	RET
	

SVING:
	INC	antalSving
	RET


COUNTERSEND:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	COUNTERSEND
	OUT	UDR,counter
	LDI	R19,2
	CALL	DELAY
	RET

ISR_EX0:
	inc	counter
	RETI

DELAY:
	;ldi	R19,2			;Delay på ca. 4*200*200*2 clock cycles (1/50 sek. ved 16MHz)
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
