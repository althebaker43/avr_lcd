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

; Uppercase character offset
.SET        CH_UPCASE_OFSET,0

; Lowercase character offset
.SET        CH_LOWCASE_OFSET,-0x30

; Punctuation
.SET        CH_SPACE,0x20
.SET        CH_EXCL,0x21
.SET        CH_COMMA,0x2C


; END CONSTANTS


; BEGIN GLOBALS


    .section .data


; END GLOBALS


    .section .text

; BEGIN PROGRAM CONSTANTS

; Punctuation table
CH_PUNCT:
    .byte   ' ',    0x20
    .byte   '!',    0x21
    .byte   ',',    0x2C

; END PROGRAM CONSTANTS


;BEGIN FUNCTIONS

; Name: LCD_INIT
; Descr: Initializes the LCD module
; Inputs:
; Outputs:
    .global LCD_INIT
LCD_INIT:

; Save registers

    PUSH    R16
    PUSH    R23
    PUSH    R24
    PUSH    R25
    PUSH    R26
    PUSH    R27

; Setup Port B

    ; Set low nibble of Port B to output
    ; All outputs are initially low
    LDI     R16,0x0F
    OUT     _SFR_IO_ADDR(DDRB),R16

; Setup Port C

    ; Set low nibble of Port C to output
    ; All outputs are initially low
    LDI     R16,0x0F
    OUT     _SFR_IO_ADDR(DDRC),R16

; Configure Timer 0
    
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
    CLR     R16                         ; Clear R16
    OUT     _SFR_IO_ADDR(TCCR0A),R16    ; Clear TCCR0A
    LDI     R16,0X03                    ; Set [0] and [1] in R16
    OUT     _SFR_IO_ADDR(TCCR0B),R16    ; Set [0] and [1] in TCCR0B

    ; Disable all Timer 0 interrupts
    LDI     XL,lo8(TIMSK0)  ; Load low byte of TIMSK0 address into XL
    LDI     XH,hi8(TIMSK0)  ; Load high byte of TIMSK0 address into XH
    CLR     R16             ; Clear R16
    ST      X,R16           ; Clear TIMSK0

; Configure LCD module

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
    LDI     R23,0X0F    ; Display on command
    RCALL   WRITE_CMD
    
    ; Delay for 128 us
    LDI     R24,WAIT_128US
    RCALL   WAIT
    
    ; Display clear
    LDI     R23,0X01    ; Clear display command
    RCALL   WRITE_CMD

    ; Delay for 2 ms
    LDI     R24,WAIT_2MS
    RCALL   WAIT
    
    ; Entry mode set:
    ;  Increment cursor
    ;  Shift display
    LDI     R23,0X06    ; Entry mode command
    RCALL   WRITE_CMD

    ; Delay for 128 us
    LDI     R24,WAIT_128US
    RCALL   WAIT

; Restore registers

    POP     R27
    POP     R26
    POP     R25
    POP     R24
    POP     R23
    POP     R16

    RET ; Return from LCD_INIT


; Name: LCD_WRITE
; Descr: Write null-terminated string of characters
;  to LCD display
; Inputs:
;  R30: Low byte of starting address of string
;   (must be program memory)
;  R31: High byte of starting address of string
;   (must be program memory)
    .global LCD_WRITE
LCD_WRITE:

    LPM     R23,Z+          ; Load next character of string
    TST     R23             ; AND with all 1s
    BREQ    LCD_WRITE_END   ; If null terminator, return
    RCALL   WRITE_DATA      ; Else, write to LCD
    RJMP    LCD_WRITE       ; Loop back to WRITE_STR

LCD_WRITE_END:

    RET ; Return from LCD_WRITE


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

    ; Save registers
    PUSH    R16
    PUSH    R17

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
    ORI     R16,0XF0                ; Keep pull-ups enabled on input pins
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Pulse Enable to send
    SBI     _SFR_IO_ADDR(CNTRL),E
    CBI     _SFR_IO_ADDR(CNTRL),E

WRITE_CMD_END:

    ; Drive data pins low
    LDI     R16,0XF0
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Restore registers
    POP     R17
    POP     R16

    RET ; Return from WRITE_CMD


; Name: WRITE_DATA
; Descr: Writes data to the LCD data RAM,
;  always waits for 128 us afterwards
; Inputs:
;  R23 - Data to write
WRITE_DATA:

    ; Save registers
    PUSH    R16
    PUSH    R17
    
    ; Set first four pins on PORTC to output
    ; The rest are inputs
    LDI     R16,0X0F
    OUT     _SFR_IO_ADDR(DDRC),R16

    ; Enable pull-ups on input pins
    SWAP    R16
    IN      R17,_SFR_IO_ADDR(DATA)
    OR      R17,R16
    OUT     _SFR_IO_ADDR(DATA),R17

    CBI     _SFR_IO_ADDR(CNTRL),RW  ; Clear Read/Write
    SBI     _SFR_IO_ADDR(CNTRL),RS  ; Set Register Select

    ; Move high byte of data to output port
    MOV     R16,R23
    SWAP    R16
    ORI     R16,0XF0                ; Keep pull-ups enabled on input pins
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Pulse Enable to send
    SBI     _SFR_IO_ADDR(CNTRL),E
    CBI     _SFR_IO_ADDR(CNTRL),E

    ; Move low byte of command to output port
    MOV     R16,R23
    ORI     R16,0XF0                ; Keep pull-ups enabled on input pins
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

    ; Restore registers
    POP     R17
    POP     R16

    RET ; Return from WRITE_DATA


; Name: WAIT_BUSY
; Descr: Wait for busy flag
; Inputs:
;  R24 - Timeout value
; Output:
;  R25[3] - Return value (0 = ready, 1 = timed-out)
WAIT_BUSY:

    ; Save registers
    PUSH    R16
    PUSH    R17

    CBR     R25,0X08    ; Set return value to ready

    OUT     _SFR_IO_ADDR(OCR0A),R24     ; Store interval constant 
                                        ;   in output compare register
    SBI     _SFR_IO_ADDR(TIFR0),OCF0A   ; Clear output compare flag
    CLR     R16                         ; Clear R16
    OUT     _SFR_IO_ADDR(TCNT0),R17     ; Reset Timer 0

READ_BUSY:

    RCALL   READ_STATUS     ; Read busy flag from LCD

    SBRS    R25,3           ; Check busy flag
    RJMP    WAIT_BUSY_END   ; If cleared, branch to end

    SBIS    _SFR_IO_ADDR(TIFR0),OCF0A   ; Check timer compare flag
    RJMP    READ_BUSY                   ; If cleared, loop back
    SBR     R25,0X08                    ; Else, set return value to timed-out

WAIT_BUSY_END:

    ; Restore registers
    POP     R17
    POP     R16

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

    ; Save registers
    PUSH    R16

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

    ; Restore registers
    POP     R16

    RET ; Return from READ_STATUS


; Name: WAIT
; Descr: Wait for given amount of time
; Inputs:
;  R24: Interval constant
WAIT:

    ; Save registers
    PUSH    R16

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

    ; Restore registers
    POP     R16
    
    RET ; Return from WAIT


; END FUNCTIONS

    .end
