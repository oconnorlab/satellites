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
    sr.delay(itiDur);

    // Wait for animal to stop licking for a while
    sr.delayContinue(isLickPinHigh, noLickDur);

    // Wait for licking response
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





