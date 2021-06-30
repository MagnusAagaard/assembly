.include "m32def.inc"

.equ	MOSI = 5
.equ	SCK = 7
.equ	SS = 4

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
	out	TCCR2,R16		;Farten/duty cyclen på motoren kan nu styres ved at ændre værdien i OCR2 (phase-cor = 						;100% og 0%)

;Initialiser BT com
	ldi	R16,(1<<RXEN)|(1<<TXEN)
	out	UCSRB,R16
	LDI	R16,(1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)
	out	UCSRC,R16
	ldi	R16,0x67
	out	UBRRL,R16

;SPI-setup
	LDI	R17,(1<<MOSI)|(1<<SCK)|(1<<SS)
	OUT	DDRB,R17
	LDI	R17,0b01011100			;SPI-enable, MSB first, Master mode, Basevalue 1, sample on trailing edge,
	OUT	SPCR,R17			;SPClock = Fosc/4 = 4MHz

	CBI	PORTB,SS

	LDI	R17,0b00100000
	OUT	SPDR,R17
SETUPWAIT:
	SBIS	SPSR,SPIF
	RJMP	SETUPWAIT
	LDI	R17,(1<<6)|(1<<0)|(1<<1)|(1<<2)
	OUT	SPDR,R17			;Power-up device
VENT:	SBIS	SPSR,SPIF
	RJMP	VENT
	SBI	PORTB,SS

LOOP:
	CBI	PORTB,SS
	LDI	R17,0b10101001			;Læs fra x-aksen
	OUT	SPDR,R17
WAIT:
	SBIS	SPSR,SPIF
	RJMP	WAIT
	IN	R18,SPDR
	LDI	R17,0
	OUT	SPDR,R17
WAITAGAIN:
	SBIS	SPSR,SPIF
	RJMP	WAITAGAIN
	IN	R16,SPDR

TRANSMIT:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	TRANSMIT
	OUT	UDR,R18
	CALL	DELAY
TRANSMIT2:
	SBIS	UCSRA,UDRE
	RJMP	TRANSMIT2
	OUT	UDR,R16
	CALL	DELAY

	SBI	PORTB,SS
	RJMP	LOOP
	


DELAY:
	ldi	R19,5			;Delay på ca. 250*250*20 clock cycles (ved 1Mhz = 5 sek.)
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
