// Config
String password = ""; // removed for github version
String host = "soluautomaatti.fi"; // go see the pictures at https://soluautomaatti.fi
int port = 0; // also not public
int tcpTimeout = 3000;

// TODO: no flooding
boolean canPublish = true;
boolean errorPublishing = false; // not used right now. server has a full disk or something

void handleTCPInput(String line) {
  if (line == "Ping") {
    tcpout.println("Pong");
  }
  if (line == "Error publishing") {
    println(line);
//    delay(1000);
    errorPublishing = true;
  }
}

void publishDeadLockDirtyFix() {
  while (true) {
    arduinoAllowPublishing();
    delay(60000);
  }
}

void logKeyframes() {
  while (true) {
    logKeyframe();
    logHistory1Keyframe();
    logHistory2Keyframe();
    delay(10000);
  }
}

void logParameters() {
  while (true) {
    logSingleParameters();
    delay(50);
  }
}

void publishPicture() {
  if (canPublish) {
    while (drawingInProgress) {
      delay(1);
    }
    StringBuilder imageData = new StringBuilder();
    for (int i = 0; i < wsize; i++) {
      imageData.append(hex(drawing.pixels[i], 6));
      if (i < wsize-1) {
        imageData.append(",");
      }
    }
    tcpSend("pic " + wwidth + "x" + wheight + " " + imageData.toString() + " " + iteration);
    logKeyframe();
    logHistory1Keyframe();
    logHistory2Keyframe();
    thread("publishDelayWatcher"); // this is async so we have to spawn a thread to keep an eye on the response
    // also we should spawn a thread to limit when we can post again
  }
}

void publishDelayWatcher() {
  delay(publishDelay); // todo add leaky bucket timer thing
  canPublish = true;
  arduinoAllowPublishing();
}

void logPrint(String text) {
  println(text);
  String[] lines = text.split("\n");
  for (String line : lines) {
    tcpSend("log " + line);
  }
}

void logStep(int iteration, boolean[] ruleS, boolean[] ruleB) {
  String data = "log step " + iteration;
  data += " S:" + joinBooleans(ruleS);
  data += " B:" + joinBooleans(ruleB);
  data += " dir:" + joinBooleans(directions);
  
  tcpSend(data);
}

void logSingleParameters() {
  int it = iteration;
  String data = "log parameters " + it;
  
  data += " S:" + joinBooleans(S);
  data += " B:" + joinBooleans(B);
  data += " dir:" + joinBooleans(directions);
  
  data += " kohina:" + (btns[26] ? "1" : "0");
  data += " ropelo:" + (btns[27] ? "1" : "0");
  data += " negatiivi:" + (btns[28] ? "1" : "0");
  data += " toisto:" + (btns[29] ? "1" : "0");
  data += " 8-bit:" + (btns[30] ? "1" : "0");
  data += " speed:" + simulationSpeed;
  data += " light:" + pots[1] + "," + pots[2];
  data += " hue:" + pots[3] + "," + pots[4];
  tcpSend(data);
  
  data = "log stats";
  data += " counterTrigger:" + counterTrigger;
  data += " frameRate:" + frameRate;
  tcpSend(data);
}

void logKeyframe() {
  int it = iteration;
  boolean[] previousWorld = worlds[lastReadyWorld];
  StringBuilder w = new StringBuilder();
  for (int i = 0; i < wsize; i++) {
    w.append(previousWorld[i] ? "1" : "0");
    if ((i+1) % wwidth == 0) {
      w.append(",");
    }
  }
  tcpSend("log keyframe " + it + " " + w.toString());
}

void logHistory1Keyframe() {
  int it = iteration;
  int[] previousWorld = age1s[lastReadyWorld];
  StringBuilder w = new StringBuilder();
  for (int i = 0; i < wsize; i++) {
    w.append(previousWorld[i]);
    w.append(",");
    if ((i+1) % wwidth == 0) {
      w.append(";");
    }
  }
  tcpSend("log history1 " + it + " " + w.toString());
}

void logHistory2Keyframe() {
  int it = iteration;
  int[] previousWorld = age2s[lastReadyWorld];
  StringBuilder w = new StringBuilder();
  for (int i = 0; i < wsize; i++) {
    w.append(previousWorld[i]);
    w.append(",");
    if ((i+1) % wwidth == 0) {
      w.append(";");
    }
  }
  tcpSend("log history2 " + it + " " + w.toString());
}

String joinBooleans(boolean[] booleans) {
  String text = "";
  for (int i = 0; i < booleans.length; i++) {
    text += booleans[i] ? "1" : "0";
    if (i != booleans.length-1) {
      text += ",";
    }
  }
  return text;
}
  
