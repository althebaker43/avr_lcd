# AVR assembler Makefile
# Originated from AVR-Libc sample projects page
# http://www.nongnu.org/avr-libc/examples/demo/Makefile

PRG            = two_line
OBJ            = $(PRG).o
MCU_TARGET     = atmega328p
SIM_TARGET     = atmega328
OPTIMIZE       =

DEFS           =
LIBS           = -lavr_lcd -L../../

# You should not have to change anything below here.

CC = avr-gcc

# Override is only needed by avr-lib build system.

ifdef SIM
override CFLAGS        = -Wall $(OPTIMIZE) -mmcu=$(SIM_TARGET) $(DEFS)
else
override CFLAGS        = -Wall $(OPTIMIZE) -mmcu=$(MCU_TARGET) $(DEFS)
endif

override LDFLAGS       = -Wl,-Map,$(PRG).map,--cref
ASFLAGS = -Wa,-mno-wrap,--gstabs,-alms=$(PRG).lst

OBJCOPY        = avr-objcopy
OBJDUMP        = avr-objdump

all: $(PRG).elf lst text eeprom

$(PRG).elf: $(PRG).S
ifdef SIM
	@echo ""
	@echo "INFO: Generating simulation files."
	@echo ""
else
	@echo ""
	@echo "INFO: Generating hardware files."
	@echo ""
endif
	$(CC) $(CFLAGS) $(ASFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	rm -rf *.o $(PRG).elf *.eps *.png *.pdf *.bak 
	rm -rf *.lst *.map $(EXTRA_CLEAN_FILES)

lst:  $(PRG).lst

%.lst: %.elf
	$(OBJDUMP) -h -S $< > $@

# Rules for building the .text rom images

text: hex bin srec

hex:  $(PRG).hex
bin:  $(PRG).bin
srec: $(PRG).srec

%.hex: %.elf
	$(OBJCOPY) -j .text -j .data -O ihex $< $@

%.srec: %.elf
	$(OBJCOPY) -j .text -j .data -O srec $< $@

%.bin: %.elf
	$(OBJCOPY) -j .text -j .data -O binary $< $@

# Rules for building the .eeprom rom images

eeprom: ehex ebin esrec

ehex:  $(PRG)_eeprom.hex
ebin:  $(PRG)_eeprom.bin
esrec: $(PRG)_eeprom.srec

%_eeprom.hex: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O ihex $< $@ \
	|| { echo empty $@ not generated; exit 0; }

%_eeprom.srec: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O srec $< $@ \
	|| { echo empty $@ not generated; exit 0; }

%_eeprom.bin: %.elf
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O binary $< $@ \
	|| { echo empty $@ not generated; exit 0; }

# Every thing below here is used by avr-libc's build system and can be ignored
# by the casual user.

FIG2DEV                 = fig2dev
EXTRA_CLEAN_FILES       = *.hex *.bin *.srec

dox: eps png pdf

eps: $(PRG).eps
png: $(PRG).png
pdf: $(PRG).pdf

%.eps: %.fig
	$(FIG2DEV) -L eps $< $@

%.pdf: %.fig
	$(FIG2DEV) -L pdf $< $@

%.png: %.fig
	$(FIG2DEV) -L png $< $@

