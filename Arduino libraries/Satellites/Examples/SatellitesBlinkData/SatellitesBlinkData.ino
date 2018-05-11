/*
  SatellitesBlinkData
  Turns on an LED on for a while, then off for a while, repeatedly.
  The device will send blinking related data to computer.
  You can use serial commands to control the way it blinks.
  The device will send command feedbacks to computer.
*/


// Include Satellites library
#include <Satellites.h>


// SatelliteRig object
Satellites sr;


// LED pin
/*
  Pin 13 has an LED connected on most Arduino boards.
  Pin 11 has the LED on Teensy 2.0
  Pin 6  has the LED on Teensy++ 2.0
  Pin 13 has the LED on Teensy 3.0
*/
int ledPin = 13;


// Blink parameters
int ledOnDuration = 1000;   // the duration of LED being on when blinking
int ledOffDuration = 1000;  // the duration of LED being off when blinking


void setup()
{
  // Initialize serial (not necessary on Teensy)
  Serial.begin(115200);

  // Initialize the LED pin as an output
  pinMode(ledPin, OUTPUT);

  // Attach the function we defined below to handle serial commands
  sr.attachReader(myReader);
}


void loop()
{
  // Read any incoming serial command
  sr.serialReadCmd();

  // Blink
  digitalWrite(ledPin, HIGH);

  // Send a data message about turning on LED.
  // If a second argument for time is not provided, 
  // the current time (returned by millis()) will be used.
  sr.sendData("ledOn");

  delay(ledOnDuration);

  digitalWrite(ledPin, LOW);

  // Send a data message about turning off LED.
  // If a second argument for time is not provided, 
  // the current time (returned by millis()) will be used.
  sr.sendData("ledOff");

  delay(ledOffDuration);
}


// We define a function myReader (or use whatever name you like) to handle serial commands.
void myReader()
{
  // Get command information
  String cmdStr = sr.getCmdName();
  int idx = sr.getIndex();
  long val = sr.getValue();


  // Do specific things based on the command name, index and value
  if (idx == 1 && cmdStr.equals("OnDur"))
  {
    ledOnDuration = val;

    // Send a data message to confirm that ledOnDuration was correctly assigned.
    // The value, ledOnDuration, is provided as the third argument.
    // For the second argument, we can simply use the current time.
    sr.sendData("led on duration", millis(), ledOnDuration);
  }
  else if (idx == 1 && cmdStr.equals("OffDur"))
  {
    ledOffDuration = val;
    sr.sendData("led off duration", millis(), ledOffDuration);  // similar as above
  }
  else if (idx == 1 && cmdStr.equals("OnOffDur"))
  {
    ledOnDuration = val;

    // We can but we choose not to send a message here since the command is not finished yet
  }
  else if (idx == 2 && cmdStr.equals("OnOffDur"))
  {
    ledOffDuration = val;

    // Prepare an array for sending multiple values in one message
    int durArray[] = {ledOnDuration, ledOffDuration};
    int arrayLength = 2;

    // Send a data message to report multiple values
    // When sending an array, the length must be provided as the fourth argument
    sr.sendData("led on/off durations", millis(), durArray, arrayLength);
  }
  else if (idx == 0 && cmdStr.equals("Pause five sec"))
  {
    // Store the time when pausing begins
    unsigned long pauseBeginTime = millis();

    delay(5000);

    // Send a data message to report the previously stored time
    sr.sendData("pause began at", pauseBeginTime);
  }
}





