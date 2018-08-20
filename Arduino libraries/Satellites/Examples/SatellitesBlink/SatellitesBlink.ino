/*
  SatellitesBlink
  Turns on an LED on for a while, then off for a while, repeatedly. 
  You can use serial commands to control the way it blinks. 
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
  Pin 13 has the LED on Teensy 3.x
*/
int ledPin = 13;


// Blink parameters
int ledOnDuration = 1000;   // the duration (ms) of LED being on when blinking
int ledOffDuration = 1000;  // the duration (ms) of LED being off when blinking


void setup()
{
  // Initialize serial (not necessary on Teensy)
  Serial.begin(115200);
  /*
    On your computer, make sure the baud rate is consistent 
    and add either (or both) newline (NL) and carriage return (CR) to outgoing messages
  */
  
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
  digitalWrite(ledPin, HIGH);     // turn the LED on (HIGH is the voltage level)
  delay(ledOnDuration);           // wait for the specified time
  
  digitalWrite(ledPin, LOW);      // turn the LED off by making the voltage LOW
  delay(ledOffDuration);          // wait for the specified time
}


// We define a function myReader (or use whatever name you like) to handle serial commands.
void myReader()
{
  /*
    This function is called by each part of a input serial command, respectively and sequentially.
    It takes no input and return nothing.
    
    Let's say a user sends "NAME,123,456,789" (followed by a return character). It contains four 
    parts separated by comma delimiters, thus myReader will be run four times. In each function 
    call, you can get three variables - command name string, index and value. 
      When myReader is called at "NAME", the command name string is "NAME", index is 0, value is always 0;
      when at "123", the command name string is "NAME", index is 1, value is 123; 
      when at "456", the command name string is "NAME", index is 2, value is 456; 
      when at "789", the command name string is "NAME", index is 3, value is 789. 
    
    Here are the rules for a legal command: 
      1) It begins with a command name. 
      2) The command name is followed by an arbitrary number of values (including no value).
      3) The command name and each value (if any) are separated by delimiter character.
      4) The command name and values should (obviously) not contain delimiter character.
      5) Values can only be integer numbers (can be negative). Non-numarical characters will be ignored. 
      6) The value and index at command name are both 0.
      7) If there is no value between two delimiters, the value will be 0 by default.
      8) A command will not be processed without a newline or carriage return at the end. 
  */

  
  // Get command information
  String cmdStr = sr.getCmdName();  // get command name string
  int idx = sr.getIndex();          // get current index
  long val = sr.getValue();         // get current value


  // Do specific things based on the command name, index and value
  if (idx == 1 && cmdStr.equals("OnDur"))
  {
    // Update ledOnDuration when the command is "OnDur" and when it is the first value
    // An example command could be "OnDur,1000", where 1000 is the first value of this command
    ledOnDuration = val;
  }
  else if (idx == 1 && cmdStr.equals("OffDur"))
  {
    // Update ledOffDuration when the command is "OffDur" and when it is the first value
    // An example command could be "OffDur,1500", where 1500 is the first value of this command
    ledOffDuration = val;
  }
  else if (idx == 1 && cmdStr.equals("OnOffDur"))
  {
    // Update ledOnDuration when the command is "OnOffDur" and when it is the first value
    // An example command could be "OnOffDur,1000,1500", where 1000 is the first value of this command
    ledOnDuration = val;
  }
  else if (idx == 2 && cmdStr.equals("OnOffDur"))
  {
    // Update ledOffDuration when the command is "OnOffDur" and when it is the second value
    // An example command could be "OnOffDur,1000,1500", where 1500 is the second value of this command
    ledOffDuration = val;
  }
  else if (idx == 0 && cmdStr.equals("Pause five sec"))
  {
    // Pause blinking for 5 seconds when the command is "Pause five sec" and when there is no value
    delay(5000);
  }
}





