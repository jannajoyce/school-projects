/* ======================= main.c ======================= */
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdbool.h>
#include "ultrasonic.h"
#include "motors.h"
#include "parameters.h"

#define LOOP_INTERVAL_MS 200   // Interval for periodic loop (ms)

volatile uint32_t ms_ticks = 0;
volatile bool     loop_flag = false;
static   uint32_t last_loop = 0;

// Setup second interrupt: Timer0 CTC @ 1kHz → 1ms tick
void setupTimer0Interrupt(void) {
    TCCR0A  = (1<<WGM01);                         // CTC mode
    TCCR0B  = (1<<CS01)|(1<<CS00);                // prescaler = 64
    OCR0A   = F_CPU/64/1000 - 1;                  // 16MHz/64/1000 - 1
    TIMSK0 |= (1<<OCIE0A);                        // enable Compare-Match A
}

// Timer0 ISR: counts ms and flags main loop
ISR(TIMER0_COMPA_vect) {
    ms_ticks++;
    if ((ms_ticks - last_loop) >= LOOP_INTERVAL_MS) {
        last_loop  += LOOP_INTERVAL_MS;
        loop_flag   = true;
    }
}


uint8_t frontBlocked = 0, frontCount = 0;

    uint8_t frontCritical = 0;
    uint8_t frontDetected = 0;
    uint8_t frontClear    = 0;
    uint8_t rightWall     = 0;


int main(void) {
    setupUltrasonicInterrupt();   // sets up PWM + PCINT on A0
    setupServoPins();
    setupMotors();

    setupTimer0Interrupt();       // enable periodic timer interrupt
    sei();                        // globally enable interrupts

    moveServo(CENTER_POS);
    _delay_ms(1000);

    uint8_t frontBlocked = 0, frontCount = 0;

    while (1) {
        // wait for periodic flag
        if (!loop_flag) continue;
        loop_flag = false;

        stopMotors();

        // — Front scan —
        moveServo(CENTER_POS);
        _delay_ms(SERVO_STABILIZE_TIME);
        uint16_t front = getDistanceCm();

        // — Right scan —
        moveServo(RIGHT_POS);
        _delay_ms(SERVO_STABILIZE_TIME);
        uint16_t right = getDistanceCm();

        // — Face forward —
        moveServo(CENTER_POS);
        _delay_ms(50);

        // — Front hysteresis (unchanged) —
        if (!frontBlocked) {
            if (front < FRONT_TRIP_CM && ++frontCount >= FRONT_CONFIRM_HITS) {
                frontBlocked = 1;
                frontCount   = 0;
            }
        } else if (front > FRONT_RELEASE_CM) {
            frontBlocked = 0;
        }

          // — New three‐state front flags —    
        frontCritical = (front < FRONT_CRITICAL_CM);
        frontDetected = (front >= FRONT_CRITICAL_CM 
                         && front < FRONT_DETECTED_CM);
        frontClear    = (front >= FRONT_DETECTED_CM);

        // — Original flag (kept for decision logic) —  
        rightWall = (right < WALL_LOST_THRESHOLD);


        
        if ((frontDetected || rightWall) && !frontCritical) {
            moveForward(MOVEMENT_DURATION, LEFT_BASE_SPEED, BASE_SPEED);
        }

        else if (frontCritical && rightWall) {
            moveBackward(BACKUP_DURATION, LEFT_BASE_SPEED, BASE_SPEED);
            stopMotors(); _delay_ms(30);
            motorRightForward(TURN_DURATION_right, TURN_SPEED_right);
        }

        else if (!rightWall && frontClear) {
            moveForward(MOVEMENT_DURATION, LEFT_BASE_SPEED, BASE_SPEED);
            stopMotors(); _delay_ms(100);
            motorLeftForward(TURN_DURATION_left, TURN_SPEED_left);
            stopMotors(); _delay_ms(500);
            moveForward(MOVEMENT_DURATION, LEFT_BASE_SPEED, BASE_SPEED);
            stopMotors(); _delay_ms(100);
            moveForward(MOVEMENT_DURATION, LEFT_BASE_SPEED, BASE_SPEED);
        }

        else if (!rightWall && frontBlocked) {
            moveBackward(BACKUP_DURATION, LEFT_BASE_SPEED, BASE_SPEED);
            stopMotors(); _delay_ms(100);
            motorLeftForward(TURN_DURATION_leftBack, TURN_SPEED_left);
        }

        // Decision logic
        //     if (!frontBlocked && rightWall) {
        //         moveForward(MOVEMENT_DURATION, BASE_SPEED, BASE_SPEED);
        //     }
        //     else if (frontBlocked && rightWall) {
        //         moveBackward(BACKUP_DURATION, BASE_SPEED, BASE_SPEED);
        //         stopMotors(); _delay_ms(30);
        //         motorRightForward(TURN_DURATION_right, TURN_SPEED_right);
        //     }
        //     else if (frontBlocked && !rightWall) {
        //         moveBackward(BACKUP_DURATION, BASE_SPEED, BASE_SPEED);
        //         stopMotors(); _delay_ms(30);
        //         motorLeftForward(TURN_DURATION_left, TURN_SPEED_left);
        //     }
        //     else if (!frontBlocked && !rightWall){
        //         moveBackward(MOVEMENT_DURATION, BASE_SPEED, BASE_SPEED);
        //     }
        //     else if (!rightWall){
        //         moveForward(MOVEMENT_DURATION, BASE_SPEED, BASE_SPEED);
        //     }

        stopMotors();
        _delay_ms(LOOP_DELAY);
    }

    return 0;
}
