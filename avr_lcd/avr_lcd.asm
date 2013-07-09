/*
 * avr_lcd.asm
 *
 *  Created: 6/5/2013 7:24:35 PM
 *   Author: Allen Baker
 */


// Delay constants
.SET		DLY_250US =	1
.SET		DLY_5MS =	20
.SET		DLY_15MS =	60

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


// Configure Timer 1
CONFIG_T1:

	// Disable power reduction for Timer 1
	LDI		XL,LOW(PRR)
	LDI		XH,HIGH(PRR)
	LD		R16,X
	OUT		GPIOR0,R16
	CBI		GPIOR0,PRTIM1
	IN		R16,GPIOR00
	ST		X,R16

	// Disconnect ports (normal)
	// Disable waveform generation (normal)
	LDI		XL,LOW(TCCR1A)
	LDI		XH,HIGH(TCCR1A)
	CLR		R16
	ST		X,R16
	
	// Disable waveform generation (normal)
	// Set clock source to internal I/O clock
	// Prescaler set to divide freq. by 256
	LDI		XL,LOW(TCCR1B)
	LDI		XH,HIGH(TCCR1B)
	CLR		R16
	OUT		GPIOR0,R16
	SBI		GPIOR0,CS12
	IN		R16,GPIOR0
	ST		X,R16

	// Disable all Timer 1 interrupts
	LDI		XL,LOW(TIMSK1)
	LDI		XH,HIGH(TIMSK1)
	CLR		R16
	ST		X,R16


// START OF MAIN PROGRAM
MAIN:

	// Lower Enable
	CBI		CNTRL,E

	// Delay for >15ms
	LDI		R16,LOW(DLY_15MS)
	LDI		R17,HIGH(DLY_15MS)
	CALL	DELAY

	// Output wakeup #1
	CALL	WAKEUP

	// Delay for >5ms
	LDI		R16,LOW(DLY_5MS)
	LDI		R17,HIGH(DLY_5MS)
	CALL	DELAY

	// Output wakeup #2
	CALL	WAKEUP

	// Delay for >100us
	LDI		R16,LOW(DLY_250US)
	LDI		R17,HIGH(DLY_250US)
	CALL	DELAY

	// Output wakeup #3
	CALL	WAKEUP

	// Delay for >100us
	LDI		R16,LOW(DLY_250US)
	LDI		R17,HIGH(DLY_250US)
	CALL	DELAY

	// Function set #1

	// Function set #2

	// Display off

	// Display clear

	// Entry mode set


	RJMP	MAIN

// END OF MAIN PROGRAM


// Output wakeup command
WAKEUP:

	CLR		R16
	LDI		R17,0x04
	LDI		R18,0x03
	OUT		CNTRL,R17		// Raise E
	OUT		DATA,R18		// Function set
	OUT		CNTRL,R16		// Lower E
	OUT		DATA,R16		// Lower data lines

	RET


// Set data bus width
SET_DWIDTH:

	CLR		R16
	LDI		R17,0x04
	LDI		R18,0x02
	OUT		CNTRL,R17		// Raise E
	OUT		DATA,R18		// Function set
	OUT		CNTRL,R16		// Lower E
	OUT		DATA,R16		// Lower data lines


// Wait for busy flag
WAIT_BUSY:

	// Set Port C to input
	CLR		R16
	OUT		DDRC,R16

	// Issue read command
READ_BUSY:
	CLR		R16
	CBR		R16,RS
	SBR		R16,RW
	OUT		CNTRL,R16
	SBI		CNTRL,E
	CBI		CNTRL,E
	SBI		CNTRL,E
	CBI		CNTRL,E

	// Loop back if busy flag is high
	SBIC	DATA,BF
	RJMP	READ_BUSY

	// Set Port C back to output
	LDI		R16,0x0F
	OUT		DDRC,R16

	// Return
	RET 


// Delay for given amount of time
// R16: Interval constant (low byte)
// R17: Interval constant (high byte)
DELAY:
	
	// Store interval constant in output compare register
	LDI		XL,LOW(OCR1AH)
	LDI		XH,HIGH(OCR1AH)
	LDI		YL,LOW(OCR1AL)
	LDI		YH,HIGH(OCR1AL)
	ST		X,R17
	ST		Y,R16

	// Clear output compare flag
	SBI		TIFR1,OCF1A

	// Reset Timer 1
	LDI		XL,LOW(TCNT1H)
	LDI		XH,HIGH(TCNT1H)
	LDI		YL,LOW(TCNT1L)
	LDI		YH,HIGH(TCNT1L)
	CLR		R16
	ST		X,R16
	ST		Y,R16


// Wait for Timer 1 output compare flag
WAIT_T1:

	SBIS	TIFR1,OCF1A
	RJMP	WAIT_T1

	// Return
	RET