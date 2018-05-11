// Detection task protocol
void DetectionTask()
{
  // Report the start of training
  sr.sendData("detectionTaskStart");

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

    // Present stimulus
    /*
       Here stimulus is delivered in every trial. We can certainly make it probalistic 
       but it is not the focus of this example. 
    */
    unsigned long stimOnTime = millis();
    digitalWrite(ledPin, HIGH);
    delay(stimDur);
    digitalWrite(ledPin, LOW);
    sr.sendData("stimulus delivered", stimOnTime, millis() - stimOnTime);

    // Wait for licking response
    /*
       This delayUntil method blocks the code until isLickPinHigh returns true or 
       up to responseWinDur, whichever is the earliest. 
    */
    bool isLicked = sr.delayUntil(isLickPinHigh, responseWinDur);

    // Deliver water reward if animal licked
    if (isLicked)
    {
      unsigned long valveOnTime = millis();

      digitalWrite(valvePin, HIGH);
      delay(waterDur);
      digitalWrite(valvePin, LOW);

      sr.sendData("water delivered", valveOnTime, millis() - valveOnTime);

      // Report result
      sr.sendData("hit");
    }
    else
    {
      // Report result
      sr.sendData("miss");
    }
  }

  // Report the end of training
  sr.sendData("detectionTaskEnd");
}





