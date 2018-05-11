/*
ManyStepper.h - Library for actuating stepper motor.
Created by Duo Xu, August 19, 2016.
Released into the public domain.
*/

#ifndef ManyStepper_h
#define ManyStepper_h

#include "Arduino.h"

class ManyStepper
{
public:
	ManyStepper(byte pin0, byte pin1, byte pin2, byte pin3);

	void step(int numSteps);

	void setPeriod(unsigned int periodInMs);
	unsigned int getPeriod();
	
	void setActionTime(unsigned int actionTimeInMs);
	unsigned int getActionTime();

	void enableHolding();
	void disableHolding();
	bool isHolding();

private:
	byte _pins[4];
	byte _thisStep = 3;
	unsigned int _actionTimeInMs = 50;
	unsigned int _periodInMs = 50;
	bool _isHolding = false;

	void unitStep();

};

#endif