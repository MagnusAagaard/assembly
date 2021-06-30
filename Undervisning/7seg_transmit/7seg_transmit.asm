.include "m32def.inc"

.org	0
	JMP	RESET

.org	URXCaddr
	JMP	MODTAG

.org	0x2A
RESET:
;initialiser stacks			;Skal bruges til CALL
	ldi	R16,HIGH(RAMEND)
	out	SPH,R16
	ldi	R16,LOW(RAMEND)
	out	SPL,R16

;Initialiser BT com
	ldi	R16,(1<<U2X)
	OUT	UCSRA,R16
	ldi	R16,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)	;enable transmit og recieve
	out	UCSRB,R16
	LDI	R16,(1<<UCSZ1)|(1<<UCSZ0)|(1<<URSEL)	;8 bits data
	out	UCSRC,R16
	ldi	R16,12
	out	UBRRL,R16				;baud rate = 9600 ved 1 MHz med U2X = 1 (double speed)

	SEI

HERE:
	RJMP	HERE

MODTAG:
	IN	R16,UDR
	CPI	R16,65
	BRSH	STOR
	OUT	UDR,R16
	RETI

STOR:
	CPI	R16,91
	BRSH	STORRE
	LDI	R17,32
	ADD	R16,R17
	OUT	UDR,R16
	RETI

STORRE:
	CPI	R16,97
	BRSH	LILLE
	OUT	UDR,R16
	RETI

LILLE:
	CPI	R16,123
	BRSH	RETURN
	LDI	R17,32
	SUB	R16,R17
	OUT	UDR,R16
	RETI

RETURN:
	OUT	UDR,R16
	RETI
