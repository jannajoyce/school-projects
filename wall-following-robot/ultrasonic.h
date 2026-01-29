// ultrasonic.h
#ifndef ULTRASONIC_H
#define ULTRASONIC_H

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdint.h>

// PORTB bits for Arduino D9,D10
#define TRIG_PIN    PB1   // D9
#define SERVO_PIN   PB2   // D10

// PortC bit for Arduino A0 (PC0)
#define ECHO_PIN    PC0   // A0

// Servo PWM counts
#define CENTER_POS  3000
#define RIGHT_POS   1000
#define LEFT_POS    4800

// Timing
#define SERVO_DELAY      250     // ms
#define MEASURE_TIMEOUT 10000U   // µs
#define MAX_DISTANCE     400     // cm

// ISR state
extern volatile uint16_t pc_start;
extern volatile uint16_t pc_width;

// Init Timer1 for 50 Hz PWM on OC1B (servo),
// plus PCINT for echo timing on PC0.
void setupUltrasonicInterrupt(void);

// Config servo pin only (OC1B)
void setupServoPins(void);

// Trigger + wait (via PCINT) → return cm
uint16_t getDistanceCm(void);

// Move servo (blocks SERVO_DELAY)
void moveServo(uint16_t pos);

#endif // ULTRASONIC_H
