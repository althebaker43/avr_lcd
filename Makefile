# AVR assembler Makefile
# Originated from AVR-Libc sample projects page
# http://www.nongnu.org/avr-libc/examples/demo/Makefile

PROJ           = avr_lcd
LIB            = lib$(PROJ).a
OBJ            = avr_lcd.o
MCU_TARGET     = atmega328p
SIM_TARGET     = atmega328
OPTIMIZE       =

DEFS           =
LIBS           =

EXTRA_CLEAN_FILES       = *.hex *.bin *.srec

# You should not have to change anything below here.

CC = avr-gcc
AR = avr-ar

# Override is only needed by avr-lib build system.

ifdef SIM
override CFLAGS        = -Wall $(OPTIMIZE) -mmcu=$(SIM_TARGET) $(DEFS)
else
override CFLAGS        = -Wall $(OPTIMIZE) -mmcu=$(MCU_TARGET) $(DEFS)
endif

override LDFLAGS       = -Wl,-Map,$(PROJ).map
ASFLAGS = -Wa,-mno-wrap,--gstabs,-alms=$(PROJ).lst

OBJCOPY        = avr-objcopy
OBJDUMP        = avr-objdump

all: $(LIB) lst text eeprom

$(LIB): $(OBJ)
ifdef SIM
	@echo "\nINFO: Generating simulation files.\n"
else
	@echo "\nINFO: Generating hardware files.\n"
endif
	avr-ar rcs $@ $^

# dependency:
avr_lcd.o: avr_lcd.S
	$(CC) $(CFLAGS) $(ASFLAGS) -x assembler-with-cpp -c -o $@ $^

clean:
	rm -rf *.o $(LIB) *.eps *.png *.pdf *.bak 
	rm -rf *.lst *.map $(EXTRA_CLEAN_FILES)

lst:  $(PROJ).lst

%.lst: lib%.a
	$(OBJDUMP) -h -S $< > $@

# Rules for building the .text rom images

text: hex bin srec

hex:  $(PROJ).hex
bin:  $(PROJ).bin
srec: $(PROJ).srec

%.hex: %.o
	$(OBJCOPY) -j .text -j .data -O ihex $< $@

%.srec: %.o
	$(OBJCOPY) -j .text -j .data -O srec $< $@

%.bin: %.o
	$(OBJCOPY) -j .text -j .data -O binary $< $@

# Rules for building the .eeprom rom images

eeprom: ehex ebin esrec

ehex:  $(PROJ)_eeprom.hex
ebin:  $(PROJ)_eeprom.bin
esrec: $(PROJ)_eeprom.srec

%_eeprom.hex: %.o
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O ihex $< $@ \
	|| { echo empty $@ not generated; exit 0; }

%_eeprom.srec: %.o
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O srec $< $@ \
	|| { echo empty $@ not generated; exit 0; }

%_eeprom.bin: %.o
	$(OBJCOPY) -j .eeprom --change-section-lma .eeprom=0 -O binary $< $@ \
	|| { echo empty $@ not generated; exit 0; }

# Every thing below here is used by avr-libc's build system and can be ignored
# by the casual user.

FIG2DEV                 = fig2dev

dox: eps png pdf

eps: $(PROJ).eps
png: $(PROJ).png
pdf: $(PROJ).pdf

%.eps: %.fig
	$(FIG2DEV) -L eps $< $@

%.pdf: %.fig
	$(FIG2DEV) -L pdf $< $@

%.png: %.fig
	$(FIG2DEV) -L png $< $@

