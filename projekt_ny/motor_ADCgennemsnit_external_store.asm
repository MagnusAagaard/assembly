.include "m32def.inc"

.def	counter=R20
.def	itterator=R18

.equ	sizeof_array = 255
array: .byte sizeof_array


.org	0
	JMP	RESET

.org	0x02
	JMP	ISR_EX0

.org	0x2A
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
	ldi	XL,LOW(array)
	ldi	XH,HIGH(array)
	ldi	itterator,sizeof_array
	SEI

;Extern interrupt
	LDI	R16,(1<<INT0)
	OUT	GICR,R16
	LDI	R16,0b00000011		;Sætter til at trigge på rising-edge
	OUT	MCUCR,R16

;PWM setup - initialiser timer2
	ldi	R16,0b01101001		;Ved at sætte TCCR2 registret i denne indstilling: fast PWM-mode, Non-invertered, no prescalar
	out	TCCR2,R16		;Farten/duty cyclen på motoren kan nu styres ved at ændre værdien i OCR2
	ldi	R16,170
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

LOOP:
	cpi	counter,1
	BREQ	CONVERT
	RJMP	LOOP

CONVERT:
	SBIS	ADCSR,ADIF		;Læs ADC når den er færdig med at konvertere
	RJMP	CONVERT
	SBI	ADCSR,ADIF		;Clear flag
	IN	R17,ADCL
	IN	R16,ADCH
CONVERT2:
	SBIS	ADCSR,ADIF
	RJMP	CONVERT2
	SBI	ADCSR,ADIF
	IN	R18,ADCL
	IN	R16,ADCH
	ADD	R17,R18			;Det er kun low vi interessere os for
	ROR	R17			;hvis der er kommet en carry fra additionen kommer den med her igen
	cpi	itterator,0		;hvis itterator ikke er 0 er der stadig plads i arrayet
	brne	STORE	
rjmp_send:
	CALL	SEND
	RJMP	LOOP

STORE:
	st	X+,R17			;Store R17 på plads x og inc
	dec	itterator
	rjmp	rjmp_send

SEND:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SEND
	OUT	UDR,R17
	LDI	R19,4
	CALL	DELAY
	RET

ISR_EX0:
	inc	counter
	RETI

DELAY:
	;ldi	R19,4			;Delay på ca. 4*250*250*4 clock cycles (1/16 sek. ved 16MHz)
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
