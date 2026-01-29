#include "clap_detection.h"
#include "millis.h"

// The rest of your clap_detection.c code


// Globals
volatile uint8_t clapCount = 0; // Number of claps detected
volatile bool rgbLedState = false; // RGB LED state (on/off)

// Initialize external interrupt for clap detection
void initClapDetection() {
    // Set sound sensor pin as input
    DDRD &= ~(1 << SOUND_SENSOR_PIN); // Clear the bit for input
    EICRA |= (1 << ISC00);            // Trigger on any logical change
    EIMSK |= (1 << INT0);             // Enable INT0 interrupt
    sei();                            // Enable global interrupts
}

// External interrupt service routine (ISR)
ISR(INT0_vect) {
    // Debounce: Ignore if time difference is too short
    static uint32_t lastInterruptTime = 0;
    uint32_t currentTime = millis(); // Get current time in milliseconds

    if (currentTime - lastInterruptTime > 200) {
        clapCount++;
        if (clapCount == 2) {
            rgbLedState = !rgbLedState; // Toggle RGB LED state
            clapCount = 0;             // Reset clap count
        }
        lastInterruptTime = currentTime;
    }
}
