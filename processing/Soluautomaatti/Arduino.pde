import processing.serial.*;
import java.util.*;

// Config
int arduinoBaud = 19200;

int potCount = 9;
int btnCount = 32;

int speedPotIndex = 0;
int lightnessPotIndex = 1;
int contrastPotIndex = 2;
int huePotIndex = 3;
int hueDiffPotIndex = 4;

// Program
Serial arduino;
float[] pots;
boolean[] btns;
boolean publishStatusLedOK = false;
boolean publishStatusLedWaiting = false;
boolean publishStatusLedError = false;
String serialPort = "";
String publishingStatusLetter;

String STATUS_LETTER_OK = "aaaaaaaa";
// b = please wait. Arduino sets it automatically when the button is pressed.
String STATUS_LETTER_ERROR = "cccccccc";

void setupArduino() {
  connectSerial();
  
  pots = new float[potCount];
  btns = new boolean[btnCount];
  for (int i = 0; i < potCount; i++) {
    pots[i] = 0.5;
  }
  for (int i = 0; i < potCount; i++) {
    btns[i] = false;
  }
  arduinoAllowPublishing(); // The panel says "please wait" on boot. Tell the user that we are ok.
  
  thread("serialLoop");
}

void connectSerial() {
  while (serialPort.equals("")) {  
    for (String s : Serial.list()) {
      logPrint(s);
      if (s.indexOf(serialPortNameContains) != -1) {
        serialPort = s;
        try {
          arduino = new Serial(this, serialPort, arduinoBaud);
          break;
        } catch (Exception e) {
          serialPort = ""; // keep trying
        }
      }
    }
  }
  logPrint("Connected to arduino");
}

void serialLoop() {
  String fromArduino = "";
  while (true) {
    arduino.write(toArduino() + "\n"); // tell arduino we can read the next values
    
    delay(50); // not sure why removing this causes blinking problems
    
    while (arduino.available() > 0) {
      char inChar = arduino.readChar();
      if (inChar == '\r') {
        continue;
      }
      if (inChar == (char) -1) {
        continue; // these seem like they shouldn't be there.
        // ignoring them fixes a lot of things though
      }
      if (inChar == '\n') {
        // TODO not sure if we should be able to get clean stream or not
        try {
          parseSerial(fromArduino);
        } catch (NumberFormatException e) {
          logPrint("Serial parse error: " + fromArduino);
        } catch (ArrayIndexOutOfBoundsException e) {
          logPrint("Serial parse error: " + fromArduino);
        }
        fromArduino = "";
      } else {
        fromArduino += inChar;
      }
    }
  }
}

boolean lastSerialFound() {
  return Arrays.asList(Serial.list()).contains(serialPort);
}

void arduinoAllowPublishing() {
  publishingStatusLetter = STATUS_LETTER_OK;
}

String toArduino() {
  String text = "";
  text += arduinoJoinBooleans(SStates);
  text += ",";
  text += arduinoJoinBooleans(BStates);
  if (!networkIsUp || errorPublishing) {
    publishingStatusLetter = STATUS_LETTER_ERROR;
  }

  text += publishingStatusLetter;
  publishingStatusLetter = "";
  return text;
}

String arduinoJoinBooleans(boolean[] booleans) {
  String text = "";
  for (int i = 0; i < booleans.length; i++) {
    text += booleans[i] ? "?" : "0";
    if (i != booleans.length-1) {
      text += ",";
    }
  }
  return text;
}

void parseSerial(String line) {
  float maxValue = Integer.parseInt(line.split("; ")[0]);
  String[] rawNumbers = line.split("; ")[1].split(",");
  String[] rawBooleans = line.split("; ")[2].split(",");
  
  int potCount = min(pots.length, rawNumbers.length);
  for (int i = 0; i < potCount; i++) {
    pots[i] = Integer.parseInt(rawNumbers[i]) / maxValue;
  }  
  
  int btnCount = min(btns.length, rawBooleans.length);
  for (int i = 0; i < btnCount; i++) {
    btns[i] = rawBooleans[i].equals("1");
  }

  // added 2018-03-10
  if (btns[31]) {
    publishPicture();
  }
}

void mapValues() {
  S[0] = btns[0];
  S[1] = btns[1];
  S[2] = btns[2];
  S[3] = btns[3];
  S[4] = btns[4];
  S[5] = btns[5];
  S[6] = btns[6];
  S[7] = btns[7];
  S[8] = btns[8];
  
  B[0] = btns[9];
  B[1] = btns[10];
  B[2] = btns[11];
  B[3] = btns[12];
  B[4] = btns[13];
  B[5] = btns[14];
  B[6] = btns[15];
  B[7] = btns[16];
  B[8] = btns[17];
  
  directions[0] = btns[25];
  directions[1] = btns[24];
  directions[2] = btns[23];
  directions[3] = btns[22];
  directions[4] = btns[21];
  directions[5] = btns[20];
  directions[6] = btns[19];
  directions[7] = btns[18];
  
  simulationSpeed = minSpeed * exp(log(maxSpeed/minSpeed) * pow(pots[speedPotIndex], speedGamma));
  
  noiseOn = btns[26];
  userColoringMethod = int(btns[27]) + 1;  
  userNegative = btns[28];
  userDrawMultiple = btns[29];
  userColorSteps = btns[30] ? 7 : 1000;
  
  userHue = (pots[huePotIndex] * 1.5) % 1;
  userHueDiff = (pots[hueDiffPotIndex] * 2 - 1) * 2;

  float prevLightness = userLightness;
  userLightness = minLightness * exp(log(maxLightness/minLightness) * 
                                     pow(pots[lightnessPotIndex], lightnessPotGamma));
  userContrast = exp((1 - 2*pots[contrastPotIndex]) - 0.25);

  if (userLightness != prevLightness) {
    lightingChanged();
  }  
}
