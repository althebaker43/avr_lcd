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

METOO_ADDR:
    .asciz  "Me too!"

; END PROGRAM CONSTANTS

    .global main
main:

    rcall   LCD_INIT          ; Initialize LCD module

    ; Write "Hello, World!" to LCD display
    ldi     ZL,lo8(HIWLD_ADDR)
    ldi     ZH,hi8(HIWLD_ADDR)
    rcall   LCD_STR

    ; Change position to next line
    ldi     r16,0x40
    rcall   SET_POS

    ; Write "Me too!" to LCD display
    ldi     ZL,lo8(METOO_ADDR)
    ldi     ZH,hi8(METOO_ADDR)
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
