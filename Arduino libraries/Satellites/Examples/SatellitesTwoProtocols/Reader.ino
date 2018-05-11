
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
  else if (idx == 1 && cmdStr.equals("DTT"))
  {
    // Execute detection task protocol
    DetectionTask();
  }
  else if (idx == 1 && cmdStr.equals("STD"))
  {
    // Change visual stimulus duration
    stimDur = val;
    sr.sendData("stimDur set", millis(), stimDur);
  }
  else if (idx == 1 && cmdStr.equals("RWD"))
  {
    // Change response window duration
    responseWinDur = val;
    sr.sendData("responseWinDur set", millis(), responseWinDur);
  }
  else if (idx == 1 && cmdStr.equals("v"))
  {
    // Manually present visual stimulation
    unsigned long stimOnTime = millis();

    digitalWrite(ledPin, HIGH);
    delay(val);
    digitalWrite(ledPin, LOW);

    sr.sendData("visual stim delivered", stimOnTime, val);
  }
}





