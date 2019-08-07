boolean flipButton[buttonCount];

void setupDevices() {  
  // Leds
  leds.begin();
  for (int i = 0; i < pixelCount; i++) {
    ledStates[i] = LOW;
  }

  // Serial
  Serial.begin(baud);
  
  // Potentiometers
  for (int p = 0; p < potCount; p++) {
    for (int i = 0; i < potSavedReadings; i++) {
      analogReadings[p][i] = 0;
    }
  }

  // Buttons and switches
  for (int i = 0; i < buttonCount; i++) {
    pinMode(buttonPins[i], INPUT_PULLUP);
    buttonStates[i] = digitalRead(buttonPins[i]);
    prevButtonStates[i] = buttonStates[i];
    lastButtonChanges[i] = millis() - bounceDelay;
    flipButton[i] = false;
  }

  for (int i = 0; i < (sizeof(flippedButtons) / sizeof(int)); i++) {
    flipButton[flippedButtons[i]] = true;
  }

//  pinMode(ledPowerPin, OUTPUT);
//  digitalWrite(ledPowerPin, HIGH);
}



void ledWrite(int led, boolean state) {
  ledStates[led] = state;
}

void updateLeds() {
  int hue = (potStates[colorPot] * 3 / 2 ) % potMax;
  uint32_t onColor = colorByHue(hue, ledBrightness);
  uint32_t offColor = colorByHue(hue, 0);

  for (int i = 0; i < pixelCount; i++) {
    if (ledStates[i] == HIGH) {
      leds.setPixelColor(ledAddresses[i], onColor);
    } else {
      leds.setPixelColor(ledAddresses[i], offColor);
    }
  }
  leds.show();
}

// hue range: 0..potMax
uint32_t colorByHue(long hue, int brightness) {
  hue = hue * 3 * brightness / potMax;

  if (hue < brightness) {
    return leds.Color(brightness - hue, hue, 0);
  }
  if (hue < 2*brightness) {
    hue -= brightness;
    return leds.Color(0, brightness - hue, hue);
  }
  hue -= 2*brightness;
  return leds.Color(hue, 0, brightness - hue);
}



void updateButton(int i) {
  prevButtonStates[i] = buttonStates[i];
  if (millis() > lastButtonChanges[i] + bounceDelay) {
    boolean readState = !digitalRead(buttonPins[i]); // low = on, high = off
    
    buttonStates[i] = readState != flipButton[i];
    if (buttonStates[i] != prevButtonStates[i]) {
      lastButtonChanges[i] = millis();
    }
  }
}



void updatePotentiometer(int p) {
  // Get rid of the oldest values and make some room for newer values
  for (int i = 0; i < potSavedReadings - potAddReadings; i++) {
    analogReadings[p][i] = analogReadings[p][i + potAddReadings];
  }

  // Make some measurements with analogRead()
  for (int i = potSavedReadings - potAddReadings; i < potSavedReadings; i++) {
    analogReadings[p][i] = analogRead(analogPins[p]);
  }

  // Copy values to another array so we still know which measurements are the oldest
  for (int i = 0; i < potSavedReadings; i++) {
    sortedReadings[i] = analogReadings[p][i];
  }
  sort(sortedReadings, potSavedReadings);

  int median = sortedReadings[potSavedReadings/2];

  // This hack makes the resolution a lot better than just the median
  // Values are counted +1, 0 or -1 from the median (removes large peaks -> much less noise)
  int over = 0;
  for (int i = 0; i < potSavedReadings; i++) {
    if (sortedReadings[i] > median) {
      over = over + 1;
    } else if (sortedReadings[i] < median) {
      over = over - 1;
    }
  }
  int value = (((long) median * potSavedReadings + over) * potResolutionMultiplier + potSavedReadings/2) / potSavedReadings;
  
  // Hysteresis complitely eliminates small fluctuations while keeping
  // the potentiometer 100 % responsive and accurate
  potStates[p] = min(potStates[p], value);
  potStates[p] = max(potStates[p], value - potHysteresisSize);
}



void sort(int *arr, int len) {
  quickSort(arr, 0, len);
}

void quickSort(int *arr, int left, int right) {
  int i = left;
  int j = right;
  int tmp;
  int pivot = arr[(left + right) / 2];
  
  // Partition
  while (i <= j) {
    while (arr[i] < pivot)
      i++;
    while (arr[j] > pivot)
      j--;
    if (i <= j) {
      tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
      i++;
      j--;
    }
  }
  
  // Recursion
  if (left < j)
    quickSort(arr, left, j);
  if (i < right)
    quickSort(arr, i, right);
}
