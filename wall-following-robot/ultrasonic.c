// ultrasonic.c
#include "ultrasonic.h"
#include "parameters.h"   

volatile uint16_t pc_start;
volatile uint16_t pc_width;

// Set up:
//  - Timer1 Fast-PWM @50 Hz on OC1B (PB2)
//  - PCINT on PC0 for echo edges
void setupUltrasonicInterrupt(void) {
    // ––– Servo PWM (Timer1, OC1B) –––
    DDRB  |=  (1<<SERVO_PIN);
    TCCR1A = (1<<COM1B1)|(1<<WGM11);
    TCCR1B = (1<<WGM13)|(1<<WGM12)|(1<<CS11); 
    ICR1   = 40000;
    OCR1B  = CENTER_POS;

    // ––– Trigger pin = output low –––
    DDRB  |=  (1<<TRIG_PIN);
    PORTB &= ~(1<<TRIG_PIN);

    // ––– Echo pin = input PC0 –––
    DDRC  &= ~(1<<ECHO_PIN);

    // ––– Pin-Change Interrupt on PC0 –––
    PCICR  |= (1<<PCIE1);          // enable PCINT[14:8]
    PCMSK1 |= (1<<ECHO_PIN);       // mask PC0 only
    sei();                         // global interrupts
}

void setupServoPins(void) {
    // (already configured in setupUltrasonicInterrupt,
    DDRB |= (1<<SERVO_PIN);
}

void moveServo(uint16_t pos) {
    OCR1B = pos;
    _delay_ms(SERVO_DELAY);
}

uint16_t getDistanceCm(void) {
    // reset
    pc_start = 0;
    pc_width = 0;
    EIFR     = (1<<PCIF1);         // clear any pending PCINT1

    // fire 10 µs trigger
    PORTB |=  (1<<TRIG_PIN);
    _delay_us(10);
    PORTB &= ~(1<<TRIG_PIN);

    // wait for rising+falling via ISR
    uint32_t t=0;
    while (pc_width==0 && t++ < MEASURE_TIMEOUT) {
        _delay_us(1);
    }
    if (t>=MEASURE_TIMEOUT) return MAX_DISTANCE;

    // convert: tick = prescaler/clk = 8/16MHz = 0.5µs
    float us = pc_width * 0.5f;
    return (uint16_t)(us/58.0f);
}

uint8_t isFrontCritical(void) {
    uint16_t d = getDistanceCm();
    return (d > 0 && d <= (uint16_t)FRONT_TRIP_CM);
}


// Port-Change ISR for PCINT[14:8]
ISR(PCINT1_vect) {
    // only PC0 is unmasked, so this fires on both edges of A0
    if (PINC & (1<<ECHO_PIN)) {
        // rising edge
        pc_start = TCNT1;
    } else {
        // falling edge
        pc_width = TCNT1 - pc_start;
    }
}
