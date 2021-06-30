.include "m32def.inc"

.equ	ACCreg_value=25
.equ	sving_hastighed=105
.equ	ligeud_hastighed=255
.equ	hojsving_ind1=110		;første sving ind
.equ	hojsving_ind2=90		;anden værdi er kun 75 fordi vi fik spikes der hoppede ned på ca. 80 inden svinget var
.equ	hojsving_ud=85			;færdigt
.equ	lavsving_ind1=60		;første værdi der skal være inde i sving
.equ	lavsving_ind2=60		;anden værdi der skal være inde i sving
.equ	lavsving_ud=75

.def	rigtigCounter=R20
.def	ACCdata=R21
.def	boolSving=R22
.def	antalSving=R23
.def	ACCreg=R24
.def	svingUd2=R9
.def	erISvingreg=R10
.def	boolIndISving=R11
.def	boolUdSving=R12
.def	gemReelReg=R13
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
	ldi	ACCreg,ACCreg_value

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
	ldi	R16,sving_hastighed
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

STOPBIL:
	LDI	R16,0
	OUT	OCR2,R16
	RJMP	LOOP

COUNTERINC:
	MOV	nyCounter,counter
	INC	rigtigCounter
	RJMP	LOOP

LOOP:
	CP	nyCounter,counter
	BRNE	COUNTERINC		;Hvis counter har ændret sig, så har vi passeret målstregen
	;CALL	COUNTERSEND
	CPI	rigtigCounter,2		;Første gang over målstreg, bliver den 2, og den skal mappe
	BREQ	JUMPMAIN		;Hopper til main som mapper
	CPI	rigtigCounter,3		;Anden gang over målstreg, optimerer omgangen
	BREQ	OPTIMER
	CPI	rigtigCounter,4
	BRSH	STOPBIL
	RJMP	LOOP			;Hoppet tilbage til loop ved alle andre omgange

JUMPMAIN:
	JMP	MAIN

OPTIMER:
	LDI	R16,1
	ST	X+,R16
	LD	ACCdata,Y+		;Henter næste gemte værdi
	CPI	ACCdata,2		;Kigger om det er sving, hopper til optimersving hvis det er sving	
	BREQ	OPTIMERSVING
	RJMP	OPTIMERLIGEUD		;Hvis det ikke er sving, kører den optimerligeud
	RJMP	LOOP

OPTIMERSVING:
	LDI	R16,sving_hastighed
	OUT	OCR2,R16		;Sætter hastighed til 105, som er svinghastighed
	;CALL	DELAYBREMS		;Bremser og venter afhængigt af, hvor meget den accelerede på ligeud
	CALL	TJEKREEL		;Tjekker på reel data, og venter på at den også siger ud af sving, før den fortsætter
	CALL	SEND
	RJMP	LOOP

OPTIMERLIGEUD:
	LDI	R16,ligeud_hastighed	;Sætter tophastighed, hvis vi ikke er på den
	OUT	OCR2,R16
	CALL	DELAYLIGEUD
	CPI	ACCreg,0		;Tjekker på om vi allerede er tophastighed
	BREQ	LOOP			;Der skal være delay mellem hver sampling, også hvis vi er i tophastighed
	DEC	ACCreg			;Tæller antal gange vi mangler at køre denne før den er på tophastighed ned
	LD	ACCdata,Y+		;Kigger 1 måling længere frem
	RJMP	LOOP

GEMREEL:
	LDI	R16,1
	CP	erISvingreg,R16		;hvis erISvingreg er 1 skal vi store sving, ellers ligeud
	BREQ	REELSVING
	LDI	R16,1
	MOV	gemReelReg,R16		;1 = ligeud, 2 = sving
	RET

REELSVING:
	LDI	R16,2
	MOV	gemReelReg,R16		;2 = sving
	RET

VENTPAAUDAFSVING:
	LDI	R16,1
	CP	gemReelReg,R16		;Hvis den er kommet ind i sving, venter den på at reel data siger vi er ude af sving igen
	BREQ	REELUDAFSVING2
	RJMP	TJEKREEL

REELUDAFSVING:
	CLR	boolIndISving		;Nulstiller det hele, inklusiv ACCreg
	CLR	boolUdSving
	LDI	ACCreg,ACCreg_value
IGEN:	LD	ACCdata,Y+		;Tjekker hele tiden på gemt data, for at se, hvornår den siger ud af sving, så reel og 
	CPI	ACCdata,2		;gemt data passer sammen
	BREQ	IGEN
	LD	ACCdata,-Y		;Tæller 1 ned i målinger, da det første den gør på et ligeud stykke er at tælle 1 op igen
	RET

REELETSVING:
	INC	antalSving		;Marker vi har ramt sving til ene side
	LDI	boolSving,1
	JMP	TJEKREEL

REELANDETSVING:
	INC	antalSving		;Marker vi har ramt sving til anden side
	LDI	boolSving,2
	JMP	TJEKREEL

REELERISVING:
	CPI	ACCdata,200		;Tjekker hvornår vi kommer ud af sving (lave sving)
	BRSH	TJEKREEL
	CPI	ACCdata,lavsving_ud
	BRSH	REELUDAFSVING2
	RJMP	TJEKREEL

REELERIETANDETSVING:
	CPI	ACCdata,hojsving_ud		;Tjekker hvornår vi kommer ud af sving til den anden side (høje sving)
	BRLO	REELUDAFSVING2
	JMP	TJEKREEL

REELUDAFSVING2:
	INC	svingUd2
	LDI	R16,1
	CP	svingUd2,R16
	BREQ	TJEKREEL
	CLR	svingUd2
	CLR	boolSving		;Når den kommer ud af sving skal den clear det hele
	CLR	antalSving
	CALL	SENDUDAFSVING		;Sender 10 via bluetooth for at markere ude af sving
	RJMP	REELUDAFSVING

REELSTADIGISVING:
	CPI	boolSving,1		;Tjekker om der 2 målinger i streg siger vi er inde i sving
	BREQ	REELSTADIGISVING1
	RJMP	REELSTADIGISVING2

REELSTADIGISVING1:
	CPI	ACCdata,200		;Hvis 2 målinger ikke siger den er sving, clear den sving
	BRSH	REELSKIP
	CPI	ACCdata,lavsving_ind2
	BRSH	REELCLEARANDRETURN
REELSKIP:
	INC	antalSving
	CALL	SENDSVING		;sæt hastighed/gem data
	JMP	TJEKREEL
REELSTADIGISVING2:
	CPI	ACCdata,hojsving_ind2		;Hvis 2 målinger ikke siger den er sving, clear den sving
	BRLO	REELCLEARANDRETURN
	INC	antalSving
	CALL	SENDSVING		;sæt hastighed/gem data
	JMP	TJEKREEL

REELCLEARANDRETURN:
	CLR	antalSving		;Clear sving
	CLR	boolSving
	RJMP	TJEKREEL

TJEKREEL:
	CALL	CONVERT			;Henter næste reele tal
	CALL	GEMREEL			;Gemmer om det er sving eller ej i gemReelReg
	CALL	SENDREELDATA
	;CALL	SEND
	CPI	antalSving,1		;Tjekker om der er 2 målinger i streg som siger sving, for at fjerne fejlmålinger
	BREQ	REELSTADIGISVING
	CPI	boolSving,1		;Tjekker om vi er ude af sving til ene side, når antalSving >= 1
	BREQ	REELERISVING
	CPI	boolSving,2		;Tjekker om vi er ude af sving til anden side, når antalSving >= 1
	BREQ	REELERIETANDETSVING
	CPI	ACCdata,lavsving_ind1
	BRLO	REELETSVING		;Tjekker om vi er kommet ind i sving til ene side
	CPI	ACCdata,hojsving_ind1
	BRSH	REELANDETSVING		;Tjekker om vi er kommet ind i sving til anden side
	CLR	antalSving
	LDI	R16,1
	CP	boolIndISving,R16	;tjekker om vi har været i sving/er i sving
	BREQ	JUMPVENTPAAUDAFSVING	;Hvis vi stadig er i sving skal den vente
	LDI	R16,1
	CPSE	gemReelReg,R16		;Gemmer om vi er i sving
	RJMP	SETINDISVING
	RJMP	TJEKREEL		;Hvis det er ligeud kører den igen

JUMPVENTPAAUDAFSVING:
	JMP	VENTPAAUDAFSVING

SETINDISVING:
	LDI	R16,1			;Gemmer vi ramte sving i reel data
	MOV	boolIndISving,R16
	RJMP	TJEKREEL
	
MAIN:
	CALL	CONVERT			;Henter ny data
	CALL	GEMDATA			;Gemmer data i stacken
	CALL	SEND	
	CPI	antalSving,1		;Samme som i tjekreel
	BREQ	STADIGISVING
	CPI	boolSving,1
	BREQ	ERISVING
	CPI	boolSving,2
	BREQ	ERIETANDETSVING
	CPI	ACCdata,lavsving_ind1
	BRLO	ETSVING
	CPI	ACCdata,hojsving_ind1
	BRSH	ANDETSVING
	CLR	antalSving
	RJMP	LOOP

ETSVING:
	INC	antalSving		;Marker vi har ramt sving til ene side
	LDI	boolSving,1
	RJMP	LOOP

ANDETSVING:
	INC	antalSving		;Marker vi har ramt sving til anden side
	LDI	boolSving,2
	RJMP	LOOP

ERISVING:
	CPI	ACCdata,200		;Tjekker hvornår vi kommer ud af sving
	BRSH	JUMPLOOP
	CPI	ACCdata,lavsving_ud		;(lave sving)
	BRSH	UDAFSVING
	RJMP	LOOP

JUMPLOOP:
	JMP	LOOP

ERIETANDETSVING:
	CPI	ACCdata,hojsving_ud		;Tjekker hvornår vi kommer ud af sving til den anden side(høje sving)
	BRLO	UDAFSVING
	RJMP	LOOP

UDAFSVING:
	INC	svingUd2
	LDI	R16,1
	CP	svingUd2,R16
	BREQ	JUMPLOOP
	CLR	svingUd2
	CLR	boolSving		;Når den kommer ud af sving skal den clear det hele
	CLR	antalSving
	CALL	SENDUDAFSVING		;Sender 10 via bluetooth for at markere ude af sving
	RJMP	LOOP

STADIGISVING:
	CPI	boolSving,1		;Tjekker om der 2 målinger i streg siger vi er inde i sving
	BREQ	STADIGISVING1
	RJMP	STADIGISVING2

STADIGISVING1:
	CPI	ACCdata,200		;Hvis 2 målinger ikke siger den er sving, clear den sving
	BRSH	SKIPNED
	CPI	ACCdata,lavsving_ind2
	BRSH	CLEARANDRETURN
SKIPNED:
	INC	antalSving
	CALL	SENDSVING		;sæt hastighed/gem data
	RJMP	LOOP
STADIGISVING2:
	CPI	ACCdata,hojsving_ind2		;Hvis 2 målinger ikke siger den er sving, clear den sving
	BRLO	CLEARANDRETURN
	INC	antalSving
	CALL	SENDSVING		;sæt hastighed/gem data
	RJMP	LOOP

CLEARANDRETURN:
	CLR	antalSving		;Clear sving
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

GEMDATA:
	LDI	R16,1
	CP	erISvingreg,R16		;hvis erISvingreg er 1 skal vi store sving, ellers ligeud
	BREQ	GEMSVING
	LDI	R16,1
	ST	X+,R16			;1 = ligeud, 2 = sving
	RET

GEMSVING:
	LDI	R16,2
	ST	X+,R16			;2 = sving
	RET

SENDSVING:
	LDI	R16,1
	MOV	erISvingreg,R16		;Brugs til at gemme data, hvor den tjekker om det er sving eller ej

	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SENDSVING
	LDI	R16,1
	OUT	UDR,R16
	RET

SENDUDAFSVING:
	CLR	erISvingreg

	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SENDUDAFSVING
	LDI	R16,10
	OUT	UDR,R16
	RET

SEND:
	SBIS	UCSRA,UDRE		;Loop til send data
	RJMP	SEND
	OUT	UDR,ACCdata
	RET

COUNTERSEND:
	SBIS	UCSRA,UDRE
	RJMP	COUNTERSEND
	OUT	UDR,rigtigCounter
	RET

SENDREELDATA:
	SBIS	UCSRA,UDRE
	RJMP	SENDREELDATA
	OUT	UDR,gemReelReg
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
	LDI	R16,sving_hastighed
	OUT	OCR2,R16
	RETI

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

DELAYLIGEUD:
	MOV	R19,ACCreg		;Delay på ca. 4*250*110*5 clock cycles (550.000 cycles = ca. 34ms ved 16MHz)
	CPI	R19,0
	BREQ	HOPHER
DELAYLIGEUD4:
	LDI	R18,5
DELAYLIGEUD3:
	LDI	R17,65
DELAYLIGEUDIGEN:
	NOP
	NOP
	DEC	R17
	BRNE	DELAYLIGEUDIGEN
	DEC	R18
	BRNE	DELAYLIGEUD3
	DEC	R19
	BRNE	DELAYLIGEUD4
HOPHER:
	LDI	R17,80
DELAYLIGEUD2:
	LDI	R16,250
DELAYLIGEUD1:				;Tom cycle
	NOP
	DEC	R16			;Decrement
	BRNE	DELAYLIGEUD1		;Kører 250 gange (R17's værdi)
	dec	R17
	BRNE	DELAYLIGEUD2
	ret

DELAYBREMS:
	LDI	R19,ACCreg_value	;skal være det samme som ACCreg fra start
	SUB	R19,ACCreg
	;LDI	R16,2
	;MUL	R16,R19
	;MOV	R19,R0			;Delay på ca. 5*250*252*(19-ACCreg) clock cycles
	CPI	R19,0
	BREQ	RETURN
DELAYBREMS3:
	LDI	R18,252
DELAYBREMS2:
	LDI	R17,250
DELAYBREMS1:
	NOP	
	NOP				;Tom cycle
	DEC	R17			;Decrement
	BRNE	DELAYBREMS1		;Kører 250 gange (R17's værdi)
	dec	R18
	BRNE	DELAYBREMS2
	dec	R19
	BRNE	DELAYBREMS3
RETURN:	ret

;Grunden til det ikke virker når vi tjekker på forkert data er, at vi får så meget forkert data ind, at 9599 at byte'sne vi får ind er forkerte og kun 1 rigtig. Det gør at outputtet bliver domineret af det forkerte data
