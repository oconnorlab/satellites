/*
boardnames.h - Code for determining the Arduino board type
From StackExchang https://arduino.stackexchange.com/questions/21137/arduino-how-to-get-the-board-type-in-code March 1, 2016
Modified by Many Xu, August 1, 2017
*/


#if defined(TEENSYDUINO) 

//  --------------- Teensy -----------------

#if defined(__AVR_ATmega32U4__)
#define BOARD_NAME "Teensy 2.0"
#elif defined(__AVR_AT90USB1286__)       
#define BOARD_NAME "Teensy++ 2.0"
#elif defined(__MK20DX128__)       
#define BOARD_NAME "Teensy 3.0"
#elif defined(__MK20DX256__)       
#define BOARD_NAME "Teensy 3.1" // and Teensy 3.2
#elif defined(__MKL26Z64__)       
#define BOARD_NAME "Teensy LC"
#elif defined(__MK66FX1M0__)
#define BOARD_NAME "Teensy++ 3.0" // coming soon
#else
#error "Unknown board"
#endif

#else // --------------- Arduino ------------------

#if defined(ARDUINO_AVR_ADK)       
#define BOARD_NAME "Mega Adk"
#elif defined(ARDUINO_AVR_BT)    // Bluetooth
#define BOARD_NAME "Bt"
#elif defined(ARDUINO_AVR_DUEMILANOVE)       
#define BOARD_NAME "Duemilanove"
#elif defined(ARDUINO_AVR_ESPLORA)       
#define BOARD_NAME "Esplora"
#elif defined(ARDUINO_AVR_ETHERNET)       
#define BOARD_NAME "Ethernet"
#elif defined(ARDUINO_AVR_FIO)       
#define BOARD_NAME "Fio"
#elif defined(ARDUINO_AVR_GEMMA)
#define BOARD_NAME "Gemma"
#elif defined(ARDUINO_AVR_LEONARDO)       
#define BOARD_NAME "Leonardo"
#elif defined(ARDUINO_AVR_LILYPAD)
#define BOARD_NAME "Lilypad"
#elif defined(ARDUINO_AVR_LILYPAD_USB)
#define BOARD_NAME "Lilypad Usb"
#elif defined(ARDUINO_AVR_MEGA)       
#define BOARD_NAME "Mega"
#elif defined(ARDUINO_AVR_MEGA2560)       
#define BOARD_NAME "Mega 2560"
#elif defined(ARDUINO_AVR_MICRO)       
#define BOARD_NAME "Micro"
#elif defined(ARDUINO_AVR_MINI)       
#define BOARD_NAME "Mini"
#elif defined(ARDUINO_AVR_NANO)       
#define BOARD_NAME "Nano"
#elif defined(ARDUINO_AVR_NG)       
#define BOARD_NAME "NG"
#elif defined(ARDUINO_AVR_PRO)       
#define BOARD_NAME "Pro"
#elif defined(ARDUINO_AVR_ROBOT_CONTROL)       
#define BOARD_NAME "Robot Ctrl"
#elif defined(ARDUINO_AVR_ROBOT_MOTOR)       
#define BOARD_NAME "Robot Motor"
#elif defined(ARDUINO_AVR_UNO)       
#define BOARD_NAME "Uno"
#elif defined(ARDUINO_AVR_YUN)       
#define BOARD_NAME "Yun"

// These boards must be installed separately:
#elif defined(ARDUINO_SAM_DUE)       
#define BOARD_NAME "Due"
#elif defined(ARDUINO_SAMD_ZERO)       
#define BOARD_NAME "Zero"
#elif defined(ARDUINO_ARC32_TOOLS)       
#define BOARD_NAME "101"
#else
#error "Unknown board"
#endif

#endif