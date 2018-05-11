#include <Satellites.h>
#include <ManyVibMotor.h>
#include <TimerOne.h>


Satellites rig;


// HARDWARE
const byte analogPins[] = {A0, A1, A2, A3};
const byte numInputChannels = 4;

ManyVibMotor forepawVibrator(5);
ManyVibMotor hindpawVibrator(6);


// SAMPLING
unsigned int samplingFreq = 50; // Hz
bool isStreamInputReadings = false;
volatile bool isInputReadingsAvailable = false;
volatile int inputReadings[numInputChannels];



void setup()
{
  // Set up serial communication at certain transmission speed
  Serial.begin(115200);
  
  // Setup timer/counter interrupts
  Timer1.initialize(1e6 / samplingFreq);
  Timer1.attachInterrupt(readInputs);
  Timer1.start();
  
  // Attach user parser function
  rig.attachReader(myReader);
  
  Serial.println("setup finished");
}



void loop()
{
  // Handling serial command input
  rig.serialRead();
  
  // Stream input readings
  if (isStreamInputReadings)
    sendInputReadings();
}



void readInputs()
{
  for (byte i = 0; i < numInputChannels; i++)
    inputReadings[i] = analogRead(analogPins[i]);
  
  isInputReadingsAvailable = true;
}



void sendInputReadings()
{
  if (isInputReadingsAvailable)
  {
    rig.sendData("i", millis(), inputReadings, numInputChannels);
    isInputReadingsAvailable = false;
  }
}










