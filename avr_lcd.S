; avr_lcd.S
;
;  Created: 6/5/2013 7:24:35 PM
;   Author: Allen Baker

#include <avr/io.h>

; BEGIN CONSTANTS


; Delay constants
.SET        WAIT_64US,0
.SET        WAIT_128US,1
.SET        WAIT_320US,4
.SET        WAIT_2MS,31
.SET        WAIT_5MS,78
.SET        WAIT_15MS,234

; Control line definitions (for Port B)
.SET        CNTRL,PORTB
.SET        RS,PORTB0
.SET        RW,PORTB1
.SET        E,PORTB2
.SET        LCD_FAIL,PORTB3

; Data line definitions (for Port C)
.SET        DATA,PORTC
.SET        DB4,PORTC0
.SET        DB5,PORTC1
.SET        DB6,PORTC2
.SET        DB7,PORTC3
.SET        BF,PORTC3

; Character codes

; Uppercase
.SET        CH_A_UP,0x41
.SET        CH_B_UP,0x42
.SET        CH_C_UP,0x43
.SET        CH_D_UP,0x44
.SET        CH_E_UP,0x45
.SET        CH_F_UP,0x46
.SET        CH_G_UP,0x47
.SET        CH_H_UP,0x48
.SET        CH_I_UP,0x49
.SET        CH_J_UP,0x4A
.SET        CH_K_UP,0x4B
.SET        CH_L_UP,0x4C
.SET        CH_M_UP,0x4D
.SET        CH_N_UP,0x4E
.SET        CH_O_UP,0x4F
.SET        CH_P_UP,0x50
.SET        CH_Q_UP,0x51
.SET        CH_R_UP,0x52
.SET        CH_S_UP,0x53
.SET        CH_T_UP,0x54
.SET        CH_U_UP,0x55
.SET        CH_V_UP,0x56
.SET        CH_W_UP,0x57
.SET        CH_X_UP,0x58
.SET        CH_Y_UP,0x59
.SET        CH_Z_UP,0x5A

; Lowercase
.SET        CH_A_LOW,0x61
.SET        CH_B_LOW,0x62
.SET        CH_C_LOW,0x63
.SET        CH_D_LOW,0x64
.SET        CH_E_LOW,0x65
.SET        CH_F_LOW,0x66
.SET        CH_G_LOW,0x67
.SET        CH_H_LOW,0x68
.SET        CH_I_LOW,0x69
.SET        CH_J_LOW,0x6A
.SET        CH_K_LOW,0x6B
.SET        CH_L_LOW,0x6C
.SET        CH_M_LOW,0x6D
.SET        CH_N_LOW,0x6E
.SET        CH_O_LOW,0x6F
.SET        CH_P_LOW,0x70
.SET        CH_Q_LOW,0x71
.SET        CH_R_LOW,0x72
.SET        CH_S_LOW,0x73
.SET        CH_T_LOW,0x74
.SET        CH_U_LOW,0x75
.SET        CH_V_LOW,0x76
.SET        CH_W_LOW,0x77
.SET        CH_X_LOW,0x78
.SET        CH_Y_LOW,0x79
.SET        CH_Z_LOW,0x7A

; Punctuation
.SET        CH_SPACE,0x20
.SET        CH_EXCL,0x21
.SET        CH_COMMA,0x2C


; END CONSTANTS


; BEGIN GLOBALS


    .section .data


; END GLOBALS


; BEGIN MAIN PROGRAM


    .section .text

; BEGIN PROGRAM CONSTANTS

HIWLD_ADDR:
    .byte   CH_H_UP
    .byte   CH_E_LOW
    .byte   CH_L_LOW
    .byte   CH_L_LOW
    .byte   CH_O_LOW
    .byte   CH_COMMA
    .byte   CH_SPACE
    .byte   CH_W_UP
    .byte   CH_O_LOW
    .byte   CH_R_LOW
    .byte   CH_L_LOW
    .byte   CH_D_LOW
    .byte   CH_EXCL
    .byte   0x00 

; END PROGRAM CONSTANTS


    .global main
main:

; Setup Port B

    ; Set low nibble of Port B to output
    ; All outputs are initially low
    LDI     R16,0x0F
    OUT     _SFR_IO_ADDR(DDRB),R16

; Setup Port C
CONFIG_PORTC:

    ; Set low nibble of Port C to output
    ; All outputs are initially low
    LDI     R16,0x0F
    OUT     _SFR_IO_ADDR(DDRC),R16

; Configure Timer 0
CONFIG_T0:
    
    ; Disable power reduction for Timer 0
    ; PRR: Power Reduction Register
    LDI     XL,lo8(PRR)     ; Move low byte of PRR into XL
    LDI     XH,hi8(PRR)     ; Move high byte of PRR into XH
    LD      R16,X           ; Load PRR contents into R16
    CBR     R16,0X20        ; Clear Timer 0 bit
    ST      X,R16           ; Store new flags into PRR

    ; Disconnect ports 
    ; Disable waveform generation
    ; Set clock source to internal I/O clock
    ; Prescaler set to divide freq. by 64
    CLR     R16         ; Clear R16
    OUT     _SFR_IO_ADDR(TCCR0A),R16  ; Clear TCCR0A
    LDI     R16,0X03    ; Set [0] and [1] in R16
    OUT     _SFR_IO_ADDR(TCCR0B),R16  ; Set [0] and [1] in TCCR0B

    ; Disable all Timer 0 interrupts
    LDI     XL,lo8(TIMSK0)  ; Load low byte of TIMSK0 address into XL
    LDI     XH,hi8(TIMSK0)  ; Load high byte of TIMSK0 address into XH
    CLR     R16             ; Clear R16
    ST      X,R16           ; Clear TIMSK0

CONFIG_LCD:

    ; Drive all data lines low
    LDI     R16,0XF0
    OUT     _SFR_IO_ADDR(DATA),R16
    SWAP    R16
    OUT     _SFR_IO_ADDR(DDRC),R16

    ; Drive all control lines low (except for LCD_FAIL)
    IN      R16,_SFR_IO_ADDR(CNTRL)
    ANDI    R16,0XF8
    OUT     _SFR_IO_ADDR(CNTRL),R16

    ; Delay for >40ms after power-up
    LDI     R25,WAIT_15MS
    RCALL   WAIT    ; 15 ms 
    RCALL   WAIT    ; 30 ms
    RCALL   WAIT    ; 45 ms

    ; Output wakeup #1
    LDI     R23,0X30    ; Function set: 8-bit bus width (not really)
    CBR     R25,0X01    ; 4-bit bus width
    SBR     R25,0X02    ; 4-bit setup mode
    SBR     R25,0X04    ; Do not wait on busy flag
    RCALL   WRITE_CMD
    
    ; Delay for 5ms
    LDI     R24,WAIT_5MS
    RCALL   WAIT
    
    ; Output wakeup #2
    RCALL   WRITE_CMD
    
    ; Delay for 5ms
    LDI     R24,WAIT_5MS
    RCALL   WAIT
    
    ; Output wakeup #3
    RCALL   WRITE_CMD
    
    ; Delay for 320us
    LDI     R24,WAIT_320US
    RCALL   WAIT

    ; Function set #1:
    ;  4-bit bus width
    ;  2-line display
    ;  5x8 dot character resolution
    LDI     R23,0X28
    RCALL   WRITE_CMD

    ; Delay for 128 us
    LDI     R24,WAIT_128US
    RCALL   WAIT
    
    ; Output function set #2
    CBR     R25,0X02    ; Disable 4-bit setup mode
    RCALL   WRITE_CMD
    
    ; Delay for 128 us
    RCALL   WAIT
    
    ; Turn on LCD:
    ;  Cursor on
    ;  Cursor blinking
LCD_ON:
    LDI     R23,0X0F        ; Display on command
    RCALL   WRITE_CMD
    
    ; Delay for 128 us
    LDI     R24,WAIT_128US
    RCALL   WAIT
    
    ; Display clear
LCD_CLEAR:
    LDI     R23,0X01        ; Clear display command
    RCALL   WRITE_CMD

    ; Delay for 2 ms
    LDI     R24,WAIT_2MS
    RCALL   WAIT
    
    ; Entry mode set:
    ;  Increment cursor
    ;  Shift display
LCD_ENTRY:
    LDI     R23,0X06        ; Entry mode command
    RCALL   WRITE_CMD

    ; Delay for 128 us
    LDI     R24,WAIT_128US
    RCALL   WAIT
    
    ; Write characters for "Hello, World!" to display
LCD_WRITE:

    LDI     R30,lo8(HIWLD_ADDR)
    LDI     R31,hi8(HIWLD_ADDR)
    RCALL   WRITE_STR


LOOP:

    RJMP    LOOP    ; Loop back to LOOP


; END OF MAIN PROGRAM

; BEGIN FUNCTIONS


; Name: WRITE_CMD
; Descr: Writes a command to the LCD display
; Inputs:
;  R23 - Command to write
;  R24 - Time-out value
;  R25[0] - Bus width (ignored for now) (0 = 4-bit, 1 = 8-bit)
;  R25[1] - 4-bit setup mode? (0 = no, 1 = yes)
;  R25[2] - Wait on Busy Flag? (0 = yes, 1 = no)
; Outputs:
;  R25[3] - Time-out occurred (0 = no, 1 = yes)
WRITE_CMD:

    ; If requested, wait on BF
    SBRC    R25,2               ; Check wait-busy argument
    RJMP    WRITE_CMD_DWIDTH    ; If set, jump to WRITE_CMD_DWIDTH
    RCALL   WAIT_BUSY           ; Else, call WAIT_BUSY
    SBRC    R25,3               ; Check WAIT_BUSY return value
    RET                         ; If set, return from WRITE_CMD

WRITE_CMD_DWIDTH:

    RJMP    WRITE_CMD_4BIT  ; If set, jump to 4-bit write

WRITE_CMD_8BIT:
    
    ; Set all pins on PORTC to output
    LDI     R16,0XFF
    OUT     _SFR_IO_ADDR(DDRC),R16

    CBI     _SFR_IO_ADDR(CNTRL),RW    ; Write operation
    CBI     _SFR_IO_ADDR(CNTRL),RS    ; Select Instruction Register

    ; Move command to output port
    OUT     _SFR_IO_ADDR(DATA),R23

    ; Pulse Enable to send
    SBI     _SFR_IO_ADDR(CNTRL),E
    CBI     _SFR_IO_ADDR(CNTRL),E

    ; Drive data pins low
    CLR     R16
    OUT     _SFR_IO_ADDR(DATA),R16

    RET ; Return from WRITE_CMD

WRITE_CMD_4BIT:
    
    ; Set first four pins on PORTC to output
    ; The rest are inputs
    LDI     R16,0X0F
    OUT     _SFR_IO_ADDR(DDRC),R16

    ; Enable pull-ups on input pins
    SWAP    R16
    IN      R17,_SFR_IO_ADDR(DATA)
    OR      R17,R16
    OUT     _SFR_IO_ADDR(DATA),R17

    CBI     _SFR_IO_ADDR(CNTRL),RW    ; Clear Read/Write
    CBI     _SFR_IO_ADDR(CNTRL),RS    ; Clear Register Select

    ; Move high byte of command to output port
    MOV     R16,R23
    SWAP    R16
    ORI     R16,0XF0    ; Keep pull-ups enabled on input pins
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Pulse Enable to send
    SBI     _SFR_IO_ADDR(CNTRL),E
    CBI     _SFR_IO_ADDR(CNTRL),E

    SBRC    R25,1           ; Check 4-bit setup mode flag
    RJMP    WRITE_CMD_END   ; If set, jump to WRITE_CMD_END

    ; Move low byte of command to output port
    MOV     R16,R23
    ORI     R16,0XF0    ; Keep pull-ups enabled on input pins
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Pulse Enable to send
    SBI     _SFR_IO_ADDR(CNTRL),E
    CBI     _SFR_IO_ADDR(CNTRL),E

WRITE_CMD_END:

    ; Drive data pins low
    LDI     R16,0XF0
    OUT     _SFR_IO_ADDR(DATA),R16

    RET ; Return from WRITE_CMD


; Name: WRITE_DATA
; Descr: Writes data to the LCD data RAM,
;   Always waits for 128 us afterwards
; Inputs:
;  R23 - Data to write
WRITE_DATA:
    
    ; Set first four pins on PORTC to output
    ; The rest are inputs
    LDI     R16,0X0F
    OUT     _SFR_IO_ADDR(DDRC),R16

    ; Enable pull-ups on input pins
    SWAP    R16
    IN      R17,_SFR_IO_ADDR(DATA)
    OR      R17,R16
    OUT     _SFR_IO_ADDR(DATA),R17

    CBI     _SFR_IO_ADDR(CNTRL),RW    ; Clear Read/Write
    SBI     _SFR_IO_ADDR(CNTRL),RS    ; Set Register Select

    ; Move high byte of data to output port
    MOV     R16,R23
    SWAP    R16
    ORI     R16,0XF0    ; Keep pull-ups enabled on input pins
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Pulse Enable to send
    SBI     _SFR_IO_ADDR(CNTRL),E
    CBI     _SFR_IO_ADDR(CNTRL),E

    ; Move low byte of command to output port
    MOV     R16,R23
    ORI     R16,0XF0    ; Keep pull-ups enabled on input pins
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Pulse Enable to send
    SBI     _SFR_IO_ADDR(CNTRL),E
    CBI     _SFR_IO_ADDR(CNTRL),E

    ; Drive data pins low
    LDI     R16,0XF0
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Wait for 128 us
    LDI     R24,WAIT_128US
    RCALL   WAIT

    RET ; Return from WRITE_DATA


; Name: WAIT_BUSY
; Descr: Wait for busy flag
; Inputs:
;  R24 - Timeout value
; Output:
;  R25[3] - Return value (0 = ready, 1 = timed-out)
WAIT_BUSY:

    CBR     R25,0X08        ; Set return value to ready

    OUT     _SFR_IO_ADDR(OCR0A),R24     ; Store interval constant 
                                        ;   in output compare register
    SBI     _SFR_IO_ADDR(TIFR0),OCF0A   ; Clear output compare flag
    CLR     R16             ; Clear R16
    OUT     _SFR_IO_ADDR(TCNT0),R17       ; Reset Timer 0

READ_BUSY:

    RCALL   READ_STATUS     ; Read busy flag from LCD

    SBRS    R25,3           ; Check busy flag
    RJMP    WAIT_BUSY_END   ; If cleared, branch to end

    SBIS    _SFR_IO_ADDR(TIFR0),OCF0A   ; Check timer compare flag
    RJMP    READ_BUSY       ; If cleared, loop back
    SBR     R25,0X08        ; Else, set return value to timed-out

WAIT_BUSY_END:

    RET ; Return from WAIT_BUSY


; Name: READ_STATUS
; Descr: Read Busy Flag and Address Counter contents
;  of LCD
; Note: Busy Flag will always be cleared from 
;  Address Counter output register
; Inputs:
;  R25[1]: 4-bit setup mode? (0 = no, 1 = yes)
; Outputs:
;  R25[3]: Busy flag (0 = ready, 1 = busy)
;  R22[6:0]: Address counter contents
READ_STATUS:

    ; Set data pins to input (pull-ups disabled)
    CLR     R16
    OUT     _SFR_IO_ADDR(DDRC),R16

    SBR     R25,0X08    ; Default Busy indicator to busy

    SBI     _SFR_IO_ADDR(CNTRL),RW    ; Read operation
    CBI     _SFR_IO_ADDR(CNTRL),RS    ; Select Instruction Register

    ; Get high nibble of address counter
READ_STATUS_HI:

    SBI     _SFR_IO_ADDR(CNTRL),E     ; Raise Enable
    IN      R22,_SFR_IO_ADDR(DATA)    ; Copy input pin values
    CBI     _SFR_IO_ADDR(CNTRL),E     ; Lower Enable
    
    SWAP    R22         ; Swap nibbles in output register
    ANDI    R22,0XF0    ; Clear lower nibble

    SBRC    R25,1           ; Check 4-bit setup mode flag
    RJMP    READ_STATUS_END ; If cleared, proceed to READ_STATUS_LOW

    ; Get low nibble of address counter
READ_STATUS_LOW:

    SBI     _SFR_IO_ADDR(CNTRL),E     ; Raise Enable
    IN      R16,_SFR_IO_ADDR(DATA)    ; Copy intput pin values
    CBI     _SFR_IO_ADDR(CNTRL),E     ; Lower Enable

    ANDI    R16,0X0F    ; Isolate low nibble
    OR      R22,R16     ; Move low nibble to output register

READ_STATUS_END:

    SBRS    R22,7       ; Check Busy Flag
    CBR     R25,0X08    ; If cleared, output ready
    CBR     R22,0X80    ; Always clear flag in address counter output

    RET ; Return from READ_STATUS


; Name: WRITE_STR
; Descr: Write null-terminated string of characters
;  to LCD display
; Inputs:
;  R30: Low byte of starting address of string
;   (must be program memory)
;  R31: High byte of starting address of string
;   (must be program memory)
WRITE_STR:

    LPM     R23,Z+          ; Load next character of string
    TST     R23             ; AND with all 1s
    BREQ    WRITE_STR_END   ; If null terminator, return
    RCALL   WRITE_DATA      ; Else, write to LCD
    RJMP    WRITE_STR       ; Loop back to WRITE_STR

WRITE_STR_END:

    RET ; Return from WRITE_STR


; Name: WAIT
; Descr: Wait for given amount of time
; Inputs:
;  R24: Interval constant
WAIT:

    ; Store interval constant in output compare register
    OUT     _SFR_IO_ADDR(OCR0A),R24

    ; Clear output compare flag
    SBI     _SFR_IO_ADDR(TIFR0),OCF0A   ; Cleared by writing 1 to location

    ; Reset Timer 0
    CLR     R16
    OUT     _SFR_IO_ADDR(TCNT0),R16

    ; Wait for Timer 0 output compare flag
WAIT_T0:

    SBIS    _SFR_IO_ADDR(TIFR0),OCF0A
    RJMP    WAIT_T0
    
    ; Return
    RET


; END FUNCTIONS

    .global __vector_default
__vector_default:
    reti

    .end
