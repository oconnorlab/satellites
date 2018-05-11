/*
ManyRig.h - Library for rig specific utilities.
Created by Duo Xu, November 23, 2017.
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
	byte pawDetectorPin;
	byte randPin;

	byte waterValvePin;
	byte speakerPin;
	byte airPuffPin;
	byte odorEmptyPin;
	byte odorPins[2];
	byte numPin;
	byte camPin;
	byte wsPin;
	byte audioPins[2];
	byte servoPin;

	// IO
	bool isPawOn();
	bool isLickOn();
	void playTone(unsigned int freq, unsigned long durInMs);
	void playSweep(unsigned int freqStart, unsigned int freqEnd, unsigned long durInMs);
	void playNoise(unsigned long durInMs);
	void deliverWater(unsigned long durInMs);
	void deliverOdor(byte odorId, unsigned long durInMs);
	void deliverAirPuff(unsigned long durInMs);
	void sendTTL(byte pin, unsigned long ms);

	// Computing
	byte choose(byte* probVector, byte numChoices);

private:

};



class Position
{
protected:
	long _x = 0, _y = 0;
	float _a = 0, _r = 0;

	void updatePolar() {
		_a = atan(double(_x) / double(_y)) * 180 / PI;
		_r = sqrt(pow(double(_x), 2) + pow(double(_y), 2));
	}
	void updateCartesian() {
		_x = sin(_a / 180.0 * PI) * _r;
		_y = cos(_a / 180.0 * PI) * _r;
	}

public:
	Position() {};
	Position(long x, long y) : _x(x), _y(y) { updatePolar(); }
	Position(float a, float r) : _a(a), _r(r) { updateCartesian(); }

	long getX() { return _x; }
	long getY() { return _y; }
	long getA() { return _a; }
	long getR() { return _r; }
	void setX(long x) { _x = x; updatePolar(); }
	void setY(long y) { _y = y; updatePolar(); }
	void setA(long a) { _a = a; updateCartesian(); }
	void setR(long r) { _r = r; updateCartesian(); }

	Position operator+(const Position& p) {
		Position pp(this->_x + p._x, this->_y + p._y);
		return pp;
	}
	Position operator-(const Position& p) {
		Position pp(this->_x - p._x, this->_y - p._y);
		return pp;
	}
	Position operator=(const Position& p) {
		Position pp(p._x, p._y);
		return pp;
	}
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