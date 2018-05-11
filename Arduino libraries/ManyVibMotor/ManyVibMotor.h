/*
ManyVibMotor.h - Library for actuating vibration motor with PWM.
Created by Duo Xu, August 21, 2016.
Released into the public domain.
*/

#ifndef ManyVibMotor_h
#define ManyVibMotor_h

#include "Arduino.h"

class ManyVibMotor
{
public:
	ManyVibMotor(byte pin);

	void vibrate();
	void vibrate(unsigned int val);
	void vibrateDutyCycle(byte prct);
	void stop();

	byte getDutyCycle();
	void setResolution(byte res);
	byte getResolution();

private:
	byte _pin;
	byte _dutyCycle = 100;
	byte _resolution = 8;

	unsigned int dutyCycle2val(byte prct);
	byte val2dutyCycle(unsigned int val);

};

#endif