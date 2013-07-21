/*
 * avr_lcd.asm
 *
 *  Created: 6/5/2013 7:24:35 PM
 *   Author: Allen Baker
 */


// BEGIN CONSTANTS


// Delay constants
.SET        WAIT_64US = 0
.SET        WAIT_128US = 1
.SET        WAIT_2MS = 31
.SET        WAIT_5MS =  78
.SET        WAIT_15MS =	234

// Control line definitions (for Port B)
.SET		CNTRL =		PORTB
.SET		RW =		PORTB0
.SET		RS =		PORTB1
.SET		E =			PORTB2
.SET        LCD_FAIL =  PORTB3

// Data line definitions (for Port C)
.SET		DATA =		PORTC
.SET		DB4 =		PORTC0
.SET		DB5 =		PORTC1
.SET		DB6 =		PORTC2
.SET		DB7 =		PORTC3
.SET		BF =		PORTC3 


// END CONSTANTS


// Set Reset Interrupt vector
.ORG		0x0000
	
	RJMP	RESET


// BEGIN MAIN PROGRAM


.ORG		0x0034

// Setup stack pointer
RESET:
	LDI		R16,LOW(RAMEND)
	LDI		R17,HIGH(RAMEND)
	OUT		SPL,R16
	OUT		SPH,R17

// Setup Port B
CONFIG_PORTB:

	// Set low nibble of Port B to output
    // All outputs are initially low
	LDI		R16,0x0F
	OUT		DDRB,R16

// Setup Port C
CONFIG_PORTC:

	// Set low nibble of Port C to output
    // All outputs are initially low
	LDI		R16,0x0F
	OUT		DDRC,R16

// Configure Timer 0
CONFIG_T0:
    
    // Disable power reduction for Timer 0
    // PRR: Power Reduction Register
    LDI     XL,LOW(PRR)     // Move low byte of PRR into XL
    LDI     XH,HIGH(PRR)    // Move high byte of PRR into XH
    LD      R16,X           // Load PRR contents into R16
    CBR     R16,0X20        // Clear Timer 0 bit
    ST      X,R16           // Store new flags into PRR

	// Disconnect ports 
	// Disable waveform generation
	// Set clock source to internal I/O clock
	// Prescaler set to divide freq. by 64
    CLR     R16         // Clear R16
    OUT     TCCR0A,R16  // Clear TCCR0A
    LDI     R16,0X03    // Set [0] and [1] in R16
    OUT     TCCR0B,R16  // Set [0] and [1] in TCCR0B

	// Disable all Timer 0 interrupts
	LDI		XL,LOW(TIMSK0)  // Load low byte of TIMSK0 address into XL
	LDI		XH,HIGH(TIMSK0) // Load high byte of TIMSK0 address into XH
	CLR		R16             // Clear R16
	ST		X,R16           // Clear TIMSK0

CONFIG_LCD:

    // Drive all data lines low
    LDI     R16,0XF0
    OUT     DATA,R16
    SWAP    R16
    OUT     DDRC,R16

    // Drive all control lines low (except for LCD_FAIL)
    IN      R16,CNTRL
    ANDI    R16,0XF8
    OUT     CNTRL,R16

	// Delay for >40ms after power-up
    //  (busy flag unavailable)
	LDI		R25,WAIT_15MS
	CALL	WAIT    // 15 ms 
	CALL	WAIT    // 30 ms
	CALL	WAIT    // 45 ms

	// Output wakeup
    LDI     R23,0X30    // Function set: 8-bit bus width (not really)
    CBR     R25,0X01    // 4-bit bus width
    SBR     R25,0X02    // 4-bit setup mode
    SBR     R25,0X04    // Do not wait on busy flag
	CALL	WRITE_CMD

	// Delay for >5ms (busy flag unavailable)
	LDI		R24,WAIT_5MS
	CALL	WAIT

    // Function set #1:
    //  4-bit bus width
    //  2-line display
    //  5x8 dot character resolution
    LDI     R23,0X28
    CBR     R25,0X02    // Disable 4-bit setup mode
	CALL	WRITE_CMD

	// Delay for >100us
	LDI		R24,WAIT_128US
	CALL	WAIT

	// Output function set #2
	CALL	WRITE_CMD

	// Delay for >100us
	CALL	WAIT

	// Display off
LCD_OFF:
    LDI     R23,0X08        // Display off command
    CBR     R25,0X04        // Wait on BF
    LDI     R24,WAIT_2MS    // Time out after 2 ms
    CALL    WRITE_CMD
    SBRS    R25,3           // Check time-out flag
    RJMP    LCD_CLEAR       // If cleared, proceed to next stage
    SBI     CNTRL,LCD_FAIL  // Else, turn on LCD setup failure indicator
    RJMP    CONFIG_LCD      // Loop back to CONFIG_LCD

	// Display clear
LCD_CLEAR:
    LDI     R23,0X01        // Clear display command
    CALL    WRITE_CMD
    SBRS    R25,3           // Check time-out flag
    RJMP    LCD_ENTRY       // If cleared, proceed to next stage
    SBI     CNTRL,LCD_FAIL  // Else, turn on LCD setup failure indicator
    RJMP    CONFIG_LCD      // Loop back to CONFIG_LCD

	// Entry mode set:
    //  Increment cursor
    //  Shift display
LCD_ENTRY:
    LDI     R23,0X07        // Entry mode command
    CALL    WRITE_CMD
    SBRS    R25,3           // Check time-out flag
    RJMP    LCD_ON          // If cleared, proceed to next stage
    SBI     CNTRL,LCD_FAIL  // Else, turn on LCD setup failiure indicator
    RJMP    CONFIG_LCD      // Loop back to CONFIG_LCD

    // Turn on LCD:
    //  Cursor on
    //  Cursor blinking
LCD_ON:
    LDI     R23,0X0F        // Display on command
    CALL    WRITE_CMD
    SBRS    R25,3           // Check time-out flag
    RJMP    MAIN            // If cleared, proceed to next stage
    SBI     CNTRL,LCD_FAIL  // Else, turn on LCD setup failiure indicator
    RJMP    CONFIG_LCD      // Loop back to CONFIG_LCD

MAIN:

	RJMP	MAIN    // Loop back to MAIN


// END OF MAIN PROGRAM

// BEGIN FUNCTIONS


// Name: WRITE_CMD
// Descr: Writes a command to the LCD display
// Inputs:
//  R23 - Command to write
//  R24 - Time-out value
//  R25[0] - Bus width (ignored for now) (0 = 4-bit, 1 = 8-bit)
//  R25[1] - 4-bit setup mode? (0 = no, 1 = yes)
//  R25[2] - Wait on Busy Flag? (0 = yes, 1 = no)
// Outputs:
//  R25[3] - Time-out occurred (0 = no, 1 = yes)
WRITE_CMD:

    // If requested, wait on BF
    SBRC    R25,2               // Check wait-busy argument
    RJMP    WRITE_CMD_DWIDTH    // If set, jump to WRITE_CMD_DWIDTH
    CALL    WAIT_BUSY           // Else, call WAIT_BUSY
    SBRC    R25,3               // Check WAIT_BUSY return value
    RET                         // If set, return from WRITE_CMD

WRITE_CMD_DWIDTH:

    //SBRS    R25,0           // Check bus width indicator
    RJMP    WRITE_CMD_4BIT  // If set, jump to 4-bit write

WRITE_CMD_8BIT:
    
    // Set all pins on PORTC to output
    LDI     R16,0XFF
    OUT     DDRC,R16

    CBI     CNTRL,RW    // Write operation
    CBI     CNTRL,RS    // Select Instruction Register

    // Move command to output port
    OUT     DATA,R23

    // Pulse Enable to send
    SBI     CNTRL,E
    CBI     CNTRL,E

    // Drive data pins low
    CLR     R16
    OUT     DATA,R16

    RET // Return from WRITE_CMD

WRITE_CMD_4BIT:
    
    // Set first four pins on PORTC to output
    // The rest are inputs
    LDI     R16,0X0F
    OUT     DDRC,R16

    // Enable pull-ups on input pins
    SWAP    R16
    IN      R17,DATA
    OR      R17,R16
    OUT     DATA,R17

    CBI     CNTRL,RW    // Clear Read/Write
    CBI     CNTRL,RS    // Clear Register Select

    // Move high byte of command to output port
    MOV     R16,R23
    SWAP    R16
    ORI     R16,0XF0    // Keep pull-ups enabled on input pins
    OUT     DATA,R16

    // Pulse Enable to send
    SBI     CNTRL,E
    CBI     CNTRL,E

    SBRC    R25,1           // Check 4-bit setup mode flag
    RJMP    WRITE_CMD_END   // If set, jump to WRITE_CMD_END

    // Move low byte of command to output port
    MOV     R16,R23
    ORI     R16,0XF0    // Keep pull-ups enabled on input pins
    OUT     DATA,R16

    // Pulse Enable to send
    SBI     CNTRL,E
    CBI     CNTRL,E

WRITE_CMD_END:

    // Drive data pins low
    LDI     R16,0XF0
    OUT     DATA,R16

    RET // Return from WRITE_CMD


// Name: WAIT_BUSY
// Descr: Wait for busy flag
// Inputs:
//  R24 - Timeout value
// Output:
//  R25[3] - Return value (0 = ready, 1 = timed-out)
WAIT_BUSY:
	
    CBR     R25,0X08        // Set return value to ready

    OUT     OCR0A,R24       // Store interval constant in output compare register
	SBI		TIFR0,OCF0A     // Clear output compare flag
    CLR     R16             // Clear R16
    OUT     TCNT0,R17       // Reset Timer 0

READ_BUSY:

    CALL    READ_STATUS     // Read busy flag from LCD

	SBRS	R25,3           // Check busy flag
	RJMP	WAIT_BUSY_END   // If cleared, branch to end

    SBIS    TIFR0,OCF0A     // Check timer compare flag
    RJMP    READ_BUSY       // If cleared, loop back
    SBR     R25,0X08        // Else, set return value to timed-out

WAIT_BUSY_END:

	RET // Return from WAIT_BUSY


// Name: READ_STATUS
// Descr: Read Busy Flag and Address Counter contents
//  of LCD
// Note: Busy Flag will always be cleared from 
//  Address Counter output register
// Inputs:
//  R25[1]: 4-bit setup mode? (0 = no, 1 = yes)
// Outputs:
//  R25[3]: Busy flag (0 = ready, 1 = busy)
//  R22[6:0]: Address counter contents
READ_STATUS:

    // Set data pins to input (pull-ups disabled)
    CLR     R16
    OUT     DDRC,R16

    SBR     R25,0X08    // Default Busy indicator to busy

    SBI     CNTRL,RW    // Read operation
    CBI     CNTRL,RS    // Select Instruction Register

    // Get high nibble of address counter
READ_STATUS_HI:

	SBI		CNTRL,E     // Raise Enable
    IN      R22,DATA    // Copy input pin values
	CBI		CNTRL,E     // Lower Enable
    
    SWAP    R22         // Swap nibbles in output register
    ANDI    R22,0XF0    // Clear lower nibble

    SBRC    R25,1           // Check 4-bit setup mode flag
    RJMP    READ_STATUS_END // If cleared, proceed to READ_STATUS_LOW

    // Get low nibble of address counter
READ_STATUS_LOW:

	SBI		CNTRL,E     // Raise Enable
    IN      R16,DATA    // Copy intput pin values
    CBI		CNTRL,E     // Lower Enable

    ANDI    R16,0X0F    // Isolate low nibble
    OR      R22,R16     // Move low nibble to output register

READ_STATUS_END:

    SBRS    R22,7       // Check Busy Flag
    CBR     R25,0X08    // If cleared, output ready
    CBR     R22,0X80    // Always clear flag in address counter output

    RET // Return from READ_STATUS


// Name: WAIT
// Descr: Wait for given amount of time
// Inputs:
//  R24: Interval constant
WAIT:
	
	// Store interval constant in output compare register
    OUT     OCR0A,R24

	// Clear output compare flag
	SBI		TIFR0,OCF0A

	// Reset Timer 0
	CLR		R16
    OUT     TCNT0,R16

// Wait for Timer 0 output compare flag
WAIT_T0:

	SBIS	TIFR0,OCF0A
	RJMP	WAIT_T0

	// Return
	RET


// END FUNCTIONS