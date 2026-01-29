#include <avr/io.h>
#include <util/delay.h>
#include "motors.h"

/* Duty is 0–10 (int-cast). Adjust everywhere else if you change that scale. */

/* ----------------- Setup ----------------- */
void setupMotors(void) {
    DDRB |= (1 << LEFT_EN);                                    // PB3
    DDRD |= (1 << RIGHT_EN) | (1 << LEFT_IN1) | (1 << LEFT_IN2)
          | (1 << RIGHT_IN3) | (1 << RIGHT_IN4);

    PORTB &= ~(1 << LEFT_EN);
    PORTD &= ~((1 << RIGHT_EN) | (1 << LEFT_IN1) | (1 << LEFT_IN2)
             | (1 << RIGHT_IN3) | (1 << RIGHT_IN4));
}

/* ------------ Single-wheel helpers ------------ */
void motorLeftForward(int duration_ms, float duty){
    PORTD |=  (1 << LEFT_IN1);
    PORTD &= ~(1 << LEFT_IN2);

    int on = (int)duty, off = 10 - on, steps = duration_ms / 10;
    for(int i=0;i<steps;i++){
        PORTB |=  (1 << LEFT_EN);
        _delay_ms(on);
        PORTB &= ~(1 << LEFT_EN);
        _delay_ms(off);
    }
}

void motorRightForward(int duration_ms, float duty){
    PORTD |=  (1 << RIGHT_IN3);
    PORTD &= ~(1 << RIGHT_IN4);

    int on = (int)duty, off = 10 - on, steps = duration_ms / 10;
    for(int i=0;i<steps;i++){
        PORTD |=  (1 << RIGHT_EN);
        _delay_ms(on);
        PORTD &= ~(1 << RIGHT_EN);
        _delay_ms(off);
    }
}

void motorLeftBackward(int duration_ms, float duty){
    PORTD &= ~(1 << LEFT_IN1);
    PORTD |=  (1 << LEFT_IN2);

    int on = (int)duty, off = 10 - on, steps = duration_ms / 10;
    for(int i=0;i<steps;i++){
        PORTB |=  (1 << LEFT_EN);
        _delay_ms(on);
        PORTB &= ~(1 << LEFT_EN);
        _delay_ms(off);
    }
}

void motorRightBackward(int duration_ms, float duty){
    PORTD &= ~(1 << RIGHT_IN3);
    PORTD |=  (1 << RIGHT_IN4);

    int on = (int)duty, off = 10 - on, steps = duration_ms / 10;
    for(int i=0;i<steps;i++){
        PORTD |=  (1 << RIGHT_EN);
        _delay_ms(on);
        PORTD &= ~(1 << RIGHT_EN);
        _delay_ms(off);
    }
}

/* ------------ Both wheels together ------------ */
void moveForward(int duration_ms, float left_duty, float right_duty) {
    // 1) Set both wheels spinning “forward”
    PORTD |=  (1<<LEFT_IN1)  | (1<<RIGHT_IN3);
    PORTD &= ~((1<<LEFT_IN2) | (1<<RIGHT_IN4));

    // 2) Convert your 0–10.0 duty→ 0–10 ticks with rounding
    int onL = (int)(left_duty  + 0.5f);
    int onR = (int)(right_duty + 0.5f);

    // 3) How many full 10 ms PWM cycles we’ll run
    int fullCycles = duration_ms / 10;
    // 4) Remainder if duration_ms isn’t an exact multiple of 10
    int remMs     = duration_ms % 10;

    // — main 10 ms PWM loops —
    for (int c = 0; c < fullCycles; c++) {
        for (int tick = 0; tick < 10; tick++) {
            // left wheel PWM
            if (tick < onL) PORTB |=  (1<<LEFT_EN);
            else            PORTB &= ~(1<<LEFT_EN);
            // right wheel PWM
            if (tick < onR) PORTD |=  (1<<RIGHT_EN);
            else            PORTD &= ~(1<<RIGHT_EN);

            _delay_ms(1);
        }
    }

    // — leftover time (<10 ms) —
    for (int tick = 0; tick < remMs; tick++) {
        if (tick < onL) PORTB |=  (1<<LEFT_EN);
        else            PORTB &= ~(1<<LEFT_EN);
        if (tick < onR) PORTD |=  (1<<RIGHT_EN);
        else            PORTD &= ~(1<<RIGHT_EN);
        _delay_ms(1);
    }

    // 5) Finally, stop both wheels
    PORTB &= ~(1<<LEFT_EN);
    PORTD &= ~(1<<RIGHT_EN);
}

void moveBackward(int duration_ms, float left_duty, float right_duty){
    PORTD &= ~(1 << LEFT_IN1);
    PORTD |=  (1 << LEFT_IN2);
    PORTD &= ~(1 << RIGHT_IN3);
    PORTD |=  (1 << RIGHT_IN4);

    int onL = (int)left_duty,  offL = 10 - onL;
    int onR = (int)right_duty, offR = 10 - onR;
    int steps = duration_ms / 10;

    for(int i=0;i<steps;i++){
        PORTB |=  (1 << LEFT_EN);
        PORTD |=  (1 << RIGHT_EN);
        _delay_ms(onL < onR ? onL : onR);

        if(onL <= onR) PORTB &= ~(1 << LEFT_EN);
        if(onR <= onL) PORTD &= ~(1 << RIGHT_EN);

        _delay_ms(onL > onR ? onL - onR : onR - onL);

        PORTB &= ~(1 << LEFT_EN);
        PORTD &= ~(1 << RIGHT_EN);

        _delay_ms((offL > offR) ? offL : offR);
    }
}



/* ----------------- Stop ----------------- */
void stopMotors(void){
    PORTB &= ~(1 << LEFT_EN);
    PORTD &= ~(1 << RIGHT_EN);
    PORTD &= ~((1 << LEFT_IN1)|(1 << LEFT_IN2)|(1 << RIGHT_IN3)|(1 << RIGHT_IN4));
}
