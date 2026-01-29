#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "ACS712.h"
#include "EmonLib.h"
#include <SoftwareSerial.h>
#include <MFRC522.h>

#define VOLT_CAL 592
#define BUZZER_PIN 8
#define RELAY_PIN 3
#define RFID_TIMEOUT 5000

ACS712 currentSensor1(ACS712_05B, A0);
ACS712 currentSensor2(ACS712_05B, A1);
EnergyMonitor voltageSensor1, voltageSensor2;
SoftwareSerial sim(4, 5);
#define RST_PIN 9
#define SS_PIN 10
MFRC522 mfrc522(SS_PIN, RST_PIN);
bool relayActivated = false;
bool rfidDetected = false;
unsigned long rfidTimeoutStart = 0;
bool access = false;
// Initialize the LCD object
LiquidCrystal_I2C lcd(0x27, 16, 2); // Set the LCD address and dimensions (16x2)

String incomingMessage = ""; // Global variable to store the incoming message
String message = "Waiting for activation";
int scrollIndex = 0;

void setup() {
  Serial.begin(9600);
  delay(7000);
  sim.begin(9600);
  delay(1000);
  currentSensor1.calibrate();
  currentSensor2.calibrate();
  voltageSensor1.voltage(2, VOLT_CAL, 1.7);
  voltageSensor2.voltage(3, VOLT_CAL, 1.7);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  SPI.begin();
  mfrc522.PCD_Init();
 
  // Initialize the LCD
  lcd.init();
  lcd.backlight(); // Turn on backlight

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("System is on");
  delay(5000);

  // Set SMS text mode
  sim.println("AT+CMGF=1");
  delay(1000);
  // Configure SIM module to show new SMS notifications
  sim.println("AT+CNMI=1,2,0,0,0");
  delay(1000);
}

void loop() {
  float current1 = currentSensor1.getCurrentAC();
  float current2 = currentSensor2.getCurrentAC();
  voltageSensor1.calcVI(25, 1000);
  voltageSensor2.calcVI(25, 1000);
  float supplyVoltage1 = voltageSensor1.Vrms;
  float supplyVoltage2 = voltageSensor2.Vrms;
  float percentageError = abs((current1 - current2) / current2) * 100;
  bool theftDetected = false;
 
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("System is on");
 
  if (current1 <= 0.06 && current2 <= 0.06) {
    theftDetected = false;
  } else if (supplyVoltage1 <= 100 && supplyVoltage2 <= 100) {
    theftDetected = false;
  } else if (percentageError < 27) {
    theftDetected = false;
  } else if (percentageError >= 27) {
    theftDetected = true;
  } else if (percentageError > 27 && supplyVoltage2 >= 100) {
    theftDetected = false;
  } else {
    theftDetected = true;
  }

  float totalPower = current1 * supplyVoltage1;

  if (theftDetected && !relayActivated) {
    Serial.println("Theft Detected!");
    digitalWrite(BUZZER_PIN, HIGH);
    delay(500);
    digitalWrite(BUZZER_PIN, LOW);
    sendSMS("+639979258101", "Theft Detected!");
    relayActivated = true;
    rfidTimeoutStart = millis();
    rfidDetected = false;
   
    // Display "Theft Detected" on the LCD
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Theft Detected!");
  }

  if (relayActivated && (millis() - rfidTimeoutStart >= RFID_TIMEOUT) && !access) {
    Serial.println("Waiting for Activation...");
   displayScrollingMessage();
    digitalWrite(RELAY_PIN, HIGH);
    if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
      if (isCardAllowed(mfrc522.uid.uidByte, mfrc522.uid.size)) {
        relayActivated = false;
        digitalWrite(RELAY_PIN, LOW);
        rfidDetected = true;
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Access Granted");
        sendSMS("+639979258101", "Access Granted");
        Serial.println("Access Granted");
      } else {
        Serial.println("Wrong card!");
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Access Denied");
      }
    }
  }else if (access){
    Serial.println("Waiting for Activation...");
    displayScrollingMessage();
        relayActivated = true;
      digitalWrite(RELAY_PIN, HIGH);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("SYSTEM DEACTIVATED");
      sendSMS("+639979258101", "SYSTEM DEACTIVATED");
      Serial.println("System Deactivated");
      access = false;

    }

  Serial.println("Current Sensor 1: ");
  Serial.println(current1);
  Serial.println("Current Sensor 2: ");
  Serial.println(current2);
  Serial.println("Voltage Sensor 1: ");
  Serial.println(supplyVoltage1);
  Serial.println("Voltage Sensor 2: ");
  Serial.println(supplyVoltage2);
  Serial.println("Total Power: ");
  Serial.println(totalPower);
  lcd.setCursor(0, 1);
  lcd.print("Total Power:");
  lcd.print(totalPower);
  delay(1000);

  // At the end of the loop() function in Arduino 1
  // Serial communication to send data to Arduino 2
  Serial.print(current1);
  Serial.print(",");
  Serial.print(current2);
  Serial.print(",");
  Serial.print(totalPower);
  Serial.print(",");
  Serial.println(theftDetected);
  delay(1000); // Adjust delay as needed

  // Check for new SMS messages and process them
  if (sim.available()) {
    processIncomingSMS();
  }
}

void sendSMS(String number, String message) {
  sim.println("AT+CMGF=1");
  delay(100);
  sim.println("AT+CMGS=\"" + number + "\"");
  delay(100);
  sim.println(message);
  delay(100);
  sim.println((char)26);
  delay(100);
}

bool isCardAllowed(byte uid[], byte uidLength) {
  byte allowedCardUID[] = {0xD1, 0x17, 0x16, 0x0D};
  if (uidLength != 4) return false;
  for (int i = 0; i < uidLength; i++) {
    if (uid[i] != allowedCardUID[i]) return false;
  }
  return true;
}

void processIncomingSMS() {
  String response = "";
  while (sim.available()) {
    char c = sim.read();
    response += c;
    delay(10);
  }
  Serial.println("SIM Response: " + response);

  int msgIndex = response.indexOf("+CMT: ");
  if (msgIndex >= 0) {
    Serial.println("New SMS received");

    // Extract the message content
    int msgStart = response.indexOf("\r\n", msgIndex) + 2;
    int msgEnd = response.indexOf("\r\n", msgStart);
    incomingMessage = response.substring(msgStart, msgEnd);
    incomingMessage.trim(); // Remove any leading or trailing whitespace

    Serial.println("Message Content: " + incomingMessage);

    if (incomingMessage.indexOf("ACTIVATE") >= 0) {
      relayActivated = false;
      digitalWrite(RELAY_PIN, LOW);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("SYSTEM ACTIVATED");
      sendSMS("+639979258101", "SYSTEM ACTIVATED");
      Serial.println("System activated");
    } else if (incomingMessage.indexOf("TURN OFF") >= 0) {
      access = true;
      relayActivated = true;
      digitalWrite(RELAY_PIN, HIGH);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("SYSTEM DEACTIVATED");
      sendSMS("+639979258101", "SYSTEM DEACTIVATED");
      Serial.println("System Deactivated");
    }

    // Delete the read message
    sim.println("AT+CMGD=1,4"); // Delete all read messages
    delay(1000);
  }
}

void displayScrollingMessage() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(message.substring(scrollIndex));
  lcd.setCursor(0, 1);
  lcd.print(message.substring(0, scrollIndex));
  scrollIndex++;
  if (scrollIndex >= message.length()) {
    scrollIndex = 0;
  }
  //delay(); // Adjust scroll speed as needed
}