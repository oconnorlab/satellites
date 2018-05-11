/*
Satellites.h - Library facilitating the control of behavioral experiments.
Created by Duo Xu, September 24, 2016.
Latest update on November 24, 2017.
Released into the public domain.
*/

#ifndef Satellites_h
#define Satellites_h



#include "Arduino.h"
#include "boardnames.h"


class Satellites
{
public:
	Satellites();

	void setDelimiter(char d);
	char getDelimiter();

	// Handling incoming messages
	void attachReader(void(*f)(void));
	void detachReader();
	unsigned int getIndex();
	unsigned long getValue();
	String getCmdName();

	void serialRead();
	void serialReadCmd();
	void delay(unsigned long dur);
	bool delayUntil(bool(*f)(void));
	bool delayUntil(bool(*f)(void), unsigned long timeout);
	bool delayContinue(bool(*f)(void), unsigned long unitTime);

	// Sending formatted data message
	void setSerial(usb_serial_class* s);
	void setSerial(HardwareSerial* s);

	// Format and send data message
	unsigned long sendData(const char* tag, unsigned long t = millis());
	unsigned long sendData(const char* tag, unsigned long t, volatile byte num);
	unsigned long sendData(const char* tag, unsigned long t, volatile int num);
	unsigned long sendData(const char* tag, unsigned long t, volatile unsigned int num);
	unsigned long sendData(const char* tag, unsigned long t, volatile long num);
	unsigned long sendData(const char* tag, unsigned long t, volatile unsigned long num);
	unsigned long sendData(const char* tag, unsigned long t, volatile float num);
	unsigned long sendData(const char* tag, unsigned long t, volatile byte* dataArray, byte numData);
	unsigned long sendData(const char* tag, unsigned long t, volatile int* dataArray, byte numData);
	unsigned long sendData(const char* tag, unsigned long t, volatile unsigned int* dataArray, byte numData);
	unsigned long sendData(const char* tag, unsigned long t, volatile long* dataArray, byte numData);
	unsigned long sendData(const char* tag, unsigned long t, volatile unsigned long* dataArray, byte numData);
	unsigned long sendData(const char* tag, unsigned long t, volatile float* dataArray, byte numData);

	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t = millis());
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile byte num);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile int num);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile unsigned int num);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile long num);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile unsigned long num);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile float num);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile byte* dataArray, byte numData);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile int* dataArray, byte numData);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile unsigned int* dataArray, byte numData);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile long* dataArray, byte numData);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile unsigned long* dataArray, byte numData);
	unsigned long sendData(const __FlashStringHelper* tag, unsigned long t, volatile float* dataArray, byte numData);

protected:
	// Parsing
	char _delimiter = ',';
	unsigned int _numDelimiter = 0;
	long _inputVal = 0;
	long _inputSign = 1;
	String _cmdString = String();
	void (*_parserFunc)(void) = NULL;

	// Sending
	Stream* _serial = &Serial;
	void serialSend(String);

};

#endif