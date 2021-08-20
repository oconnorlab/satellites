#include <Satellites.h>

// Satellite object
Satellites sat;

// Runtime variables
unsigned long samplingRate = 60;
const byte numChan = 4;
byte pins[] = {0, 1, 2, 3};
unsigned int vals[numChan];
bool isStream = false;

void setup() {
  // Communication
  Serial.begin(115200);
  sat.attachReader(myReader);
}

void loop() {
  sat.delay(1000. / samplingRate);
  if (isStream)
    readAndReport();
}

void readAndReport() {
  for (int i = 0; i < numChan; i++)
    vals[i] = analogRead(pins[i]);

  sat.sendData("i", millis(), vals, numChan);
}

// We define a function myReader (or use whatever name you like) to handle serial commands.
void myReader()
{
  // Get command information
  String cmdStr = sat.getCmdName();
  int idx = sat.getIndex();
  long val = sat.getValue();


  // Do specific things based on the command name, index and value
  if (idx > 0 && cmdStr.equals("pins"))
  {
    pins[idx-1] = val;
    if (idx == 4)
      sat.sendData("pins to read from", millis(), pins, numChan);
  }
  else if (idx == 1 && cmdStr.equals("spr"))
  {
    samplingRate = val;
    sat.sendData("sampling rate set", millis(), samplingRate);
  }
  else if (idx == 0 && cmdStr.equals("i"))
  {
    readAndReport();
  }
  else if (idx == 0 && cmdStr.equals("s"))
  {
    isStream = !isStream;
  }
}
