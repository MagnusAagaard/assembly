# Makefile for programming ATmega32 using assembler
PROJECT=bil_2sem
PROGRAMMER=-c usbasp -P usb

default:
	sudo avrdude -p m32 $(PROGRAMMER) -U flash:w:$(PROJECT).hex

fuse:
	sudo avrdude -p m32 $(PROGRAMMER) -U hfuse:w:0xd9:m -U lfuse:w:0xff:m

clean:
	rm -f $(PROJECT).obj $(PROJECT).hex $(PROJECT).cof $(PROJECT).eep.hex

erase:
	sudo avrdude -p m32 $(PROGRAMMER) -e
