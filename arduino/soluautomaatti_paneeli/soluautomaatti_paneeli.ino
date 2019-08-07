#include <Adafruit_NeoPixel.h>

// BUTTONS (logical indexes in this sketch, not wiring)
// A0..A8: 0..8
// B0..B8: 9..17
// Directions (nw, n, ne, w, e, sw, s, se): 18..25
// Kohina: 26
// Julkaise kuva: 27
// Röpelö: 28
// Negatiivi: 29
// Toisto: 30
// 8-bit: 31

// LEDS (logical indexes in this sketch, not wiring)
// A0..A8: 0..8
// B0..B8: 9..17
// Directions (nw, n, ne, w, e, sw, s, se): 18..25
// Voi julkaista: 26
// Odota hetki: 27
// Ongelma: 28

// Configuration: Wirings
const int pixelCount = 29;
const int ledAddresses[pixelCount] = {20, 21, 22, 23, 24, 25, 26, 27, 28, 19, 18, 17, 16, 15, 14, 13, 12, 11, 7, 6, 5, 8, 4, 9, 10, 3, 2, 1, 0};
const int pixelPin = 2;
const int buttonCount = 32;
const int buttonPins[buttonCount] = {22, 23, 24, 25, 26, 27, 28, 29, 30, 33, 34, 35, 36, 37, 38, 39, 40, 41, 45, 43, 44, 46, 42, 47, 48, 49, 31, 32, 53, 52, 50, 51};
const int flippedButtons[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 28, 29, 30, 31};
const int potCount = 5;
const int analogPins[potCount] = {A2, A1, A3, A0, A4};
const int colorPot = 3;

// Configuration: Input/output parameters
const int ledBrightness = 10; // 0..255
const int bounceDelay = 50; // ms // 50 ms is usable but 250 ms -> we don't want people to smash the buttons
const int potSavedReadings = 50;
const int potAddReadings = 10;
const int potHysteresisSize = 10;
const int potResolutionMultiplier = 4;
const long blinkDelay = 1400;
const int statusBlinkDelay = 200;
const int statusBlinkCount = 3;
const int loopDelay = 10;

// Configuration: serial
const long baud = 19200;
const int serialLedCount = 18;
const int serialLeds[serialLedCount] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17};
const int serialButtonCount = 31;
const int serialButtons[serialButtonCount] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 28, 29, 30, 31};



// Leds
Adafruit_NeoPixel leds = Adafruit_NeoPixel(pixelCount, pixelPin, NEO_RGB + NEO_KHZ800);
boolean ledStates[pixelCount];

// Potentiometers
long cycle = 0;
int analogReadings[potCount][potSavedReadings];
int sortedReadings[potSavedReadings];
int potStates[potCount];
int potMax = 1023 * potResolutionMultiplier - potHysteresisSize;

// Buttons and switches
boolean buttonStates[buttonCount];
boolean prevButtonStates[buttonCount];
long lastButtonChanges[buttonCount];

// Serial
int incomingDataIndex = 0;

// direction led blink
long lastOnTime;

// publish
long lastWaitLedBlink;
int publishingStatus;
const int STATUS_OK = 0;
const int STATUS_WAIT = 1;
const int STATUS_ERROR = 2;
boolean reportPublishing = false;

void setup() {
  setupDevices();
  publishingStatus = STATUS_WAIT;
  lastWaitLedBlink = millis() - statusBlinkDelay * statusBlinkCount; // no blink
}

void loop() {
  for (int i = 0; i < potCount; i++) {
    updatePotentiometer(i);
  }
  for (int i = 0; i < buttonCount; i++) {
    updateButton(i);
  }
  if (Serial.available() > 0) {
    serialRead();
    serialSend();
  }

  // Julkaise kuva
  if (buttonStates[27] && !prevButtonStates[27]) {
    if (publishingStatus == STATUS_OK) {
      publishingStatus = STATUS_WAIT;
      reportPublishing = true;
    } else {
      if (millis() - lastWaitLedBlink < statusBlinkDelay * statusBlinkCount) {
        lastWaitLedBlink = lastWaitLedBlink % statusBlinkDelay;
      } else {
        lastWaitLedBlink = millis();
      }
    }
  }
  boolean statusBlink;
  if (millis() - lastWaitLedBlink < statusBlinkDelay * statusBlinkCount) {
    statusBlink = (millis() - lastWaitLedBlink) % statusBlinkDelay < statusBlinkDelay/2;
  }
  ledStates[26] = publishingStatus == STATUS_OK;
  ledStates[27] = (publishingStatus == STATUS_WAIT) && !statusBlink;
  ledStates[28] = (publishingStatus == STATUS_ERROR) && !statusBlink;

  // Direction leds
  boolean anyOn = false;
  for (int i = 18; i <= 25; i++) {
    if (buttonStates[i]) {
      anyOn = true;
      lastOnTime = millis();
      break;
    }
  }
  if (anyOn) {
    for (int i = 18; i <= 25; i++) {
      ledStates[i] = buttonStates[i];
    }
  } else {
    long timeFromLastBlink = millis() - lastOnTime;
    if (timeFromLastBlink >= blinkDelay) {
      lastOnTime = millis();
    }
    boolean blinkState = 2*timeFromLastBlink > blinkDelay;
    for (int i = 18; i <= 25; i++) {
      ledStates[i] = blinkState;
    }
  }

  updateLeds();

  delay(loopDelay);
}

void serialSend() {
  Serial.print(potMax);
  Serial.print("; ");
  
  for (int p = 0; p < potCount; p++) {
    Serial.print(potStates[p]);
    if (p < potCount - 1) {
      Serial.print(",");
    }
  }
  Serial.print("; ");

  // buttons
  for (int i = 0; i < serialButtonCount; i++) {
    Serial.print(buttonStates[serialButtons[i]]);
    if (i < serialButtonCount - 1) {
      Serial.print(",");
    }
  }

  Serial.print(",");
  if (reportPublishing) {
    Serial.print("1");
    reportPublishing = false;
  } else {
    Serial.print("0");
  }
  
  Serial.println();
}

void serialRead() {
  while (Serial.available() > 0) {
    byte inChar = Serial.read();
    if (inChar == ',') {
      incomingDataIndex++;
    }
    if (inChar == '\n') {
      incomingDataIndex = 0;
    }
    if (incomingDataIndex < serialLedCount) {
      if (inChar == '?') { // chr(ord('0') + 0xf)    
        ledWrite(serialLeds[incomingDataIndex], HIGH);
      }
      if (inChar == '0') {    
        ledWrite(serialLeds[incomingDataIndex], LOW);
      }
    }
    if (inChar == 'a') {
      publishingStatus = STATUS_OK;
    }
    if (inChar == 'b') {
      publishingStatus = STATUS_WAIT;
    }
    if (inChar == 'c') {
      publishingStatus = STATUS_ERROR;
    }
  }
}
