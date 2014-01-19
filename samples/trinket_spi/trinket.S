#include <avr/io.h>

; BEGIN CONSTANTS


; END CONSTANTS


; BEGIN GLOBALS

    .section .data

; END GLOBALS

    .section .text

; BEGIN MAIN PROGRAM

; BEGIN PROGRAM CONSTANTS

HIWLD_STR:
    .asciz  "Hello, world!"

; END PROGRAM CONSTANTS

    .global main
main:

    rcall   SPI_INIT          ; Initialize LCD module

    ldi     ZL,lo8(HIWLD_STR)
    ldi     ZH,hi8(HIWLD_STR)
    rcall   SPI_WRITE

LOOP:

    rjmp    LOOP    ; Loop back to LOOP

; END MAIN PROGRAM


; BEGIN FUNCTIONS


SPI_INIT:

    ret


SPI_WRITE:

    ret


; END FUNCTIONS

    .global __vector_default
__vector_default:
    reti

    .end
