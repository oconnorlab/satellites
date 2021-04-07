/*
ManyRig.h - Library for rig specific utilities.
Created by Duo Xu, November 23, 2017.
Last updated by Duo Xu, March 17, 2019.
*/

#ifndef ManyRig_h
#define ManyRig_h

#include "Arduino.h"

class ManyRig
{
public:
	ManyRig();

	// Pin-out (values are defined in constructor)
	byte lickDetectorPin;
	byte lickDetectorPinAUX;
	byte randPin;

	byte waterValvePin;
	byte framePin;
	byte numPin;
	byte camPin;
	byte wsPin;
	byte audioPins[2];
	byte servoPin;

	// IO
	bool isLickOn();
	bool isLickOnAUX();
	void triggerSound(byte idx, unsigned long durInMs);
	void deliverWater(unsigned long durInMs);
	void sendTTL(byte pin, unsigned long durInMs);

	// Computing
	byte choose(byte* probVector, byte numChoices);

private:

};

class Interval
{
private:
	static double expDist(double meanVal) {
		return -meanVal * log(1.0 - double(random(0, 1e6)) / 1.0e6);
	}

public:
	unsigned long fixedDur = 2000, meanRandDur = 2000, upperRandLim = 6000, lowerRandLim = 0;
	unsigned long randomDur = 0;
	unsigned long nextRandom() {
		do {
			randomDur = expDist(meanRandDur);
		} while (randomDur > upperRandLim || randomDur < lowerRandLim);
		return randomDur;
	}
};

#endif