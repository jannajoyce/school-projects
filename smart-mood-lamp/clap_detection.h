#ifndef __CLAP_DETECTION_H__
#define __CLAP_DETECTION_H__

#include <stdint.h>
#include <stdbool.h>
#include <avr/io.h>
#include <avr/interrupt.h>

// Pin Definitions
#define SOUND_SENSOR_PIN 2 // Digital pin 2 (INT0)

// Globals (extern means "defined elsewhere")
extern volatile uint8_t clapCount;   // Number of claps detected
extern volatile bool rgbLedState;    // RGB LED state (on/off)

// Function Prototypes
void initClapDetection(void);
void handleClap(void);

#endif // __CLAP_DETECTION_H__
