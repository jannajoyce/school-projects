#define ledPinF 8
#define ledPinB 9
#define ledPinR 4
#define ledPinL 5
int state = 0;
void setup() {
pinMode(ledPinF, OUTPUT);
pinMode(ledPinB, OUTPUT);
pinMode(ledPinR, OUTPUT);
pinMode(ledPinL, OUTPUT);
digitalWrite(ledPinF, LOW);
digitalWrite(ledPinB, LOW);
digitalWrite(ledPinR, LOW);
digitalWrite(ledPinL, LOW);
Serial.begin(9600);
}
void loop() {
if (Serial.available() > 0) {
state = Serial.read();
Serial.print("Received: ");
Serial.println(state);
}
if (state == '1') {
digitalWrite(ledPinF, HIGH);
digitalWrite(ledPinB, LOW);
digitalWrite(ledPinR, LOW);
digitalWrite(ledPinL, LOW);
Serial.println("Forward LED on");
}

else if (state == '2') {
digitalWrite(ledPinF, LOW);
digitalWrite(ledPinB, HIGH);
digitalWrite(ledPinR, LOW);
digitalWrite(ledPinL, LOW);
Serial.println("Backward LED on");
}
else if (state == '3') {
digitalWrite(ledPinF, LOW);
digitalWrite(ledPinB, LOW);
digitalWrite(ledPinR, HIGH);
digitalWrite(ledPinL, LOW);
Serial.println("Right LED on");
}
else if (state == '4') {
digitalWrite(ledPinF, LOW);
digitalWrite(ledPinB, LOW);
digitalWrite(ledPinR, LOW);
digitalWrite(ledPinL, HIGH);
Serial.println("Left LED on");
}
else if (state == '0') {
digitalWrite(ledPinF, LOW);
digitalWrite(ledPinB, LOW);
digitalWrite(ledPinR, LOW);
digitalWrite(ledPinL, LOW);
Serial.println("All LEDs off");
}
state = 0; // Reset state after processing
}