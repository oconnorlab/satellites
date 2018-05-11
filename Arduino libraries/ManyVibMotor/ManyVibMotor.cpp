/*
ManyVibMotor.cpp - Library for actuating vibration motor with PWM.
Created by Duo Xu, August 21, 2016.
Released into the public domain.
*/

#include "Arduino.h"
#include "ManyVibMotor.h"

ManyVibMotor::ManyVibMotor(byte pin)
{
	_pin = pin;
	pinMode(_pin, OUTPUT);
}



void ManyVibMotor::setResolution(byte res)
{
	_resolution = res;
}

byte ManyVibMotor::getResolution()
{
	return _resolution;
}

byte ManyVibMotor::getDutyCycle()
{
	return _dutyCycle;
}


void ManyVibMotor::vibrate()
{
	analogWrite(_pin, dutyCycle2val(_dutyCycle));
}

void ManyVibMotor::vibrate(unsigned int val)
{
	val = min(val, pow(2, _resolution) - 1);
	analogWrite(_pin, val);
	_dutyCycle = val2dutyCycle(val);
}

void ManyVibMotor::vibrateDutyCycle(byte prct)
{
	_dutyCycle = max(min(prct,  100),  0);
	analogWrite(_pin, dutyCycle2val(_dutyCycle));
}

void ManyVibMotor::stop()
{
	analogWrite(_pin, 0);
}



byte ManyVibMotor::val2dutyCycle(unsigned int val)
{
	return min(float(val) / float(pow(2, _resolution) - 1), 1) * 100;
}

unsigned int ManyVibMotor::dutyCycle2val(byte prct)
{
	return float(max(min(prct, 100), 0)) / 100 * (pow(2, _resolution) - 1);
}