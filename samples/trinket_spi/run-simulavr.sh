#!/bin/bash
simulavr --device atmega328 --cpufrequency 1000000 -c vcd:../../avr_lcd.traces:helloworld.vcd -f helloworld.elf --terminate LOOP
