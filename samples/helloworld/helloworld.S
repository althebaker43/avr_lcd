#include <avr/io.h>

.extern   LCD_INIT
.extern   LCD_WRITE

; BEGIN CONSTANTS


; END CONSTANTS


; BEGIN GLOBALS

    .section .data

; END GLOBALS

    .section .text

; BEGIN MAIN PROGRAM

; BEGIN PROGRAM CONSTANTS

HIWLD_ADDR:
    .asciz  "Hello, World!"

; END PROGRAM CONSTANTS

    .global main
main:

    rcall   LCD_INIT          ; Initialize LCD module

    ; Write "Hello, World!" to LCD display
    ldi     ZL,lo8(HIWLD_ADDR)
    ldi     ZH,hi8(HIWLD_ADDR)
    rcall   LCD_STR

LOOP:

    rjmp    LOOP    ; Loop back to LOOP

; END MAIN PROGRAM


; BEGIN FUNCTIONS


; END FUNCTIONS

    .global __vector_default
__vector_default:
    reti

    .end
