.include "m32def.inc"

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
	out	TCCR2,R16		;Farten/duty cyclen på motoren kan nu styres ved at ændre værdien i OCR2 (phase-cor = 100% og 0%)

;Initialiser BT com
	ldi	R16,(1<<RXEN)|(1<<TXEN)
	out	UCSRB,R16
	LDI	R16,(1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)
	out	UCSRC,R16
	ldi	R16,0x67
	out	UBRRL,R16

	rjmp	LOOPMODTAG

LOOPMODTAG:
	SBIS	UCSRA,RXC
	RJMP	LOOPMODTAG
	IN	R17,UDR
	CPI	R17,'G'			;Skal kun reagere på det rigtige data, ellers skaber vi overflow
	BRNE	CHECK			;Hvis vi ikke modtager 'G' hopper vi ned til check og tjekker om det så er 'A'
	RJMP	RIGTIGT			;Sender kun R hvis det er det rigtige data vi modtager, ellers gemmer vi det ikke

CHECK:
	CPI	R17,'A'			;Hvis det er 'A' hopper vi til rigtigt2 og udskriver 'J'
	BRNE	LOOPMODTAG		;Ellers hopper vi tilbage og tjekker igen - C++ vil udksrive den sidste værdi den
	RJMP	RIGTIGT2		;har modtaget, så C++ vil blive ved med at udskrive 'R' hvis det ikke bliver ændret her

RIGTIGT:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	RIGTIGT
	LDI	R16,'R'
	OUT	UDR,R17
	CALL	DELAY
	RJMP	LOOPMODTAG

RIGTIGT2:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	RIGTIGT2
	LDI	R16,'J'
	OUT	UDR,R16
	CALL	DELAY
	RJMP	LOOPMODTAG

;Start progamløkken
;LOOP:					;Loop til modtag data
;	SBIS	UCSRA,RXC
;	RJMP	LOOP
;	LDI	R16,150
;	OUT	OCR2,R16
;	RJMP	LOOP


;LOOP:					;Loop til test af fart styring
;	ldi	R16,200			;Duty cycle på (255-OCR2-1)/256*100 = 21%
;	out	OCR2,R16		;Outes for at ændre værdien
;	CALL	DELAY			;Delay imellem skiftet
;	ldi	R16,150			;Duty cycle på 41%
;	out	OCR2,R16
;	CALL	DELAY
;	rjmp	LOOP
;
;
DELAY:
	ldi	R19,255			;Delay på ca. 250*250*20 clock cycles (ved 1Mhz = 5 sek.)
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
