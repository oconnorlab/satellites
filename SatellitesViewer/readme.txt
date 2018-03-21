Overview

SatellitesViewer is a general-purposed app for serial and UDP/IP communication. One can use it to simply communicate with a serial device (e.g. Arduino), or to talk with another computer over a local network, or to deploy multiple messaging topologies involving serial/Wifi/LAN interfaces. This app streamlines your communications with easily customizable GUI (e.g. by editing an Excel spreadsheet). Its support of user functions makes online visualization and feedback control possible by basic MATLAB programming.



Channel

SatellitesViewer uses the idea of a Channel to manage a complete message flow based on a set of realted connections. You can create an arbitrary number of Channels. Each Channel has its independent configuration, input/output control, logging, and etc, which can be accessed in the "Current Channel" panel. A Channel can be configured to one of three modes below. 

Standalone mode
It is the simplest mode in which the computer connects to a device via a serial port (just like the Serial Monitor in Arduino IDE). However, you can, for example, create multiple Channels in this mode to control separate serial devices simultaneously. See "XBee API" section for advanced use of serial communication. 

Server mode
This mode sets up a serial connection as in Standalone mode but also broadcasts messages received from this serial connection to one or more client computers in the local network (via UDP/IP). In the opposite direction, messages received from client computers will be relayed back to the serial device. One needs to provide the IP addresses and ports of client computers to send messages out and the port of the local computer to receive messages. 

Client mode
No serial connection is involved in this mode. Instead, the Channel sends and receives messages with a server computer on the network, thus can remotely control a serial device connected to the server. One needs to specify the IP address and port of the server computer to send messages out and the port of local computer to receive messages. See "Client-Client communication" section for an alternative use. 

Turn Channel on/off
In the "Current Channel" panel, checking the Enable checkbox turns the current Channel on; unchecking turns it off. When turned off, a Channel has no actual connection and no computing resource is taken. See "Performance note" for more details on app performance in different conditions. 



Receiving Messages

Logging
Each Channel has its own communication log and a dedicated window for display. Operations such as saving and emtying log can be accessed in "Current Channel" panel. The saved log is a text file where each line is a message. More options about logging can be found in a Channel's configuration window. A simulator allows you to see how different options preprocess a message string. 

User function
You can write custom MATLAB functions to process incoming messages and acheive capabilities such as online visualization, close-loop control, or even email notification. A user function takes one input argument and is called every time the Channel receives a message. This input argument is an object of type UserFuncModel which contains all available information and functionalities at your disposal. Please see example user functions in "private" folder and documentation of UserFuncModel class for more details. 



Sending Messages

Dialog
Messages can be sent in a Channel's log window just like that in Serial Monitor and most messaging apps. 

Quick commands
You may have some frequently used commands to control a device and do not want to type them again and again. In the Quick Commands tab, you can type commonly used commands in individual boxes and send any of them by a click. Note that quick commands only send messages to the currently selected Channel. 

Command groups
Quick commands are limited by the number of boxes, uniform layout, and lack of explanation. Command groups allows you to generate GUI with a large number of organized and well labeled custom commands. It converts content in Excel spreadsheets to buttons, textboxes and descriptive labels. Clicking a button sends a command and its values out using a format specified by Satellites communication protocol. Playing with the example Excel file will help you to understand the conventions. Like quick commands, command groups only send messages to the currently selected Channel. Also see "Satellites communication protocol" section. 



Save and Load Settings

You can save all app settings to a MAT file using "Save settings" button. This file can be loaded later to restore the state of the app. Please note that the following information are not considered as parts of app settings: 1) messages in log, 2) log file name textbox and append time checkbox, 3) command groups, and 4) data in user functions. 



Advanced Topics

Satellites communication protocol
Satellites library for Arduino (and compatible devices) provides an array of simple-to-use functionalities that can streamline flow control, communication, concurency, etc. Please check out the documentation for Satellites library for complete information. 
The communication part of Satellites library implements a specific, yet common, messaging convention for sending and receiving interpretable string. Each message received by a device needs to have the following format:
    cmdString,number1,number2,number3
"cmdString" is a string of letters which indicates what command this is. "number1/2/3..." are numbers associated with this command. There can be as many numbers as you need or none at all. Components of this message are seperated by delimiters (comma "," in this example). 

XBee API mode
In addition to commonly used transparent serial communication, SatellitesViewer also supports a simplified version of XBee API mode allowing user to wirelessly communicate with one or more serial devices. 

Client-Client communication


Performance note



