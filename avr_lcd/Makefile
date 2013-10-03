PROJECT=avr_lcd
ASSEMBLER=avr-gcc
MCU=atmega328p

all : $(PROJECT).S
	$(ASSEMBLER) -mmcu=$(MCU) $(PROJECT).S
