#!/bin/bash
simulavr --device atmega328 --cpufrequency 1000000 -c vcd:avr_lcd.traces:avr_lcd.vcd -f avr_lcd.elf --terminate LOOP
