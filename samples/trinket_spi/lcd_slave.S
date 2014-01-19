#include <avr/io.h>

; BEGIN CONSTANTS


; END CONSTANTS


; BEGIN GLOBALS

    .section .data

; END GLOBALS

    .section .text

; BEGIN MAIN PROGRAM

; BEGIN PROGRAM CONSTANTS

LCD_INIT_STR:
    .asciz  "LCD Init."

SPI_INIT_STR:
    .asciz  "SPI Init."

SPI_NINIT_STR:
    .asciz  "Error: SPI."

; END PROGRAM CONSTANTS

    .global main
main:

    rcall   LCD_INIT          ; Initialize LCD module

    ldi     ZL,lo8(LCD_INIT_STR)
    ldi     ZH,hi8(LCD_INIT_STR)
    rcall   LCD_WRITE

LOOP:

    rjmp    LOOP    ; Loop back to LOOP

; END MAIN PROGRAM


; BEGIN FUNCTIONS


; END FUNCTIONS

    .global __vector_default
__vector_default:
    reti

    .end
