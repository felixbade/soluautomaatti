PImage drawing;

int lightnessCacheSize = 100000;
int userColoringMethod = 1;
boolean userNegative;
float userHue, userHueDiff, userContrast, userColorSteps;
float userLightness = -1;

float lightnessMultiplier;
float lightnesses[];
boolean drawingInProgress;

void setupDrawing() {
  drawing = createImage(wwidth, wheight, RGB);
  drawingInProgress = false;
  lightnesses = new float[lightnessCacheSize]; // lazy look-up table
}

void updateDrawing() {
  drawingInProgress = true;
  drawing.loadPixels();

  int age[];
  
  // there was a coloring method 0, but it is not implemented right now because after refactoring
  // the code became a lot cleaner without it
  if (userColoringMethod == 1) {
    age = age1s[lastReadyWorld];
  } else {
    age = age2s[lastReadyWorld];
  }

  int index = 0;
  for (int y = 0; y < wheight; y++) {
    for (int x = 0; x < wwidth; x++) {
      drawing.pixels[index] = getColor(age[index]);
      index++;
    }
  }
  
  drawing.updatePixels();
  drawingInProgress = false;
}

color getColor(float age) {
  float lightness = lazyLightness((int) age);
  if (userNegative) {
    lightness = 1-lightness;
  }
  
  if (lightness > 0.5) {
    lightness = pow((lightness - 0.5)*2, userContrast)/2 + 0.5;
  } else {
    lightness = 0.5 - pow((0.5 - lightness)*2, userContrast)/2;
  }
  
  lightness = int(lightness * userColorSteps) / userColorSteps;
  
  float hueshift = 0.1;
  // -0.9 is for ease of use
  float huediff = userHueDiff*(pow(lightness, hueshift) - 0.9);
  float hue2 = ((userHue + huediff) % 1 + 1) % 1;
  
  return hsl(hue2, 1-lightness, lightness);
}

void lightingChanged() {
  // remove old values
  for (int i = 0; i < lightnessCacheSize; i++) {
    lightnesses[i] = -1;
  }
  lightnessMultiplier = (1-lightnessOverUnder) / exp(-pow(1.0 / userLightness, 0.3));
}

float lazyLightness(int age) {
  if (age >= lightnessCacheSize) {
    // realistically nothing ever reaches this. this condition is here so that
    // nothing breaks if that happens.
    // 100k steps @ 12Hz = 2 hours
    return 0;
  }
  if (lightnesses[age] == -1) {
    float lightness = exp(-pow((age+1) / userLightness, 0.3));
    lightness *= lightnessMultiplier;
    lightnesses[age] = lightness;
  }
  return lightnesses[age];
}