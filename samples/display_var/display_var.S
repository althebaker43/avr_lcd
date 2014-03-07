#include <avr/io.h>

.extern LCD_INIT
.extern LCD_WRITE
.extern LCD_VAR

; BEGIN CONSTANTS


; END CONSTANTS


; BEGIN GLOBALS

    .section .data

VAR1:
    .byte   0xAA

VAR2:
    .byte   0x55

; END GLOBALS

    .section .text

; BEGIN MAIN PROGRAM

; BEGIN PROGRAM CONSTANTS

VLABEL1_ADDR:
    .asciz  "Variable1:"

VLABEL2_ADDR:
    .asciz  "Variable2:"

; END PROGRAM CONSTANTS

    .global main
main:

    rcall   LCD_INIT          ; Initialize LCD module

    ; Initialize variable 1
    ldi     R16,0xAA
    ldi     XL,lo8(VAR1)
    ldi     XH,hi8(VAR1)
    st      X,R16

    ; Initialize variable 2
    ldi     R16,0x55
    ldi     XL,lo8(VAR2)
    ldi     XH,hi8(VAR2)
    st      X,R16

    ; Display first variable value to display
    clr     R25                 ; Display on top, in hex format
    ldi     XL,lo8(VAR1)
    ldi     XH,hi8(VAR1)
    ldi     ZL,lo8(VLABEL1_ADDR)
    ldi     ZH,hi8(VLABEL1_ADDR)
    rcall   LCD_VAR
    
    ; Display second variable value to display
    ldi     R25,0x01            ; Display on bottom, in hex format
    ldi     XL,lo8(VAR2)
    ldi     XH,hi8(VAR2)
    ldi     ZL,lo8(VLABEL2_ADDR)
    ldi     ZH,hi8(VLABEL2_ADDR)
    rcall   LCD_VAR

LOOP:

    rjmp    LOOP    ; Loop back to LOOP

; END MAIN PROGRAM


; BEGIN FUNCTIONS


; END FUNCTIONS

    .global __vector_default
__vector_default:
    reti

    .end
