int wwidth, wheight, wsize;
boolean[][] worlds;
int[][] age1s, age2s;
int worldCount = 4;
int lastReadyWorld, last2ReadyWorld;
int nextWorld;
int iteration;
boolean noiseOn;

boolean[] S, B;
boolean[] directions = {true, true, true,
                        true,       true,
                        true, true, true};
boolean[] SStates, BStates, newSStates, newBStates;
boolean anyAlive;
boolean anyDead;
boolean simulating, stopSimulating, willCommit;

void setupSimulation() {
  iteration = 0;
  last2ReadyWorld = 0;
  lastReadyWorld = 1;
  nextWorld = 2;
  
  wwidth = width / tileSize;
  wheight = height / tileSize;
  wsize = wwidth * wheight;
  worlds = new boolean[worldCount][wsize];
  age1s = new int[worldCount][wsize];
  age2s = new int[worldCount][wsize];
  anyAlive = true;
  anyDead = true;
  stopSimulating = false;
  simulating = false;
  
  for (int i = 0; i < wsize; i++) {
    for (int j = 0; j < worldCount; j++) {
      worlds[j][i] = random(10) > 7;
      age1s[j][i] = 0;
      age2s[j][i] = 0;
    }
  }
  
  S = new boolean[9];
  B = new boolean[9];
  SStates = new boolean[9];
  BStates = new boolean[9];
  newSStates = new boolean[9];
  newBStates = new boolean[9];
  for (int i = 0; i < 9; i++) {
    SStates[i] = false;
    BStates[i] = false;
    S[i] = true;
    B[i] = false;
  }
  willCommit = false;
}

void commitStep() {
  last2ReadyWorld = lastReadyWorld;
  lastReadyWorld = nextWorld;
  nextWorld = (nextWorld + 1) % worldCount;
  
  arrayCopy(newSStates, SStates);
  arrayCopy(newBStates, BStates);
}

void simulateStep() {
  boolean[] tempS = new boolean[9];
  boolean[] tempB = new boolean[9];
  arrayCopy(S, tempS);
  arrayCopy(B, tempB);

  for (int i = 0; i < 9; i++) {
    newSStates[i] = false;
    newBStates[i] = false;
  }
  
  float flipRareness = 1e30;
  if (!anyAlive || !anyDead) {
    flipRareness = 10*wwidth*wheight;
  }
  if (noiseOn) {
    flipRareness = 0.02 * wwidth*wheight;
  }
  anyAlive = false;
  anyDead = false;

  boolean[] newWorld = worlds[nextWorld];
  boolean[] previousWorld = worlds[lastReadyWorld];
  boolean[] previous2World = worlds[last2ReadyWorld];
  
  int activeDirections = 0;
  for (int i = 0; i < 8; i++) {
    if (directions[i]) {
      activeDirections++;
    }
  }
  
  boolean anyFlipped = false;
  
  for (int i = 0; i < wsize; i++) {
    
    // count alive neighbours
    int neighbours = 0;
    if (directions[0] && (previousWorld[(i + wsize - wwidth - 1) % wsize])) neighbours++;
    if (directions[1] && (previousWorld[(i + wsize - wwidth    ) % wsize])) neighbours++;
    if (directions[2] && (previousWorld[(i + wsize - wwidth + 1) % wsize])) neighbours++;
    if (directions[3] && (previousWorld[(i + wsize          - 1) % wsize])) neighbours++;
    if (directions[4] && (previousWorld[(i + wsize          + 1) % wsize])) neighbours++;
    if (directions[5] && (previousWorld[(i + wsize + wwidth - 1) % wsize])) neighbours++;
    if (directions[6] && (previousWorld[(i + wsize + wwidth    ) % wsize])) neighbours++;
    if (directions[7] && (previousWorld[(i + wsize + wwidth + 1) % wsize])) neighbours++;
    
    // determine next state based on alive neighbour count
    boolean flipped = random(flipRareness + 1) < 1;
    anyFlipped = anyFlipped || flipped;

    if (previousWorld[i]) {
      anyAlive = true;
      newSStates[neighbours] = true;
      newWorld[i] = (tempS[neighbours] != flipped);
    } else {
      anyDead = true;
      newBStates[activeDirections - neighbours] = true;
      newWorld[i] = (tempB[activeDirections - neighbours] != flipped);
    }
    
    // history
    if (newWorld[i] != previousWorld[i]) {
      age1s[nextWorld][i] = 0;
    } else {
      age1s[nextWorld][i] = age1s[lastReadyWorld][i] + 1;
    }
    
    if (newWorld[i] && previousWorld[i] && !previous2World[i]) {
      age2s[nextWorld][i] = 0;
    } else if (!newWorld[i] && previousWorld[i] && previous2World[i]) {
      age2s[nextWorld][i] = 0;
    } else {
      age2s[nextWorld][i] = age2s[lastReadyWorld][i] + 1;
    }
  }
    
  commitStep();
  
  iteration++;
  logStep(iteration, tempS, tempB);
  
  if (anyFlipped) {
    logKeyframe();
  }
}
