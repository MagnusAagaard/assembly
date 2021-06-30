# Makefile for programming ATmega32 using assembler
PROJECT=7seg
PROGRAMMER=-c usbasp -P usb

default:
	avra $(PROJECT).asm
	sudo avrdude -p m32 $(PROGRAMMER) -U flash:w:$(PROJECT).hex

fuse:
	sudo avrdude -p m32 $(PROGRAMMER) -U hfuse:w:0xd9:m -U lfuse:w:0xe1:m

clean:
	rm -f $(PROJECT).obj $(PROJECT).hex $(PROJECT).cof $(PROJECT).eep.hex

erase:
	sudo avrdude -p m32 $(PROGRAMMER) -e
