/*
ManyStepper.cpp - Library for actuating stepper motor.
Created by Duo Xu, August 19, 2016.
Released into the public domain.
*/

#include "Arduino.h"
#include "ManyStepper.h"

ManyStepper::ManyStepper(byte pin0, byte pin1, byte pin2, byte pin3)
{
	_pins[0] = pin0;
	_pins[1] = pin1;
	_pins[2] = pin2;
	_pins[3] = pin3;

	for (int i = 0; i < 4; i++)
	{
		pinMode(_pins[i], OUTPUT);
	}

	//step(1);
}



void ManyStepper::setActionTime(unsigned int actionTimeInMs)
{
	_actionTimeInMs = actionTimeInMs;
}

unsigned int ManyStepper::getActionTime()
{
	return _actionTimeInMs;
}

void ManyStepper::setPeriod(unsigned int periodInMs)
{
	_periodInMs = periodInMs;
}

unsigned int ManyStepper::getPeriod()
{
	return _periodInMs;
}

void ManyStepper::enableHolding()
{
	_isHolding = true;

	// Set the pin specified by _thisStep
	int level[] = { LOW, LOW, LOW, LOW };
	for (byte i = 0; i < 4; i++)
	{
		if (i == _thisStep)
		{
			level[3 - i] = HIGH;
		}
		digitalWrite(_pins[3 - i], level[3 - i]);
	}
}

void ManyStepper::disableHolding()
{
	_isHolding = false;

	// Clear all pins
	for (byte i = 0; i < 4; i++)
		digitalWrite(_pins[3 - i], LOW);
}

bool ManyStepper::isHolding()
{
	return _isHolding;
}



void ManyStepper::step(int numSteps)
{
	if (numSteps > 0)
		for (int i = numSteps; i > 0; i--)
		{
			if (_thisStep < 3)
				_thisStep++;
			else
				_thisStep = 0;

			unitStep();
		}
	else
		for (int i = numSteps; i < 0; i++)
		{
			if (_thisStep > 0)
				_thisStep--;
			else
				_thisStep = 3;

			unitStep();
		}
}



void ManyStepper::unitStep()
{
	// Set the pin specified by _thisStep
	int level[] = { LOW, LOW, LOW, LOW };
	for (byte i = 0; i < 4; i++)
	{
		if (i == _thisStep)
		{
			level[3-i] = HIGH;
		}
		digitalWrite(_pins[3-i], level[3-i]);
	}

	// keep this output for a while before the next step
	delay(min(_actionTimeInMs, _periodInMs));

	// Turn off all pins for reducing heating, if enabled
	if (!_isHolding)
	{
		for (byte i = 0; i < 4; i++)
			digitalWrite(_pins[3 - i], LOW);
	}

	// Wait additional time to ensure the stepping period
	if (_periodInMs > _actionTimeInMs)
	{
		delay(_periodInMs - _actionTimeInMs);
	}
}