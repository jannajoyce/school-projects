#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>
#include <stdbool.h>
#include "dht.h"
#include "clap_detection.h"
#include "millis.h"

// Pin Definitions
#define LDR_PIN 0       // Analog pin A0 corresponds to 0 for ATmega328p

extern volatile bool rgbLedState;  // RGB LED state (from clap_detection.c)
extern volatile uint8_t clapCount; // Clap count (from clap_detection.c)

volatile uint32_t millisCount = 0; // Global variable to store milliseconds

// Timer0 Overflow Interrupt Service Routine (ISR)
ISR(TIMER0_OVF_vect) {
    millisCount++;  // Increment millis every overflow (every ~1ms)
}

// Function to initialize Timer0 for millis()
void initMillis() {
    TCCR0A = 0;                // Normal mode
    TCCR0B = (1 << CS00);      // No prescaling, Timer0 runs at full system clock speed
    TIMSK0 = (1 << TOIE0);     // Enable Timer0 overflow interrupt
    sei();                     // Enable global interrupts
}

// Function to get the elapsed time in milliseconds
uint32_t millis() {
    return millisCount;
}

// PWM Setup
void setupPWM() {
    DDRD |= (1 << PD6) | (1 << PD5);  // PWM for Red and Green LEDs
    DDRB |= (1 << PB1);               // PWM for Blue LED

    // Configure Timer0 for Red and Green LEDs (Fast PWM mode)
    TCCR0A |= (1 << WGM00) | (1 << WGM01) | (1 << COM0A1) | (1 << COM0B1);
    TCCR0B |= (1 << CS01) | (1 << CS00); // Prescaler = 64

    // Configure Timer1 for Blue LED (Fast PWM mode)
    TCCR1A |= (1 << WGM10) | (1 << COM1A1);
    TCCR1B |= (1 << CS11) | (1 << CS10) | (1 << WGM12); // Prescaler = 64
}

// Function to set RGB LED brightness
void setBrightness(uint8_t red, uint8_t green, uint8_t blue) {
    OCR0A = red;   // Red LED brightness
    OCR0B = green; // Green LED brightness
    OCR1A = blue;  // Blue LED brightness
}

// Function to read the LDR value
uint16_t readLDR() {
    ADMUX = (1 << REFS0) | (LDR_PIN & 0x0F); // Select analog pin A0 (which is pin 0)
    ADCSRA |= (1 << ADEN) | (1 << ADSC);     // Start conversion
    while (ADCSRA & (1 << ADSC));            // Wait for conversion to finish
    return ADC;
}

int main() {
    // Initialize Timer0 and millis
    initMillis();
    setupPWM();
    initClapDetection();

    uint16_t temperature = 0, humidity = 0;
    uint8_t red = 0, green = 0, blue = 0;

    while (1) {
        // Handle clap detection (toggles RGB LED on/off)
        if (rgbLedState) {
            // Read DHT22 (temperature and humidity)
            if (dht_GetTempUtil(&temperature, &humidity) == 0) {
                float tempC = temperature / 10.0;

                // Determine RGB LED color based on temperature
                if (tempC <= 30.0) {
                    red = 255; green = 0; blue = 0; // Full Red
                } else if (tempC <= 31.25) {
                    red = 128; green = 128; blue = 0; // Half Red, Half Green
                } else if (tempC <= 32.5) {
                    red = 0; green = 255; blue = 0; // Full Green
                } else if (tempC <= 33.75) {
                    red = 0; green = 128; blue = 128; // Half Green, Half Blue
                } else if (tempC <= 35.0) {
                    red = 0; green = 0; blue = 255; // Full Blue
                }
            }

            // Read LDR and adjust brightness
            uint16_t ldrValue = readLDR();
            uint8_t brightness =255-  (ldrValue / 4); // Map 10-bit ADC to 8-bit PWM

            // Apply brightness and color
            setBrightness((red * brightness) / 255, (green * brightness) / 255, (blue * brightness) / 255);
        } else {
            // Turn off RGB LED if clapCount is zero
            setBrightness(0, 0, 0);
        }

        _delay_ms(200); // Delay between readings
    }

    return 0;
}
