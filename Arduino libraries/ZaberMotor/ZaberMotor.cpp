#include "Arduino.h"
#include "ZaberMotor.h"



const long ZaberMotor::maxPos[2] = {100000,50000};

ZaberMotor::ZaberMotor()
{
	// Initialze array variables
	for (int i = 0; i < 1; i++) {
		isReverse[i] = false;
		_refPos[i] = 0;
	}
}

void ZaberMotor::setSerial(Stream* sObj)
{
	_serial = sObj;
}

void ZaberMotor::setRef(long ref, byte axId)
{
	if (axId > 2)
		return;

	_refPos[axId-1] = ref;
}

long ZaberMotor::getRef(byte axId)
{
	if (axId > 2)
		return -1;

	return _refPos[axId - 1];
}

void ZaberMotor::setJitter(int n)
{
	_jitRange = n;
}

void ZaberMotor::setMaxSpeed(long v)
{
	String str = "/01 0 set maxspeed ";
	str.concat(v);
	_serial->println(str);
	streamDisable();
}

void ZaberMotor::setAcceleration(int a)
{
	String str = "/01 0 set accel ";
	str.concat(a);
	_serial->println(str);
	streamDisable();
}

void ZaberMotor::home(byte axId)
{
    if (axId > 2)
        return;
    
    String str = "/01 ";
    str.concat(axId);
    str.concat(" home");
    _serial->println(str);
    _isStream = false;
}

void ZaberMotor::move(long pos, byte axId)
{
	if (axId > 2)
		return;

	pos = convert(pos, axId);
	String str = "/01 ";
	str.concat(axId);
	str.concat(" move abs ");
	str.concat(pos);
	_serial->println(str);
	_isStream = false;
}

void ZaberMotor::moveMax(byte axId)
{
	if (axId > 2)
		return;

    String str = "/01 ";
    str.concat(axId);
    str.concat(" move max");
    _serial->println(str);
	_isStream = false;
}

void ZaberMotor::streamLive()
{
	if (!_isStream) {
		_serial->println("/01 0 stream 1 setup live 1 2");
		_isStream = true;
	}
}

void ZaberMotor::streamDisable()
{
	_serial->println("/01 0 stream 1 setup disable");
	_isStream = false;
}

void ZaberMotor::streamCork()
{
	_serial->println("/01 0 stream 1 fifo cork");
}

void ZaberMotor::streamUncork()
{
	_serial->println("/01 0 stream 1 fifo uncork");
}

void ZaberMotor::streamLine(long pos1, long pos2)
{
	pos1 = convert(pos1, 1);
	pos2 = convert(pos2, 2);

	streamLive();

	String str = "/01 0 stream 1 line abs ";
	str = str.concat(pos1) + " ";
	str.concat(pos2);
	_serial->println(str);
}

void ZaberMotor::streamArc(long centerx, long centery, long endx, long endy)
{
    centerx = convert(centerx, 1);
    centery = convert(centery, 2);
    endx = convert(endx, 1);
    endy = convert(endy, 2);

    streamLive();

	String str = "/01 0 stream 1 arc abs cw ";
    str = str.concat(centerx) + " ";
    str = str.concat(centery) + " ";
	str = str.concat(endx) + " ";
	str.concat(endy);
	_serial->println(str);
}

void ZaberMotor::streamCirc(long centerx, long centery)
{
    centerx = convert(centerx, 1);
    centery = convert(centery, 2);

	streamLive();

	String str = "/01 0 stream 1 circle abs cw ";
	str = str.concat(centerx) + " ";
	str.concat(centery);
	_serial->println(str);
}

long ZaberMotor::convert(long pos, byte axId)
{
	pos = pos + _refPos[axId-1] + genJitter();
	if (isReverse[axId-1]) {
		pos = maxPos[axId-1] - pos;
	}
	pos = constrain(pos, 0, maxPos[axId - 1]);
	pos = pos / 0.1905;
	return pos;
}

int ZaberMotor::genJitter()
{
	return random(-_jitRange, _jitRange + 1);
}

void ZaberMotor::read()
{
	char ch;
	while (_serial->available()) {
		ch = _serial->read();
		Serial.print(ch);
	}
}
