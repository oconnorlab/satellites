#include "Arduino.h"
#include "Satellites.h"

#ifndef ZaberMotor_h
#define ZaberMotor_h

class ZaberMotor
{
public:
	static const long maxPos[2];
    bool isReverse[2];
	
    ZaberMotor();
    
	void setSerial(Stream* sObj);
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
    void streamCirc(long centrex, long centrey);
    void streamCork();
    void streamUncork();

	void read();
    
private:
    Stream* _serial = &Serial3;
	long _refPos[2];
    int _jitRange = 0;
    bool _isStream = false;
	
    int genJitter();
	long convert(long pos, byte axId);
};

#endif
