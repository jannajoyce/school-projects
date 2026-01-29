#include <SoftwareSerial.h>

// Define the ESP-01s RX and TX pins
#define RX 7
#define TX 6
String AP = "realme 8i";       // AP NAME
String PASS = "jeyykyt3"; // AP PASSWORD
String API = "FDCZJMDM8KZPU805";   // Write API KEY
String HOST = "api.thingspeak.com";
String PORT = "80";

SoftwareSerial esp8266(RX, TX); // ESP-01s RX is connected to pin 6 (TX of Arduino) and TX is connected to pin 7 (RX of Arduino)

void setup() {
  Serial.begin(9600);
  esp8266.begin(115200);

   // Reset the ESP-01S
  sendATCommand("AT+RST", 2000);

  // Set the ESP-01S to AP mode
  sendATCommand("AT+CWMODE=2", 2000);

  // Set the SSID and password for the AP
  String cmd = "AT+CWSAP=\"" + String(AP) + "\",\"" + String(PASS) + "\",5,3";
  sendATCommand(cmd.c_str(), 5000);

  // Print the IP address
  sendATCommand("AT+CIFSR", 2000);

  sendCommand("AT", 5, "OK");
  sendCommand("AT+CWMODE=1", 5, "OK");
  sendCommand("AT+CWJAP=\"" + AP + "\",\"" + PASS + "\"", 20, "OK");
}

void loop() {
  // Read data from Arduino 1 via serial
  if (Serial.available() > 0) {
    float current1 = Serial.parseFloat();
    float current2 = Serial.parseFloat();
    float totalPower = Serial.parseFloat();
    bool theftDetected = Serial.parseInt();
   
    // Now send the data to ThingSpeak
    // Construct the GET request
    String getData = "GET /update?api_key=" + API + "&field1=" + String(current1) + "&field2=" + String(current2) + "&field3=" + String(totalPower) + "&field4=" + String(theftDetected);
    // Send the data using the ESP-01s module
    sendCommand("AT+CIPMUX=1", 5, "OK");
    sendCommand("AT+CIPSTART=0,\"TCP\",\"" + HOST + "\"," + PORT, 15, "OK");
    sendCommand("AT+CIPSEND=0," + String(getData.length() + 4), 4, ">");
    esp8266.println(getData);
    delay(1500); // Adjust delay as needed
    sendCommand("AT+CIPCLOSE=0", 5, "OK");
  }
}


void sendCommand(String command, int maxTime, char readReplay[]) {
  boolean found = false;
  int countTrueCommand = 0;
  int countTimeCommand = 0;
  Serial.print(countTrueCommand);
  Serial.print(". at command => ");
  Serial.print(command);
  Serial.print(" ");
  while (countTimeCommand < (maxTime * 1)) {
    esp8266.println(command); // Send AT command to ESP8266
    if (esp8266.find(readReplay)) { // Response "OK" is expected
      found = true;
      break;
    }
    countTimeCommand++;
  }
  if (found == true) {
    Serial.println("connected");
    countTrueCommand++;
    countTimeCommand = 0;
  }
  if (found == false) {
    Serial.println("failed to connect");
    countTrueCommand = 0;
    countTimeCommand = 0;
  }
}

void sendATCommand(const char* command, const int timeout) {
  esp8266.println(command);
  long int time = millis();
  while ((time + timeout) > millis()) {
    while (esp8266.available()) {
      char c = esp8266.read();
      Serial.write(c); // Print the response to Serial Monitor
    }
  }
}