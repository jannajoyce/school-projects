/*
  * Right_Wall_Following_Robot.ino
  * Maintains 10 inches distance from right wall
  * Turns left IMMEDIATELY when obstacles detected ahead
  * Takes precise measurements with stationary servo
  * Uses gentle speed and adjustment settings
  * IMPROVED: Immediate response to obstacles and conditions
  */

// Pin Definitions
#define LEFT_EN_PIN 11  // PWM pin for left motor enable
#define RIGHT_EN_PIN 3  // PWM pin for right motor enable
#define LEFT_IN1 7      // Left motor direction control 1
#define LEFT_IN2 6      // Left motor direction control 2
#define RIGHT_IN3 5     // Right motor direction control 1
#define RIGHT_IN4 4     // Right motor direction control 2  
#define TRIGGER_PIN 12  // Ultrasonic sensor trigger
#define ECHO_PIN 13     // Ultrasonic sensor echo
#define SERVO_PIN 10    // Servo control pin

// Servo Positions  
#define RIGHT_POS 10    // Servo position for right sensor reading (degrees)
#define CENTER_POS 100  // Center position (degrees)

// System Constants
#define DESIRED_DISTANCE 25.4     // Target distance from wall (10 inches in cm)
#define TOO_CLOSE 15.24            // Distance considered too close (6 inches in cm)
#define DISTANCE_TOLERANCE 3    // Acceptable distance variation (about 2 inches)
#define OBSTACLE_THRESHOLD 25.4   // Distance to consider as obstacle (10 inches in cm)
#define WALL_LOST_THRESHOLD 38.1  // Distance to consider wall lost (14 inches in cm)

// Motor Speed Parameters (0-255) - GENTLE SPEEDS
#define BASE_SPEED 120  // Base speed for motors
#define MAX_SPEED 150   // Maximum motor speed
#define MIN_SPEED 80    // Minimum motor speed
#define TURN_SPEED 120  // Speed during turns

// Timing Constants (milliseconds)
#define SERVO_STABILIZE_TIME 250  // REDUCED time to allow servo to reach position
#define MEASUREMENT_SAMPLES 3     // REDUCED number of measurements to average
#define SAMPLE_DELAY 25           // REDUCED delay between samples
#define TURN_DURATION 300         // Time for turning maneuvers
#define CORRECTION_DURATION 200   // Time for wall distance correction
#define LOOP_DELAY 100            // Main loop delay

// ADJUSTABLE MOVEMENT PARAMETERS
#define MOVEMENT_DURATION 200     // Default time robot moves per scan cycle (lower = less movement)
#define CORRECTION_MOVE_TIME 150  // Movement time during corrections

// Robot States
enum RobotState {
  STATE_CHECK_FRONT,  // First check front for obstacles
  STATE_CHECK_RIGHT,  // Then check right for wall distance
  STATE_NORMAL,       // Normal wall following
  STATE_TURNING,      // Turning to avoid obstacle
  STATE_TOO_CLOSE,    // Too close to wall
  STATE_WALL_LOST     // Lost the wall
};

// Function Prototypes
float measureDistance();
float takePreciseMeasurement();
void moveForward(int leftSpeed, int rightSpeed);
void moveBackward(int leftSpeed, int rightSpeed);
void turnLeft(int speed);
void turnRight(int speed);
void stopMotors();
void correctFromWall();
void findWall();
RobotState determineState(float frontDistance, float rightDistance);
RobotState checkFrontForObstacle(float frontDistance);

// Global variables
#include <Servo.h>
Servo headServo;
RobotState currentState = STATE_CHECK_FRONT;
float previousError = 0;  // To track previous error for smoother transitions
float frontDistance = 0;
float rightDistance = 0;

// Adjustable movement parameters
int movementDuration = MOVEMENT_DURATION;  // Can be modified via serial commands

void setup() {
  // Initialize Serial (for debugging)
  Serial.begin(9600);

  // Initialize motor control pins
  pinMode(LEFT_EN_PIN, OUTPUT);
  pinMode(RIGHT_EN_PIN, OUTPUT);
  pinMode(LEFT_IN1, OUTPUT);
  pinMode(LEFT_IN2, OUTPUT);
  pinMode(RIGHT_IN3, OUTPUT);
  pinMode(RIGHT_IN4, OUTPUT);

  // Initialize ultrasonic sensor pins
  pinMode(TRIGGER_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  // Initialize and center servo
  headServo.attach(SERVO_PIN);
  headServo.write(CENTER_POS);
  delay(1000);  // Allow servo to reach position

  Serial.println("Right Wall Following Robot Initialized");
  Serial.println("Movement duration set to: " + String(movementDuration) + "ms");
  Serial.println("Send 'M:value' to adjust movement duration (e.g. 'M:150')");

  // Stop motors to ensure we start from a known state
  stopMotors();
  delay(500);
}

void loop() {
  // Check for serial commands to adjust movement duration
  checkSerialCommands();

  // IMPROVED STATE MACHINE FOR IMMEDIATE RESPONSE
  switch (currentState) {
    case STATE_CHECK_FRONT:
      // First, always check for obstacles ahead
      stopMotors();
      headServo.write(CENTER_POS);
      delay(SERVO_STABILIZE_TIME);
      frontDistance = takePreciseMeasurement();
      Serial.print("Front distance: ");
      Serial.print(frontDistance);
      Serial.println(" cm");

      // IMMEDIATELY turn if obstacle detected - no waiting for full scan cycle
      if (frontDistance < OBSTACLE_THRESHOLD) {
        Serial.println("OBSTACLE DETECTED - Immediate avoidance");
        avoidObstacle();
        // After avoiding, go back to checking front again
        currentState = STATE_CHECK_FRONT;
      } else {
        // If no obstacle, proceed to check wall distance
        currentState = STATE_CHECK_RIGHT;
      }
      break;

    case STATE_CHECK_RIGHT:
      // Check right distance for wall following
      headServo.write(RIGHT_POS);
      delay(SERVO_STABILIZE_TIME);
      rightDistance = takePreciseMeasurement();
      Serial.print("Right distance: ");
      Serial.print(rightDistance);
      Serial.println(" cm");

      // Return to forward-facing position
      headServo.write(CENTER_POS);
      delay(SERVO_STABILIZE_TIME / 2);  // Shorter wait

      // Handle immediate responses for wall distance issues
      if (rightDistance < TOO_CLOSE) {
        Serial.println("TOO CLOSE TO WALL - Immediate correction");
        correctFromWall();
        currentState = STATE_CHECK_FRONT;  // Go back to checking front
      } else if (rightDistance > WALL_LOST_THRESHOLD) {
        Serial.println("WALL LOST - Finding wall");
        findWall();
        currentState = STATE_CHECK_FRONT;  // Go back to checking front
      } else {
        // Normal wall following
        Serial.println("NORMAL - Following wall");
        followWall(rightDistance);
        currentState = STATE_CHECK_FRONT;  // Go back to checking front
      }
      break;

    // These states are now handled inline for immediate response
    case STATE_NORMAL:
    case STATE_TURNING:
    case STATE_TOO_CLOSE:
    case STATE_WALL_LOST:
      // Safety fallback - shouldn't reach here with new structure
      currentState = STATE_CHECK_FRONT;
      break;
  }

  delay(LOOP_DELAY);
}

// Check for serial commands to adjust movement parameters
void checkSerialCommands() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');

    // Check for movement duration adjustment command (M:value)
    if (command.startsWith("M:")) {
      int newDuration = command.substring(2).toInt();
      if (newDuration >= 50 && newDuration <= 1000) {
        movementDuration = newDuration;
        Serial.println("Movement duration set to: " + String(movementDuration) + "ms");
      } else {
        Serial.println("Invalid duration. Use value between 50-1000ms");
      }
    }
  }
}

// Take multiple measurements and average them for precision
float takePreciseMeasurement() {
  float total = 0;
  int validSamples = 0;

  for (int i = 0; i < MEASUREMENT_SAMPLES; i++) {
    float distance = measureDistance();
    if (distance > 0 && distance < 400) {  // Filter invalid readings
      total += distance;
      validSamples++;
    }
    delay(SAMPLE_DELAY);
  }

  if (validSamples > 0) {
    return total / validSamples;
  } else {
    return 100;  // Default value if no valid samples
  }
}

// Single distance measurement
float measureDistance() {
  digitalWrite(TRIGGER_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIGGER_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIGGER_PIN, LOW);

  // Measure pulse duration and convert to distance
  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 30000);  // Timeout after 30ms

  if (duration == 0) {
    return 400;  // Return a large value if timeout occurred
  }

  // Convert pulse duration to distance in cm (sound speed = 340 m/s)
  float distance = duration * 0.034 / 2;

  // Filter out unrealistic values
  return (distance > 400) ? 400 : distance;
}

// Follow wall with improved proportional control for smoother movement
void followWall(float rightDistance) {
  // Calculate error (difference from desired distance)
  float error = rightDistance - DESIRED_DISTANCE;

  // Smooth the error using exponential moving average for even smoother transitions
  float smoothedError = 0.5 * error + 0.5 * previousError;
  previousError = smoothedError;  // Store smoothed error for next iteration

  // More gentle proportional control with reduced gain
  int speedAdjustment = constrain(smoothedError * 0.6, -10, 10);  // REDUCED adjustment range

  int leftSpeed = BASE_SPEED - speedAdjustment;
  int rightSpeed = BASE_SPEED + speedAdjustment;

  // Constrain speeds to safe values
  leftSpeed = constrain(leftSpeed, MIN_SPEED, MAX_SPEED);
  rightSpeed = constrain(rightSpeed, MIN_SPEED, MAX_SPEED);

  Serial.print("Error: ");
  Serial.print(error);
  Serial.print(" | Smoothed: ");
  Serial.print(smoothedError);
  Serial.print(" | Left speed: ");
  Serial.print(leftSpeed);
  Serial.print(" | Right speed: ");
  Serial.print(rightSpeed);
  Serial.print(" | Movement: ");
  Serial.println(movementDuration);

  // Move forward with adjusted speeds
  moveForward(leftSpeed, rightSpeed);
  delay(movementDuration);  // USING ADJUSTABLE PARAMETER
  stopMotors();             // Stop to prepare for next scan
}

// Handle case when robot is too close to wall - MORE GENTLE
void correctFromWall() {
  Serial.println("Correcting distance - gently moving away from wall");

  // Gentle turn left to move away from wall
  digitalWrite(LEFT_IN1, LOW);
  digitalWrite(LEFT_IN2, HIGH);
  digitalWrite(RIGHT_IN3, HIGH);
  digitalWrite(RIGHT_IN4, LOW);

  // REDUCED speeds for gentler correction
  analogWrite(LEFT_EN_PIN, MIN_SPEED);
  analogWrite(RIGHT_EN_PIN, MIN_SPEED + 5);  // REDUCED difference

  delay(CORRECTION_MOVE_TIME);  // Using shorter adjustment movement time
  stopMotors();
}

// Handle obstacle avoidance - Only turn, no backup
void avoidObstacle() {
  // Turn left to avoid obstacle - smooth and deliberate
  turnLeft(MIN_SPEED + 8);  // Slightly increased speed for more decisive turn
  delay(TURN_DURATION);     // Full turn duration for proper clearance
  stopMotors();
  delay(50);  // Short pause

  // Move forward slightly to clear the obstacle
  moveForward(MIN_SPEED, MIN_SPEED);
  delay(CORRECTION_MOVE_TIME);
  stopMotors();
}

// Handle case when wall is lost - MORE GENTLE
void findWall() {
  // Very gentle turn right to find the wall again
  turnRight(MIN_SPEED + 5);
  delay(CORRECTION_MOVE_TIME);  // REDUCED turning time
  stopMotors();
  delay(50);  // Shorter pause

  // Move forward slowly to approach wall
  moveForward(MIN_SPEED, MIN_SPEED);
  delay(CORRECTION_MOVE_TIME);  // REDUCED forward time
  stopMotors();

  // Add an additional forward step after correction
  delay(100);                                   // Brief pause before the additional forward movement
  moveForward(MIN_SPEED + 10, MIN_SPEED + 10);  // Slightly faster forward movement
  delay(200);                                   // Move forward for 200ms
  stopMotors();
}

// Set motor directions and speeds for forward movement
void moveForward(int leftSpeed, int rightSpeed) {
  // Set direction pins
  digitalWrite(LEFT_IN1, HIGH);
  digitalWrite(LEFT_IN2, LOW);
  digitalWrite(RIGHT_IN3, HIGH);
  digitalWrite(RIGHT_IN4, LOW);

  // Set speeds
  analogWrite(LEFT_EN_PIN, leftSpeed);
  analogWrite(RIGHT_EN_PIN, rightSpeed);
}

// Set motor directions and speeds for backward movement
void moveBackward(int leftSpeed, int rightSpeed) {
  // Set direction pins
  digitalWrite(LEFT_IN1, LOW);
  digitalWrite(LEFT_IN2, HIGH);
  digitalWrite(RIGHT_IN3, LOW);
  digitalWrite(RIGHT_IN4, HIGH);

  // Set speeds
  analogWrite(LEFT_EN_PIN, leftSpeed);
  analogWrite(RIGHT_EN_PIN, rightSpeed);
}

// Turn left (right motor forward, left motor backward)
void turnLeft(int speed) {
  digitalWrite(LEFT_IN1, LOW);
  digitalWrite(LEFT_IN2, HIGH);
  digitalWrite(RIGHT_IN3, HIGH);
  digitalWrite(RIGHT_IN4, LOW);

  analogWrite(LEFT_EN_PIN, speed);
  analogWrite(RIGHT_EN_PIN, speed);
}

// Turn right (left motor forward, right motor backward)
void turnRight(int speed) {
  digitalWrite(LEFT_IN1, HIGH);
  digitalWrite(LEFT_IN2, LOW);
  digitalWrite(RIGHT_IN3, LOW);
  digitalWrite(RIGHT_IN4, HIGH);

  analogWrite(LEFT_EN_PIN, speed);
  analogWrite(RIGHT_EN_PIN, speed);
}

// Stop all motors
void stopMotors() {
  digitalWrite(LEFT_IN1, LOW);
  digitalWrite(LEFT_IN2, LOW);
  digitalWrite(RIGHT_IN3, LOW);
  digitalWrite(RIGHT_IN4, LOW);

  analogWrite(LEFT_EN_PIN, 0);
  analogWrite(RIGHT_EN_PIN, 0);
}