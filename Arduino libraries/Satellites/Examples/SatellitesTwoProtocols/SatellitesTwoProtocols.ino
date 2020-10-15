/*
  SatellitesTwoProtocols
  This example illustrates an organized way to implement two interactive behavior
  protocols using the SatelliteRig library.
*/


// Include Satellites library
#include <Satellites.h>


// SatelliteRig object
Satellites sr;


// Pin numbers
int lickPin = 14;     // receives digital lick signal
int valvePin = 13;    // controls water valve solenoid

int ledPin = 12;      // controls an LED for viusal stimulation


// Parameters
int waterDur = 200;       // duration (ms) of valve opening time for water reward
int itiDur = 3000;        // duration (ms) of inter-trial-interval
int noLickDur = 1000;     // duration (ms) when the animal should not lick
int stimDur = 500;        // duration (ms) of visual stimulation
int responseWinDur = 500; // duration (ms) of response window after stimulation


// Runtime variables
byte protocolId = 0;  // protocol selection


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

  // Execute training protocols
  switch (protocolId) {
    case 1:
      lickForWater(); break;
    case 2:
      detectionTask(); break;
    default:
      break;
  }
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
