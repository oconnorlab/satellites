#include "ManyRig.h"

ManyRig::ManyRig()
{
	// Define pins in array
	lickDetectorPin = 14;
	lickDetectorPinAUX = 22; // perch lick detector
	randPin = 28;

	waterValvePin = 4;
	framePin = 6;
	servoPin = 9;
	numPin = 16;	   // trial number
	camPin = 17;	   // camera
	wsPin = 18;		   // opto
	audioPins[0] = 20; // cue
	audioPins[1] = 21; //

	// Setup pin mode
	pinMode(lickDetectorPin, INPUT);
	pinMode(lickDetectorPinAUX, INPUT);
	pinMode(randPin, INPUT);

	pinMode(waterValvePin, OUTPUT);
	pinMode(framePin, OUTPUT);
	pinMode(numPin, OUTPUT);
	pinMode(camPin, OUTPUT);
	pinMode(wsPin, OUTPUT);

	for (int i = 0; i < 2; i++)
		pinMode(audioPins[i], OUTPUT);

	// Set random seed from an unused analog pin
	randomSeed(randPin);
}

bool ManyRig::isLickOn()
{
	return digitalRead(lickDetectorPin) == HIGH;
}

bool ManyRig::isLickOnAUX() 
{
	return digitalRead(lickDetectorPinAUX) == HIGH;
}

void ManyRig::triggerSound(byte idx, unsigned long durInMs)
{
	digitalWrite(audioPins[idx], HIGH);
	delay(durInMs);
	digitalWrite(audioPins[idx], LOW);
}

void ManyRig::deliverWater(unsigned long durInMs)
{
	digitalWrite(waterValvePin, HIGH);
	delay(durInMs);
	digitalWrite(waterValvePin, LOW);
}

void ManyRig::sendTTL(byte pin, unsigned long durInMs)
{
	// Send TTL in millisecond.

	digitalWrite(pin, HIGH);
	delayMicroseconds(durInMs * 1000);
	digitalWrite(pin, LOW);
}

byte ManyRig::choose(byte *probVector, byte numChoices)
{
	byte randNum = random(0, 100);
	int sumProb = 0;

	for (byte i = 0; i < numChoices; i++)
	{
		sumProb = sumProb + probVector[i];

		if (i == numChoices - 1)
			sumProb = 100;

		if (randNum < sumProb)
			return i;
	}

	return 0;
}
