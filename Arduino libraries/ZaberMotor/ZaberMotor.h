#ifndef ZaberMotor_h
#define ZaberMotor_h

#include "Arduino.h"

class ZaberMotor
{
public:
	ZaberMotor(Stream& serial);

	static const long maxPos[2];
    bool isReverse[2];
    
    void setRef(long ref, byte axId = 1);
	long getRef(byte axId = 1);
    void setJitter(int n);
	void setMaxSpeed(long v);
	void setAcceleration(int a);

	void home(byte axId = 0);

    void move(long pos, byte axId = 1);
    void moveMax(byte axId = 0);
    
    void streamLive();
	void streamDisable();
    void streamLine(long pos1, long pos2);
    void streamArc(long centerx, long centery, long endx, long endy);
    void streamArc2(long startx, long starty, long endx, long endy);
    void streamCirc(long centrex, long centrey);
    void streamCork();
    void streamUncork();

	void read();
    
private:
    Stream& _serial;
	long _refPos[2];
    int _jitRange = 0;
    bool _isStream = false;
	
    int genJitter();
	long convert(long pos, byte axId);
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

#endif