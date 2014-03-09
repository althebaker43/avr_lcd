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

; Display position constants
.SET    LCD_TOP_L,      0x00
.SET    LCD_TOP_R,      0x0F
.SET    LCD_BTM_L,      0x40
.SET    LCD_BTM_R,      0x4F

; Entry auto-shift constants
.SET    LCD_SHFT_R,     0x00
.SET    LCD_SHFT_L,     0x01

; Control line definitions (for Port B)
.SET        CNTRL,PORTB
.SET        RS,PORTB0
.SET        RW,PORTB6
.SET        E,PORTB7
.SET        LCD_FAIL,PORTB3

; Data line definitions (for Port C)
.SET        DATA,PORTC
.SET        DB4,PORTC0
.SET        DB5,PORTC1
.SET        DB6,PORTC2
.SET        DB7,PORTC3
.SET        BF,PORTC3

; END CONSTANTS


; BEGIN GLOBALS

    .section .data

; Flag indicating successful initialization
init_finished:
    .byte   0x00

; Time-out value for LCD communications
time_out:
    .byte   WAIT_2MS

; For avoiding rewrite of labels in LCD_VAR

prev_var_top:
    .word   0x0000

prev_var_btm:
    .word   0x0000

; END GLOBALS

    .section .text

; BEGIN PROGRAM CONSTANTS

; Punctuation table
CH_PUNCT:
    .byte   ' ',    0x20
    .byte   '!',    0x21
    .byte   ',',    0x2C
    .byte   0x00

; (Hex) Number table
CH_NUM:
    .byte   0x00,   '0'
    .byte   0x01,   '1'
    .byte   0x02,   '2'
    .byte   0x03,   '3'
    .byte   0x04,   '4'
    .byte   0x05,   '5'
    .byte   0x06,   '6'
    .byte   0x07,   '7'
    .byte   0x08,   '8'
    .byte   0x09,   '9'
    .byte   0x0A,   'A'
    .byte   0x0B,   'B'
    .byte   0x0C,   'C'
    .byte   0x0D,   'D'
    .byte   0x0E,   'E'
    .byte   0x0F,   'F'
    .byte   0x00,   0x00

; END PROGRAM CONSTANTS


;BEGIN FUNCTIONS

; Name: LCD_INIT
; Descr: Initializes the LCD module
; Inputs:
; Outputs:
    .align 2
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

    ; Set control bits of Port B to output
    ; All outputs are initially low
    LDI     R16,0xC1
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
    ANDI    R16,0X3E
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
    ;  Cursor off
    ;  Cursor not blinking
    LDI     R23,0X0C    ; Display on command
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

    ; Set time-out value to 64us
    LDI     XL,lo8(time_out)
    LDI     XH,hi8(time_out)
    LDI     R16,WAIT_64US
    ST      X,R16

    ; Set "init finished" flag
    LDI     XL,lo8(init_finished)
    LDI     XH,hi8(init_finished)
    LDI     R16,0xFF
    ST      X,R16

    ; Restore registers
    POP     R27
    POP     R26
    POP     R25
    POP     R24
    POP     R23
    POP     R16

    RET ; Return from LCD_INIT


; Name: LCD_STR
; Descr: Write null-terminated string of characters
;  to LCD display
; Inputs:
;  R30: Low byte of starting address of string
;   (must be program memory)
;  R31: High byte of starting address of string
;   (must be program memory)
; Outputs:
;  R15: Size of string (not incl. terminator)
    .align 2
    .global LCD_STR
LCD_STR:

    ; Save registers
    PUSH    R23
    PUSH    R24
    PUSH    R25

LCD_STR_CP:

    LPM     R23,Z+        ; Load next character of string
    TST     R23           ; AND with all 1s
    BREQ    LCD_STR_END   ; If null terminator, return

    CPI     R23,'z'       ; If greater than 'z'
    BRPL    LCD_STR_LUT   ; Look up in table

    CPI     R23,'a'       ; Else if greater than 'a'
    BRPL    LCD_STR_OUT   ; Write out directly

    CPI     R23,'Z'       ; Else if greater than 'Z'
    BRPL    LCD_STR_LUT   ; Look up in table

    CPI     R23,' '       ; Else if greater or equal to ' '
    BRGE    LCD_STR_OUT   ; Write out directly

LCD_STR_LUT:

    ; Save Z register contents
    PUSH    ZL
    PUSH    ZH

    LDI     ZL,lo8(CH_PUNCT)
    LDI     ZH,hi8(CH_PUNCT)

LCD_STR_LUT_LOOP:

    LPM     R24,Z+          ; Load next ASCII character
    LPM     R25,Z+          ; Load next LCD character
    TST     R24             ; If null terminator loaded
    BREQ    LCD_STR_LUT_END ; Branch to end

    CP      R23,R24             ; If does notequals current character
    BRNE    LCD_STR_LUT_LOOP    ; Loop back to LCD_STR_LUT_LOOP

    MOV     R23,R25     ; Else, move LCD character into R23

LCD_STR_LUT_END:

    ; Restore Z register contents
    POP     ZH
    POP     ZL

LCD_STR_OUT:

    RCALL   WRITE_DATA  ; Write character to LCD module
    RJMP    LCD_STR_CP

LCD_STR_END:

    ; Restore registers
    POP     R25
    POP     R24
    POP     R23

    RET ; Return from LCD_STR


; Name: LCD_VAL
; Descr: Displays a byte-sized numerical value
; Inputs:
;  R25[1]: Value format (0 = hex, 1 = decimal)
;  R26: Low byte of variable's address
;   (must be in .data)
;  R27: High byte of variable's address
;   (must be in .data)
LCD_VAL:

    ; Save registers
    PUSH    R16
    PUSH    R21
    PUSH    R22
    PUSH    R23
    PUSH    R24
    PUSH    ZL
    PUSH    ZH

    SBRS    R25,1
    RJMP    LCD_VAL_HEX

LCD_VAL_DEC:

    ; TODO: Implement decimal conversion

    RJMP    LCD_VAL_END

LCD_VAL_HEX:

    ; Set auto-shifting to left
    LDI     R16,LCD_SHFT_L
    RCALL   SET_SHFT

    ; Load value to write
    LD      R21,X

    ; Get low nibble
    MOV     R22,R21
    ANDI    R22,0x0F

    ; Set Z pointer to number-char table
    LDI     ZL,lo8(CH_NUM)
    LDI     ZH,hi8(CH_NUM)

    ; Look up in number table

LCD_VAL_LUT_LO:

    LPM     R24,Z+          ; Load number in R24
    LPM     R23,Z+          ; Load character in R23
    TST     R23             ; Check if character is null
    BREQ    LCD_VAL_SHFTR   ; If so, terminate

    CP      R22,R24         ; Compare numerical values
    BRNE    LCD_VAL_LUT_LO  ; If not equal, loop again
    RCALL   WRITE_DATA      ; Else, write character to display

    ; Get high nibble
    SWAP    R21
    ANDI    R21,0x0F
    
    ; Reset Z-pointer
    LDI     ZL,lo8(CH_NUM)
    LDI     ZH,hi8(CH_NUM)

    ; Look up in number table

LCD_VAL_LUT_HI:

    LPM     R24,Z+          ; Load number in R24
    LPM     R23,Z+          ; Load character in R23
    TST     R23             ; Check if character is null
    BREQ    LCD_VAL_SHFTR   ; If so, terminate

    CP      R21,R24         ; Compare numerical values
    BRNE    LCD_VAL_LUT_HI  ; If not equal, loop again
    RCALL   WRITE_DATA      ; Else, write character to display

LCD_VAL_SHFTR:
    
    ; Set auto-shifting to right
    LDI     R16,LCD_SHFT_R
    RCALL   SET_SHFT

LCD_VAL_END:

    ; Restore registers
    POP     ZH
    POP     ZL
    POP     R24
    POP     R23
    POP     R22
    POP     R21
    POP     R16

    RET 


; Name: LCD_VAR
; Descr: Displays a variable's value (byte-sized)
; Inputs:
;  R25[0]: Display location (0 = top, 1 = bottom)
;  R25[1]: Value format (0 = hex, 1 = decimal)
;  R26: Low byte of variable's address
;   (must be in .data)
;  R27: High byte of variable's address
;   (must be in .data)
;  R30: Low byte of starting address of label
;   (must be program memory)
;  R31: High byte of starting address of label
;   (must be program memory)
    .align 2
    .global LCD_VAR
LCD_VAR:

    ; Save registers
    PUSH    R16

    SBRC    R25,0           ; If R25[0] is set
    RJMP    LCD_VAR_BTM     ; Write to bottom row

LCD_VAR_TOP:

    ; Set LCD address counter to top left
    LDI     R16,LCD_TOP_L
    RCALL   SET_POS 
    
    RJMP    LCD_VAR_LABEL

LCD_VAR_BTM:

    ; Set LCD address counter to bottom left
    LDI     R16,LCD_BTM_L
    RCALL   SET_POS

LCD_VAR_LABEL:

    ; Write out variable label
    RCALL   LCD_STR

LCD_VAR_VAL:

    ; Set cursor opposite of label
    ORI     R16,0x0F
    RCALL   SET_POS

    ; Write out variable value
    RCALL   LCD_VAL

LCD_VAR_END:

    ; Restore registers
    POP     R16

    RET ; Return from LCD_VAR


; Name: SET_POS
; Descr: Sets the cursors position on the LCD
; Inputs:
;  R16[0:3]: Column selection
;  R16[6]: Row selection (0 = top, 1 = bottom)
    .align 2
    .global SET_POS
SET_POS:

    ; Save registers
    PUSH    R23
    PUSH    R25

    LDI     R23,0x80    ; Load command
    OR      R23,R16     ; Load display data RAM address
    CLR     R25
    RCALL   WRITE_CMD   ; Write command to LCD

    ; Restore registers
    POP     R25
    POP     R23

    RET ; Return from SET_POS


; Name: SET_SHFT
; Descr: Sets the entry auto-shifting mode of the LCD
; Inputs:
;  R16[0]: Shift selection (0 = right, 1 = left)
SET_SHFT:

    ; Save registers
    PUSH    R23
    PUSH    R24
    PUSH    R25

    LDI     R23,0x04    ; Load command
    SBRS    R16,0       ; Check shift selection input
    ORI     R23,0x02    ; If cleared, set command bit
    CLR     R25
    RCALL   WRITE_CMD   ; Write command to LCD

    ; Restore registers
    POP     R25
    POP     R24
    POP     R23

    RET ; Return from SET_SHFT


; Name: WRITE_CMD
; Descr: Writes a command to the LCD display
; Inputs:
;  R23 - Command to write
;  R25[0] - Bus width (ignored for now) (0 = 4-bit, 1 = 8-bit)
;  R25[1] - 4-bit setup mode? (0 = no, 1 = yes)
; Outputs:
;  R25[3] - Time-out occurred (0 = no, 1 = yes)
WRITE_CMD:

    ; Save registers
    PUSH    R16
    PUSH    R17
    PUSH    R25
    PUSH    XL
    PUSH    XH

    ; Check initialization flag
    LDI     XL,lo8(init_finished)
    LDI     XH,hi8(init_finished)
    LD      R16,X
    TST     R16
    BREQ    WRITE_CMD_DWIDTH

    ; If requested, wait on busy flag
    RCALL   WAIT_BUSY           ; Else, call WAIT_BUSY
    SBRC    R25,3               ; Check WAIT_BUSY return value
    RJMP    WRITE_CMD_END       ; If set, return from WRITE_CMD

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

    RJMP    WRITE_CMD_END   ; Branch to end

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
    RJMP    WRITE_CMD_LOWR  ; If set, jump to WRITE_CMD_LOWR

    ; Move low byte of command to output port
    MOV     R16,R23
    ORI     R16,0XF0                ; Keep pull-ups enabled on input pins
    OUT     _SFR_IO_ADDR(DATA),R16

    ; Pulse Enable to send
    SBI     _SFR_IO_ADDR(CNTRL),E
    CBI     _SFR_IO_ADDR(CNTRL),E

WRITE_CMD_LOWR:

    ; Drive data pins low
    LDI     R16,0XF0
    OUT     _SFR_IO_ADDR(DATA),R16

WRITE_CMD_END:

    ; Restore registers
    POP     XH
    POP     XL
    POP     R25
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
    PUSH    R25
    PUSH    XL
    PUSH    XH

    ; Check initialization flag
    LDI     XL,lo8(init_finished)
    LDI     XH,hi8(init_finished)
    LD      R16,X
    TST     R16
    BREQ    WRITE_DATA_START

    ; If requested, wait on BF
    RCALL   WAIT_BUSY
    SBRC    R25,3           ; Check WAIT_BUSY return value
    RJMP    WRITE_DATA_END  ; If set, return from WRITE_DATA

WRITE_DATA_START:
    
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

    ; Set time-out value to 64us
    LDI     XL,lo8(time_out)
    LDI     XH,hi8(time_out)
    LDI     R16,WAIT_64US
    ST      X,R16

WRITE_DATA_END:

    ; Restore registers
    POP     XH
    POP     XL
    POP     R25
    POP     R17
    POP     R16

    RET ; Return from WRITE_DATA


; Name: WAIT_BUSY
; Descr: Wait for busy flag
; Inputs:
;  time_out
; Output:
;  R25[3] - Return value (0 = ready, 1 = timed-out)
WAIT_BUSY:

    ; Save registers
    PUSH    R16
    PUSH    R17
    PUSH    R24
    PUSH    XL
    PUSH    XH
    
    ; Load time-out value
    LDI     XL,lo8(time_out)
    LDI     XH,lo8(time_out)
    LD      R24,X               ; Load time-out value

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
    POP     XH
    POP     XL
    POP     R24
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
