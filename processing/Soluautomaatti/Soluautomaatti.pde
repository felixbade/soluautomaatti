/////////////// Configurations ///////////////

  int tileSize = 16;
  String serialPortNameContains = "ttyACM0"; // raspberry
  //String serialPortNameContains = "usbmodem"; // mac
  
  int publishDelay = 5000; // ms
  
  float minSpeed = 1;
  float maxSpeed = 12;
  float speedGamma = 0.7;
  float maxFrameRate = 12; // too high -> program slows down. too low -> less timing accuracy
  
  float minLightness = 0.2;
  float maxLightness = 1000;
  float lightnessPotGamma = 1.6;
  float lightnessOverUnder = 0.1;
  int maxRGBLightness = (int) (255 / (1-lightnessOverUnder)); // overlight. normal = 255

//////////////////////////////////////////////


boolean userDrawMultiple = false;
float simulationSpeed = 0; // just the default is stopped
int counter;
int counterTrigger;

void setup() {
  fullScreen();
  pixelDensity(displayDensity());
  noCursor();
  colorMode(RGB, 255);
  noStroke();
  noSmooth();
  background(0);
  
  setupSimulation();
  setupDrawing();
  setupArduino();
  delay(1000); // no idea. fixes the publishing thing. Serial line seems to be unreliable or something
  setupTCP();
  thread("publishDeadLockDirtyFix");
  thread("logKeyframes");
  thread("logParameters"); // 2017-05-17
  
  counter = 0;
  counterTrigger = 1;
}

void draw() {
  try {
    mapValues();
    if (simulationSpeed > 0) {
      counterTrigger = int(maxFrameRate / simulationSpeed);
      frameRate(simulationSpeed * counterTrigger);
      println(counterTrigger, frameRate);
      
      counter += 1;
      if (counter >= counterTrigger) {
        counter = 0;
        simulateStep();
      }
    }
    
    updateDrawing();
    
    if (userDrawMultiple) {  
      // 2x2
      image(drawing, 0, 0, width/2, height/2);
      image(drawing, width/2, 0, width/2, height/2);
      image(drawing, 0, height/2, width/2, height/2);
      image(drawing, width/2, height/2, width/2, height/2);
      
    } else {
      // odd centering
      image(drawing, 0, 0, width, height);
      
      // even centering
      /*image(drawing, -width/2, -height/2, width, height);
      image(drawing, width/2, -height/2, width, height);
      image(drawing, -width/2, height/2, width, height);
      image(drawing, width/2, height/2, width, height);*/
    }
    
  } catch (Exception e) {
    StringWriter sw = new StringWriter();
    PrintWriter pw = new PrintWriter(sw);
    e.printStackTrace(pw);
    String traceback = sw.toString();
    
    String[] lines = traceback.split("\n");
    for (String line : lines) {
      tcpSend("log traceback " + line);
    }
  }
}
