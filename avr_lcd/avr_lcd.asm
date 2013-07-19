/*
 * avr_lcd.asm
 *
 *  Created: 6/5/2013 7:24:35 PM
 *   Author: Allen Baker
 */


// Delay constants
.SET        WAIT_128US = 1
.SET        WAIT_5MS =  78
.SET        WAIT_15MS =	234

// Control line definitions (within Port B)
.SET		CNTRL =		PORTB
.SET		RW =		PORTB0
.SET		RS =		PORTB1
.SET		E =			PORTB2

// Data line definitions (within Port C)
.SET		DATA =		PORTC
.SET		DB4 =		PORTC0
.SET		DB5 =		PORTC1
.SET		DB6 =		PORTC2
.SET		DB7 =		PORTC3
.SET		BF =		PORTC3 


// Set Reset Interrupt vector
.ORG		0x0000
	
	RJMP	RESET


.ORG		0x0034

// Setup stack pointer
RESET:
	LDI		R16,LOW(RAMEND)
	LDI		R17,HIGH(RAMEND)
	OUT		SPL,R16
	OUT		SPH,R17


// Setup Port B
CONFIG_PB:

	// Set pins 0,1, and 2 of Port B to output
	LDI		R16,0x07
	OUT		DDRB,R16


// Setup Port C
CONFIG_PC:

	// Set pins 0, 1, 2, and 3 of Port C to output
	LDI		R16,0x0F
	OUT		DDRC,R16


// Configure Timer 0
CONFIG_T1:
    
    // Disable power reduction for Timer 0
    LDI     XL,LOW(PRR)
    LDI     XH,HIGH(PRR)
    LD      R16,X
    OUT     GPIOR0,R16
    CBI     GPIOR0,PRTIM0
    IN      R16,GPIOR0
    ST      X,R16

	// Disconnect ports 
	// Disable waveform generation
	// Set clock source to internal I/O clock
	// Prescaler set to divide freq. by 64
    CLR     R16
    OUT     TCCR0A,R16
    LDI     R16,0X03
    OUT     TCCR0B,R16

	// Disable all Timer 0 interrupts
	LDI		XL,LOW(TIMSK0)
	LDI		XH,HIGH(TIMSK0)
	CLR		R16
	ST		X,R16


// START OF MAIN PROGRAM
MAIN:

	// Lower Enable
	CBI		CNTRL,E

	// Delay for >15ms
	LDI		R16,WAIT_15MS
	CALL	WAIT

	// Output wakeup #1
	CALL	WAKEUP

	// Delay for >5ms
	LDI		R16,WAIT_5MS
	CALL	WAIT

	// Output wakeup #2
	CALL	WAKEUP

	// Delay for >100us
	LDI		R16,WAIT_128US
	CALL	WAIT

	// Output wakeup #3
	CALL	WAKEUP

	// Delay for >100us
	LDI		R16,WAIT_128US
	CALL	WAIT

	// Function set #1

	// Function set #2

	// Display off

	// Display clear

	// Entry mode set


	RJMP	MAIN

// END OF MAIN PROGRAM

// BEGIN FUNCTIONS

// Name: WRITE_CMD
// Descr: Writes a command to the LCD display
// Inputs:
//  R14 - Command to write
//  R15[0] - Bus width (0 = 4-bit, 1 = 8-bit)
//  R15[1] - 4-bit setup mode? (0 = no, 1 = yes)
//  R15[2] - Wait on Busy Flag? (0 = yes, 1 = no)
//  R25 - Time-out value
// Outputs:
//  R15[2] - Time-out occurred (0 = no, 1 = yes)
WRITE_CMD:

    // If requested, wait on BF
    SBIS    R15,2               // Check wait-busy argument
    RJMP    WRITE_CMD_DWIDTH    // If set, jump to WRITE_CMD_DWIDTH
    CALL    WAIT_BUSY           // Else, call WAIT_BUSY
    SBIC    R15,3               // Check WAIT_BUSY return value
    RET                         // If set, return from WRITE_CMD

WRITE_CMD_DWIDTH:

    SBIS    R15,0           // Check bus width indicator
    RJMP    WRITE_CMD_4BIT  // If set, jump to 4-bit write

WRITE_CMD_8BIT:
    
    // Set all pins on PORTC to output
    LDI     R16,0XFF
    OUT     DDRC,R16

    CBI     CNTRL,RW    // Write operation
    CBI     CNTRL,RS    // Select Instruction Register

    // Move command to output port
    MOV     R16,R14
    OUT     DATA,R16

    // Pulse Enable to send
    SBI     CNTRL,E
    CBI     CNTRL,E

    RET // Return from WRITE_CMD

WRITE_CMD_4BIT:
    
    // Set first four pins on PORTC to output
    // The rest are inputs
    LDI     R16,0X0F
    OUT     DDRC,R16

    // Drive output pins low
    // Enable pull-ups on input pins
    SWAP    R16
    OUT     PORTC,R16

    CBI     CTRL,RW // Clear Read/Write
    CBI     CTRL,RS // Clear Register Select

    // Move high byte of command to output port
    SWAP    R14
    MOV     R16,R14
    ORI     R16,0XF0    // Keep pull-ups enabled on input pins
    OUT     DATA,R16

    // Pulse Enable to send
    CBI     CTRL,E
    SBI     CTRL,E

    SBIC    R15,2   // Check 4-bit setup mode flag
    RET             // If set, return from WRITE_CMD

    // Move low byte of command to output port
    SWAP    R14
    MOV     R16,R14
    ORI     R16,0XF0    // Keep pull-ups enabled on input pins
    OUT     DATA,R16

    // Pulse Enable to send
    CBI     CTRL,E
    SBI     CTRL,E

    RET // Return from WRITE_CMD


// Name: WAIT_BUSY
// Descr: Wait for busy flag
// Inputs:
//  R25 - Timeout value
// Output:
//  R15[3] - Return value (0 = ready, 1 = timed-out)
WAIT_BUSY:

	// Set data pins to input
	LDI     R16,0X0F
	OUT		DDRC,R16
	
    CBI     R15,3   // Set return value to ready

    OUT     OCR0A,R25   // Store interval constant in output compare register
	SBI		TIFR0,OCF0A // Clear output compare flag
    OUT     TCNT0,R17   // Reset Timer 1

    CALL    READ_STATUS // Read busy flag from LCD

READ_BUSY:

    // If BF cleared, branch to happy end
	SBIS	DATA,BF
	RJMP	WAIT_BF_GOOD

    // Else if timeout, branch to fail end
    SBIS    TIFR0,OCF0A
    RJMP    READ_BUSY

WAIT_BF_FAIL:

    LDI     R2,0XFF // Set return value to fail

WAIT_BF_GOOD:

	// Set Port C back to output
	LDI		R16,0x0F
	OUT		DDRC,R16

	RET // Return from WAIT_BUSY


// Name: READ_STATUS
// Descr: Read Busy Flag and Address Counter contents
//  of LCD
// Note: Busy Flag will always be cleared from 
//  Address Counter output register
// Inputs:
// Outputs:
//  R15[4]: Busy flag (0 = ready, 1 = busy)
//  R13[6:0]: Address counter contents
READ_STATUS:

    // Set data pins to input
    LDI     R16,0X0F
    OUT     DDRC,R16

    SBI     R15,4       // Default Busy indicator to busy

    SBI     CNTRL,RW    // Read operation
    CBI     CNTRL,RS    // Select Instruction Register

    // Get high nibble of address counter
	SBI		CNTRL,E     // Raise Enable
    IN      R16,DATA    // Copy input pin values
	CBI		CNTRL,E     // Lower Enable
    
    MOV     R13,R14     // Move values to output register
    SWAP    R13         // Swap nibbles in output register
    ANDI    R13,0XF0    // Clear lower nibble

    // Get low nibble of address counter
	SBI		CNTRL,E     // Raise Enable
    IN      R16,DATA    // Copy intput pin values
    CBI		CNTRL,E     // Lower Enable

    ANDI    R16,0X0F    // Isolate low nibble
    OR      R13,R16     // Move low nibble to output register

    SBIS    R13,7       // Check Busy Flag
    CBI     R15,4       // If cleared, output ready
    CBI     R13,7       // Always clear flag in address counter output

    RET // Return from READ_STATUS


// Name: WAIT
// Descr: Wait for given amount of time
// Inputs:
//  R16: Interval constant
WAIT:
	
	// Store interval constant in output compare register
    OUT     OCR0A,R16

	// Clear output compare flag
	SBI		TIFR0,OCF0A

	// Reset Timer 1
	CLR		R16
    OUT     TCNT0,R16

// Wait for Timer 0 output compare flag
WAIT_T0:

	SBIS	TIFR0,OCF0A
	RJMP	WAIT_T0

	// Return
	RET