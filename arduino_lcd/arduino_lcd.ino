#include <LiquidCrystal.h>

const int PIN_RS = 1;
const int PIN_RW = 2;
const int PIN_EN = 3;
const int PIN_D4 = 4;
const int PIN_D5 = 5;
const int PIN_D6 = 6;
const int PIN_D7 = 7;

LiquidCrystal lcd(
    PIN_RS,
    PIN_RW,
    PIN_EN,
    PIN_D4,
    PIN_D5,
    PIN_D6,
    PIN_D7
    );

void setup() {
  
  lcd.print("Hello, World!");
}

void loop() {
}