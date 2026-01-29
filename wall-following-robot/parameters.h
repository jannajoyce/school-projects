#ifndef PARAMETERS_H
#define PARAMETERS_H

// System Constants
#define WALL_LOST_THRESHOLD 38.1f   // 38.1 cm (15 in, 1.250 ft): Distance to consider wall lost
#define FRONT_CRITICAL_CM   15.0f   // 15.0 cm (5.51 in, ~5 ft): closer than this = too close (critical)
#define FRONT_DETECTED_CM   50.0f   // 30.0 cm (11 in, 0.98 ft): between critical and this = detected, not harmful

#define FRONT_TRIP_CM      14.0f   // ≈3 in → start avoiding
#define FRONT_RELEASE_CM   20.0f  // let it “recover” before clearing block
#define FRONT_CONFIRM_HITS 0      // need N consecutive hits to accept

 // Motor Speed Parameters (0-8 scale)
#define BASE_SPEED          7.0   // Base speed for motors
#define LEFT_BASE_SPEED     5.0   // Base speed for motors
#define TURN_SPEED_right    4.0  // Speed during turns
#define TURN_SPEED_left     3.5  // Speed during turns

 // Timing Constants (milliseconds)
#define SERVO_STABILIZE_TIME    500  // Time to allow servo to reach position
#define TURN_DURATION_right     450   // Time for turning maneuvers
#define TURN_DURATION_left      350   // Time for turning maneuvers
#define TURN_DURATION_leftBack  400   // Time for turning maneuvers

#define CORRECTION_DURATION     300   // Time for wall distance correction
#define LOOP_DELAY              50   // Main loop delay
#define BACKUP_DURATION         220   // ms to reverse before turning left
#define MOVEMENT_DURATION       100   // Default time robot moves per scan cycle
 
 #endif 