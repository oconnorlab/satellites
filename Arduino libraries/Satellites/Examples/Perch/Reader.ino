// Reading Command
void myReader()
{
  // Find the index of the incoming value
  String cmdStr = rig.getCmdName();
  unsigned long val = rig.getValue();
  unsigned int idx = rig.getIndex();
  
  // Parse by command string and the index of input value
  if (idx == 0 && cmdStr.equals("i"))
  {
    sendInputReadings();
  }
  else if (idx == 0 && cmdStr.equals("s"))
  {
    isStreamInputReadings = !isStreamInputReadings;
  }
  else if (idx == 1 && cmdStr.equals("f"))
  {
    forepawVibrator.vibrateDutyCycle(min(val, 70));
    Serial.print(F("Vibrator duty cycle set to "));
    Serial.println(forepawVibrator.getDutyCycle());
  }
  else if (idx == 1 && cmdStr.equals("h"))
  {
    hindpawVibrator.vibrateDutyCycle(min(val, 70));
    Serial.print(F("Vibrator duty cycle set to "));
    Serial.println(hindpawVibrator.getDutyCycle());
  }
  else if (idx == 0 && cmdStr.equals("RIG"))
  {
    Serial.println("YES");
  }
  else if (idx == 1 && cmdStr.equals("SPF"))
  {
    unsigned long period = 1e6 / val;
    samplingFreq = val;
    Timer1.setPeriod(period);
    
    Serial.print(F("Sampling frequency set to "));
    Serial.print(val);
    Serial.println("Hz");
  }
}










