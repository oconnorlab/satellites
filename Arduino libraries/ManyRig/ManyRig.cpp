/*
ManyRig.cpp - Library for rig specific utilities.
Created by Duo Xu, November 23, 2017.
*/

#include "Arduino.h"
#include "ManyRig.h"

ManyRig::ManyRig()
{
	// Define pins in array
	lickDetectorPin = 14;
	pawDetectorPin = 15;
	randPin = 28;

	waterValvePin = 4;
	speakerPin = 6;
	servoPin = 9;
	numPin = 16;		// trial number
	camPin = 17;		// camera
	wsPin = 18;			// opto
	audioPins[0] = 20;	// cue
	audioPins[1] = 21;	// 
	frontVibratorPin = 22;
	backVibratorPin = 23;


	// Setup pin mode
	pinMode(lickDetectorPin, INPUT);
	pinMode(pawDetectorPin, INPUT);
	pinMode(randPin, INPUT);

	pinMode(waterValvePin, OUTPUT);
	pinMode(speakerPin, OUTPUT);
	pinMode(numPin, OUTPUT);
	pinMode(camPin, OUTPUT);
	pinMode(wsPin, OUTPUT);

	for (int i = 0; i < 2; i++)
		pinMode(audioPins[i], OUTPUT);


	// Set random seed from an unused analog pin
	randomSeed(randPin);
}

bool ManyRig::isPawOn()
{
	return digitalRead(pawDetectorPin) == HIGH;
}

bool ManyRig::isLickOn()
{
	return digitalRead(lickDetectorPin) == HIGH;
}

void ManyRig::playTone(unsigned int freq, unsigned long durInMs)
{
	if (durInMs > 0) {
		tone(speakerPin, freq, durInMs);
		delay(durInMs);
	}
}

void ManyRig::playSweep(unsigned int freqStart, unsigned int freqEnd, unsigned long durInMs)
{
	unsigned int dT = 10;
	unsigned int numSteps = durInMs / dT;
	unsigned int dFreq = (freqEnd - freqStart) / numSteps;

	unsigned long t0 = millis();
	unsigned int currentStep = 0;

	while (currentStep < numSteps)
	{
		if (millis() - t0 >= dT)
		{
			currentStep++;
			t0 = millis();
			tone(speakerPin, freqStart + currentStep * dFreq);
		}
	}
	noTone(speakerPin);
}

void ManyRig::playNoise(unsigned long durInMs)
{
	unsigned long dur = durInMs * 1e3;
	unsigned long t = micros();

	while (micros() - t < dur)
		digitalWrite(speakerPin, random(2));

	digitalWrite(speakerPin, LOW);
}

void ManyRig::deliverWater(unsigned long durInMs)
{
	digitalWrite(waterValvePin, HIGH);
	delay(durInMs);
	digitalWrite(waterValvePin, LOW);
}

void ManyRig::deliverOdor(byte odorId, unsigned long durInMs)
{
	digitalWrite(odorPins[odorId], HIGH);
	digitalWrite(odorEmptyPin, HIGH);
	delay(durInMs);
	digitalWrite(odorEmptyPin, LOW);
	digitalWrite(odorPins[odorId], LOW);
}

void ManyRig::deliverAirPuff(unsigned long durInMs)
{
	digitalWrite(airPuffPin, HIGH);
	delay(durInMs);
	digitalWrite(airPuffPin, LOW);
}

void ManyRig::sendTTL(byte pin, unsigned long ms)
{
	// Send TTL in millisecond. 

	digitalWrite(pin, HIGH);
	delayMicroseconds(ms * 1000);
	digitalWrite(pin, LOW);
}

byte ManyRig::choose(byte* probVector, byte numChoices)
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


