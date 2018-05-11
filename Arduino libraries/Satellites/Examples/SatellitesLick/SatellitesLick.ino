/*
  SatellitesLick
  Training an animal to lick a port for water reward is one of the simplest behaviors.
  This example illustrates a general structure to implement an interactive behavior
  protocol using the SatelliteRig library.
*/


// Include Satellites library
#include <Satellites.h>


// SatelliteRig object
Satellites sr;


// Pin numbers
int lickPin = 2;      // receives digital lick signal
int valvePin = 13;    // controls water valve solenoid


// Parameters
int waterDur = 200;       // duration (ms) of valve opening time for water reward
int itiDur = 3000;        // duration (ms) of inter-trial-interval
int noLickDur = 1000;     // duration (ms) when the animal should not lick
bool isTraining = false;  // whether or not the training should proceed


void setup()
{
  // Initialize serial (not necessary on Teensy)
  Serial.begin(115200);

  // Initialize pins as input or output
  pinMode(lickPin, INPUT);
  pinMode(valvePin, OUTPUT);

  // Attach the function you defined below to handle serial commands
  sr.attachReader(myReader);

  // Setup external interrupt and callback function
  attachInterrupt(digitalPinToInterrupt(lickPin), reportLick, RISING);
}


void loop()
{
  // Read any incoming serial command
  sr.serialReadCmd();
}


void myReader()
{
  // Get command information
  String cmdStr = sr.getCmdName();
  int idx = sr.getIndex();
  long val = sr.getValue();


  // Do specific things based on the command name, index and value
  if (idx == 0 && cmdStr.equals("LFW"))
  {
    // Execute the function for training
    lickForWater();
  }
  else if (idx == 1 && cmdStr.equals("IST"))
  {
    // Change whether the training should procced or not
    isTraining = val;
    sr.sendData("isTraining set", millis(), isTraining);
  }
  else if (idx == 1 && cmdStr.equals("WAT"))
  {
    // Change water valve opening duration
    waterDur = val;
    sr.sendData("waterDur set", millis(), waterDur);
  }
  else if (idx == 1 && cmdStr.equals("ITI"))
  {
    // Change the duration of inter-trial-interval
    itiDur = val;
    sr.sendData("itiDur set", millis(), itiDur);
  }
  else if (idx == 1 && cmdStr.equals("NLK"))
  {
    // Change the duration of no lick interval
    noLickDur = val;
    sr.sendData("noLickDur set", millis(), noLickDur);
  }
  else if (idx == 1 && cmdStr.equals("w"))
  {
    // Manually give animal certain amount of water
    unsigned long valveOnTime = millis();
    digitalWrite(valvePin, HIGH);
    delay(val);
    digitalWrite(valvePin, LOW);
    sr.sendData("water delivered", valveOnTime, val);
  }
}


// LickForWater protocol
void lickForWater()
{
  // Report the start of training
  sr.sendData("lickForWaterStart");

  // Allow training to proceed
  isTraining = true;

  // Store the number of trials
  int numTrials = 0;

  // Loop for trials
  while (isTraining)
  {
    // Increment trial count
    numTrials++;

    // Report current trial time and number
    sr.sendData("trial", millis(), numTrials);
    
    // Wait for inter-trial-interval
    /*
       This delay method in SatelliteRig object blocks the code for itiDur amount of time.
       Meanwhile, incoming serial commands can still be processed and code in myReader will
       be executed. Use Arduino's delayMicroseconds function if the precision is critical.
    */
    sr.delay(itiDur);

    // Wait for animal to stop licking for a while
    /*
       This delayContinue method blocks the code for noLickDur amount of time. However, if the
       isLickPinHigh function (defined below) returns true during the delay, the delay will
       continue repeating itself until isLickPinHigh stops returning ture for a noLickDur.
       Similar to delay method, serial commands can be processed at the same time.
    */
    sr.delayContinue(isLickPinHigh, noLickDur);

    // Wait for licking response
    /*
       This delayUntil method blocks the code until isLickPinHigh returns true or up to 10000ms,
       whichever is the earliest. The second argument of timeout limit is optional but highly
       recommended. Similar to delay method, serial commands can be processed at the same time.
    */
    bool isLicked = sr.delayUntil(isLickPinHigh, 10000);

    // Deliver water reward if animal licked
    if (isLicked)
    {
      unsigned long valveOnTime = millis();

      digitalWrite(valvePin, HIGH);
      delay(waterDur);
      digitalWrite(valvePin, LOW);

      sr.sendData("water delivered", valveOnTime, millis() - valveOnTime);
    }
  }

  // Report the end of training
  sr.sendData("lickForWaterEnd");
}


// A function that checks for licking
bool isLickPinHigh()
{
  return digitalRead(lickPin) == HIGH;
}


// Lick interrupt callback function
void reportLick()
{
  sr.sendData("lick");
}


