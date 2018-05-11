/*
Satellites.h - Library facilitating the control of behavioral experiments.
Created by Duo Xu, September 24, 2016.
Latest update on September 7, 2017.
Released into the public domain.
*/

#include "Arduino.h"
#include "Satellites.h"



Satellites::Satellites() {
	// do nothing
}

void Satellites::setDelimiter(char d) {
	_delimiter = d;
}

char Satellites::getDelimiter() {
	return _delimiter;
}



void Satellites::attachReader(void(*f)(void)) {
	_parserFunc = f;
}

void Satellites::detachReader() {
	_parserFunc = NULL;
}

unsigned int Satellites::getIndex() {
	return _numDelimiter;
}

unsigned long Satellites::getValue() {
	return _inputSign * _inputVal;
}

String Satellites::getCmdName() {
	return _cmdString;
}

void Satellites::serialRead() {
	// Handle command identification and dispatching

	if (_serial->available())
	{
		// Read byte as char
		char ch = _serial->read();

		if (_numDelimiter > 0 && isDigit(ch))
		{
			// Accumulate digits to assemble the incoming value
			_inputVal = _inputVal * 10 + ch - '0';
		}
		else if (_numDelimiter > 0 && ch == '-')
		{
			// Flip sign
			_inputSign = -_inputSign;
		}
		else if (ch == _delimiter || isControl(ch))
		{
			// Parse command and incoming value
			if (_parserFunc != NULL && _cmdString.length() > 0)
				_parserFunc();

			// Clear incoming value of the current input
			_inputVal = 0;
			_inputSign = 1;
		}
		else if (_numDelimiter < 1)
		{
			// Accumulate other characters to assemble the incoming string
			_cmdString += ch;
		}

		// Keep track of the number of delimiters for indexing inputs
		if (ch == _delimiter)
			_numDelimiter++;

		// Reset reader state for identification
		if (isControl(ch))
		{
			_cmdString = "";
			_numDelimiter = 0;
		}
	}
}

void Satellites::serialReadCmd() {
	// Read full serial input

	while (_serial->available())
	{
		serialRead();
	}
}


void Satellites::delay(unsigned long dur) {
	// Delay and read serial command

	unsigned long t0 = millis();
	while (millis() - t0 < dur)
		serialRead();
}

bool Satellites::delayUntil(bool(*f)(void)) {
	// Delay and read serial command until function returns true

	bool b = false;

	while (!b) {
		serialRead();
		b = f();
	}

	return b;
}

bool Satellites::delayUntil(bool(*f)(void), unsigned long timeout) {
	// Delay and read serial command until function returns true or timeout

	bool b = false;

	unsigned long t0 = millis();
	while (millis() - t0 < timeout && !b) {
		serialRead();
		b = f();
	}

	return b;
}

bool Satellites::delayContinue(bool(*f)(void), unsigned long unitTime) {
	// Delay and read serial command. Reiterates delay when function returns true

	bool b = false;
	unsigned long t0 = millis();
	unsigned long t = t0;

	while (millis() - t < unitTime) {
		serialRead();
		if (f()) {
			t = millis();
			b = true;
		}
	}

	return b;
}



void Satellites::setSerial(usb_serial_class* s) {
	_serial = s;
}

void Satellites::setSerial(HardwareSerial* s) {
	_serial = s;
}

void Satellites::serialSend(String msg) {
	_serial->println(msg);
}

unsigned long Satellites::sendData(const char* tag, unsigned long t) {
	// Send data message with the header

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile byte num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile int num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile unsigned int num) {
	// Send data message by event type, time, and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile long num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile unsigned long num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile float num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile byte* dataArray, byte numData) {
	// Send data message with the header and an array of bytes, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile int* dataArray, byte numData) {
	// Send data message with the header and an array of ints, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile unsigned int* dataArray, byte numData) {
	// Send data message with the header and an array of unsigned ints, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile long* dataArray, byte numData) {
	// Send data message with the header and an array of long integers, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile unsigned long* dataArray, byte numData) {
	// Send data message with the header and an array of unsigned long integers, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const char* tag, unsigned long t, volatile float* dataArray, byte numData) {
	// Send data message with the header and an array of floating point numbers, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t) {
	// Send data message with the header

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile byte num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile int num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile unsigned int num) {
	// Send data message by event type, time, and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile long num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile unsigned long num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile float num) {
	// Send data message with the header and value

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;
	msg += _delimiter;
	msg += num;

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile byte* dataArray, byte numData) {
	// Send data message with the header and an array of bytes, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile int* dataArray, byte numData) {
	// Send data message with the header and an array of ints, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile unsigned int* dataArray, byte numData) {
	// Send data message with the header and an array of unsigned ints, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile long* dataArray, byte numData) {
	// Send data message with the header and an array of long integers, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile unsigned long* dataArray, byte numData) {
	// Send data message with the header and an array of unsigned long integers, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}

unsigned long Satellites::sendData(const __FlashStringHelper* tag, unsigned long t, volatile float* dataArray, byte numData) {
	// Send data message with the header and an array of floating point numbers, separated by commas

	unsigned long tStart = micros();

	String msg = String();

	msg += tag;
	msg += _delimiter;
	msg += t;

	for (int i = 0; i < numData; i++) {
		msg += _delimiter;
		msg += dataArray[i];
	}

	serialSend(msg);

	return micros() - tStart;
}