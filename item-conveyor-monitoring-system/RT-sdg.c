#include <Arduino.h>
#include <Wire.h>
#include <EEPROM.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>


#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);


const int ldrPin = 34;
const int ledPin = 2;
const int comparisonLedPin = 15; // NEW LED FOR IPM COMPARISON
const int resetButtonPin = 4;
const int threshold = 3500;
const int debounceTime = 50;


volatile unsigned int itemCount = 0;
volatile unsigned int totalItemCount = 0;
volatile unsigned int ipm = 0;
volatile int expectedIPM = 0;


unsigned long lastItemTime = 0;
bool laserPreviouslyOn = false;


SemaphoreHandle_t itemCountMutex;


#define EEPROM_SIZE 512
#define EEPROM_ADDR_TOTAL 0
#define EEPROM_ADDR_IPM 4


unsigned int lastSavedTotal = 0;
unsigned int lastSavedIPM = 0;


volatile bool resetRequested = false;
volatile unsigned long lastInterruptTime = 0;


void IRAM_ATTR resetButtonISR() {
  unsigned long interruptTime = millis();
  if (interruptTime - lastInterruptTime > 200) {
    resetRequested = true;
    lastInterruptTime = interruptTime;
  }
}


void itemDetectionTask(void *pvParameters) {
  TickType_t lastWakeTime = xTaskGetTickCount();
  const TickType_t period = pdMS_TO_TICKS(5);


  for (;;) {
    int ldrValue = analogRead(ldrPin);
    unsigned long currentTime = millis();
    bool isLaserOn = (ldrValue > threshold);


    if (isLaserOn && !laserPreviouslyOn) {
      lastItemTime = currentTime;
      digitalWrite(ledPin, HIGH);
    } else if (!isLaserOn && laserPreviouslyOn) {
      if (currentTime - lastItemTime > debounceTime) {
        xSemaphoreTake(itemCountMutex, portMAX_DELAY);
        itemCount++;
        totalItemCount++;
        xSemaphoreGive(itemCountMutex);


        Serial.print("Item detected! Total Items: ");
        Serial.println(totalItemCount);
      }
      digitalWrite(ledPin, LOW);
    }


    laserPreviouslyOn = isLaserOn;
    vTaskDelayUntil(&lastWakeTime, period);
  }
}


void itemLoggerTask(void *pvParameters) {
  TickType_t lastWakeTime = xTaskGetTickCount();
  const TickType_t period = pdMS_TO_TICKS(60000);


  for (;;) {
    vTaskDelayUntil(&lastWakeTime, period);


    xSemaphoreTake(itemCountMutex, portMAX_DELAY);
    ipm = itemCount;
    itemCount = 0;
    EEPROM.put(EEPROM_ADDR_IPM, ipm);
    EEPROM.commit();
    xSemaphoreGive(itemCountMutex);


    Serial.print("Items per minute: ");
    Serial.println(ipm);
  }
}


void autoSaveTask(void *pvParameters) {
  TickType_t lastWakeTime = xTaskGetTickCount();
  const TickType_t saveInterval = pdMS_TO_TICKS(5000); // Save every 5 seconds


  for (;;) {
    vTaskDelayUntil(&lastWakeTime, saveInterval);


    xSemaphoreTake(itemCountMutex, portMAX_DELAY);
    if (totalItemCount != lastSavedTotal) {
      EEPROM.put(EEPROM_ADDR_TOTAL, totalItemCount);
      EEPROM.commit();
      lastSavedTotal = totalItemCount;
      Serial.print("Auto-saved totalItemCount: ");
      Serial.println(totalItemCount);
    }
    xSemaphoreGive(itemCountMutex);
  }
}


void oledDisplayTask(void *pvParameters) {
  TickType_t lastWakeTime = xTaskGetTickCount();
  const TickType_t period = pdMS_TO_TICKS(200);


  for (;;) {
    xSemaphoreTake(itemCountMutex, portMAX_DELAY);
    unsigned int currentCount = itemCount;
    unsigned int currentTotal = totalItemCount;
    unsigned int currentIPM = ipm;
    xSemaphoreGive(itemCountMutex);


    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.print(F("Current IPM: "));
    display.println(currentCount);


    display.setCursor(0, 10);
    display.print(F("Total items: "));
    display.println(currentTotal);


    display.setCursor(0, 20);
    display.print(F("Prev IPM: "));
    display.println(currentIPM);


    display.display();


    vTaskDelayUntil(&lastWakeTime, period);
  }
}


void resetButtonTask(void *pvParameters) {
  TickType_t lastWakeTime = xTaskGetTickCount();
  const TickType_t period = pdMS_TO_TICKS(20);


  for (;;) {
    if (resetRequested) {
      resetRequested = false;


      Serial.println("Reset button pressed!");
      xSemaphoreTake(itemCountMutex, portMAX_DELAY);
      totalItemCount = 0;
      itemCount = 0;
      ipm = 0;
      EEPROM.put(EEPROM_ADDR_TOTAL, totalItemCount);
      EEPROM.put(EEPROM_ADDR_IPM, ipm);
      EEPROM.commit();
      lastSavedTotal = 0;
      lastSavedIPM = 0;
      xSemaphoreGive(itemCountMutex);


      display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(SSD1306_WHITE);
      display.setCursor(0, 0);
      display.println(F("Item Monitor"));
      display.setCursor(0, 10);
      display.println(F("Total count reset!"));
      display.display();


      vTaskDelay(pdMS_TO_TICKS(1000));
    }


    vTaskDelayUntil(&lastWakeTime, period);
  }
}


void serialInputTask(void *pvParameters) {
  String inputString = "";


  for (;;) {
    if (Serial.available()) {
      char c = Serial.read();


      if (c == '\n') {
        expectedIPM = inputString.toInt();
        Serial.print("Expected IPM set to: ");
        Serial.println(expectedIPM);
        inputString = "";
      } else if (isDigit(c)) {
        inputString += c;
      }
    }


    vTaskDelay(pdMS_TO_TICKS(100));
  }
}


void ipmMonitorTask(void *pvParameters) {
  TickType_t lastWakeTime = xTaskGetTickCount();
  const TickType_t period = pdMS_TO_TICKS(500);


  for (;;) {
    xSemaphoreTake(itemCountMutex, portMAX_DELAY);
    int currentIPM = ipm;
    int targetIPM = expectedIPM;
    xSemaphoreGive(itemCountMutex);


    if (targetIPM > 0) {
      if (currentIPM > targetIPM) {
        digitalWrite(comparisonLedPin, HIGH);
        vTaskDelay(pdMS_TO_TICKS(200));
        digitalWrite(comparisonLedPin, LOW);
        vTaskDelay(pdMS_TO_TICKS(200));
        continue;
      } else if (currentIPM < targetIPM) {
        digitalWrite(comparisonLedPin, HIGH);
      } else {
        digitalWrite(comparisonLedPin, LOW);
      }
    } else {
      digitalWrite(comparisonLedPin, LOW);
    }


    vTaskDelayUntil(&lastWakeTime, period);
  }
}


void setup() {
  Serial.begin(115200);
  delay(2000);
  EEPROM.begin(EEPROM_SIZE);
  pinMode(ledPin, OUTPUT);
  pinMode(comparisonLedPin, OUTPUT); // NEW LED PIN SETUP
  pinMode(resetButtonPin, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(resetButtonPin), resetButtonISR, FALLING);


  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    for (;;);
  }


  EEPROM.get(EEPROM_ADDR_TOTAL, totalItemCount);
  EEPROM.get(EEPROM_ADDR_IPM, ipm);
  lastSavedTotal = totalItemCount;
  lastSavedIPM = ipm;


  Serial.print("EEPROM loaded totalItemCount: ");
  Serial.println(totalItemCount);
  Serial.print("EEPROM loaded prev IPM: ");
  Serial.println(ipm);


  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println(F("System Starting..."));
  display.setCursor(0, 10);
  display.println(F("ITEM MONITOR"));
  display.display();
  delay(1000);


  itemCountMutex = xSemaphoreCreateMutex();


xTaskCreatePinnedToCore(itemDetectionTask, "ItemDetection", 2048, NULL, 5, NULL, 1); // Highest priority (most frequent)
xTaskCreatePinnedToCore(oledDisplayTask, "OLEDDisplay", 2048, NULL, 4, NULL, 1);     // Medium-high priority (relatively frequent)
xTaskCreatePinnedToCore(ipmMonitorTask, "IPMMonitor", 2048, NULL, 4, NULL, 1);       // Medium-high priority (periodic)
xTaskCreatePinnedToCore(autoSaveTask, "AutoSave", 2048, NULL, 3, NULL, 1);           // Medium priority (every few seconds)
xTaskCreatePinnedToCore(itemLoggerTask, "ItemLogger", 2048, NULL, 2, NULL, 1);       // Low priority (infrequent)
xTaskCreatePinnedToCore(resetButtonTask, "ResetButton", 2048, NULL, 1, NULL, 1);     // Low priority (user event-driven)
xTaskCreatePinnedToCore(serialInputTask, "SerialInput", 2048, NULL, 1, NULL, 1);     // Low priority (user event-driven)


}


void loop() {
  // Nothing here
}