#ifndef MOTORS_H
#define MOTORS_H

// Driver pins for motors
#define LEFT_EN     PB3
#define RIGHT_EN    PD3
// after – swap these two
#define LEFT_IN1    PD6
#define LEFT_IN2    PD7
#define RIGHT_IN3   PD5
#define RIGHT_IN4   PD4

// Function prototypes
void setupMotors(void);
void moveForward(int duration_ms, float left_duty, float right_duty);
void moveBackward(int duration_ms, float left_duty, float right_duty);
void motorRightForward(int duration_ms, float duty);
void motorLeftForward(int duration_ms, float duty);
void motorRightBackward(int duration_ms, float duty);
void motorLeftBackward(int duration_ms, float duty);
void stopMotors(void);


#endif