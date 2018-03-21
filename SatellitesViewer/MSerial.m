classdef MSerial < handle
    %MSERIAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        supportedSerialModes = {'Transparent', 'XBeeAPI'};
    end
    
    properties
        serialObj;
        config = struct();
        serialMode = 'Transparent';
        handshakeTx = '';
        handshakeRx = '';
        serialInBuffer = cell(0,2);
        verbose = true;
    end
    
    properties(Dependent)
        currentPort;
        allSerialPorts;
        availableSerialPorts;
    end
    
    methods
        function val = get.currentPort(this)
            if isempty(this.serialObj)
                val = '';
            else
                val = this.serialObj.Port;
            end
        end
        function val = get.allSerialPorts(~)
            serialInfo = instrhwinfo('serial');
            val = serialInfo.SerialPorts;
        end
        function val = get.availableSerialPorts(~)
            serialInfo = instrhwinfo('serial');
            val = serialInfo.AvailableSerialPorts;
        end
    end
    
    methods
        function this = MSerial(isVerbose)
            % Constructor (do nothing)
            
            if nargin < 1
                isVerbose = true;
            end
            
            this.verbose = isVerbose;
            
            this.config.BaudRate = 115200;
            this.config.Terminator = 'LF';
            this.config.InputBufferSize = 115200;
            this.config.BytesAvailableFcnMode = 'Terminator';
            this.config.BytesAvailableFcn = {@MSerial.ReadSerial, this};
        end
        
        function [success, portName] = Connect(this, portName)
            % Find and connect to a serial port
            
            % Connection
            if nargin < 2
                portName = 'AUTO';
            end
            
            if strcmpi(portName, 'AUTO')
                portName = [];
                portList = this.availableSerialPorts;
                for i = 1 : length(portList)
                    if this.SetupSerialPort(portList{i}, this.handshakeTx, this.handshakeRx)
                        portName = portList{i};
                        break;
                    end
                end
            else
                if ~this.SetupSerialPort(portName, this.handshakeTx, this.handshakeRx)
                    portName = [];
                end
            end
            
            success = ~isempty(portName);
            
            if success
                disp([this.serialObj.Name ' connected']);
            end
        end
        
        function success = Disconnect(this)
            % Disconnect the current serial port
            
            try
                % Close serial communication and clear memory
                portName = this.serialObj.Name;
                fclose(this.serialObj);
                delete(this.serialObj);
                this.serialObj = [];
                disp([portName ' disconnected'])
                
                success = true;
            catch
                success = false;
            end
        end
        
        function delete(this)
            this.Disconnect();
        end
        
        
        function SetSerialMode(this, val)
            p = inputParser();
            p.addRequired('val', @(x) any(validatestring(x, MSerial.supportedSerialModes)));
            p.parse(val);
            
            modeIdx = find(strcmpi(val, MSerial.supportedSerialModes));
            this.serialMode = MSerial.supportedSerialModes{modeIdx};
            
            if ~isempty(this.serialObj)
                switch modeIdx
                    case 2
                        this.serialObj.Terminator = '~';
                    otherwise
                        this.serialObj.Terminator = 'LF';
                end
            end
        end
        
        function [val, idx] = GetSerialMode(this)
            val = this.serialMode;
            idx = find(strcmp(val, MSerial.supportedSerialModes));
        end
        
        function [success, errMsg, outStr] = SendSerial(this, outStr)
            % Process and dispatch command string
            
            errMsg = {};
            success = true;
            
            if ~isempty(outStr)
                if strcmp(this.serialMode, 'XBeeAPI')
                    % Pack outStr into a Transmit Request frame (0x10) in XBeeAPI mode
                    outStr = [outStr, sprintf('\r\n')];
                    outStr = this.PackFrameData(outStr);
                elseif strcmp(this.serialMode, 'Transparent')
                    % Append carriage return and newline to outStr for transparent communication
                    outStr = [outStr, sprintf('\r\n')];
                end
                
                % Send command via serial communication
                try
                    fwrite(this.serialObj, outStr);
                catch
                    errMsg = {'ERROR: Serial port is not working'};
                    this.Disconnect();
                    success = false;
                end
            end
            
        end
        
        function AddToSerialInBuffer(this, inStr, t)
            % Add string and time stamp into serial input buffer of the class
            
            if nargin < 3
                t = datevec(now());
            end
            
            if ~isempty(inStr)
                % Remove return characters
                charMask = inStr == sprintf('\n') | inStr == sprintf('\r');
                inStr(charMask) = [];
                
                % Add into buffer cell array
                this.serialInBuffer{end+1,1} = inStr;
                this.serialInBuffer{end,2} = t;
                
                if this.verbose
                    disp(inStr);
                end
            end
        end
        
        function [s, t] = ReadSerialInBuffer(this)
            % 
            
            if isempty(this.serialInBuffer)
                s = '';
                t = NaN;
            else
                s = this.serialInBuffer{1};
                t = this.serialInBuffer{2};
                this.serialInBuffer(1,:) = [];
            end
        end
        
    end
    
    methods(Static, Access = private)
        function ReadSerial(sObj, event, mSerialObj)
            % Callback function of BytesAvailable event
            
            tic;
            
            persistent bufferBytes maxTime;
            persistent isEscaping bytePos frameLength;
            
            if isempty(isEscaping)
                bufferBytes = [];
                isEscaping = false;
                bytePos = 0;
                frameLength = 0;
                maxTime = 0;
            end
            
            try
                numBytesAvailable = sObj.BytesAvailable;
                while numBytesAvailable > 0
                    
                    % Read all available bytes
                    bb = fread(sObj, numBytesAvailable);
                    
                    for i = 1 : numBytesAvailable
                        % Process one byte at a time
                        b = bb(i);
                        
                        if strcmp(mSerialObj.serialMode, MSerial.supportedSerialModes{1})
                            % Read all available bytes in chars before the terminator
                            switch b
                                case {double(sprintf('\n')), double(sprintf('\r'))}
                                    mSerialObj.AddToSerialInBuffer(char(bufferBytes), event.Data.AbsTime);
                                    bufferBytes = [];
                                otherwise
                                    bufferBytes(end+1) = b;
                            end
                            
                        else
                            % Read and parse XBee API frame
                            
                            if b == 126 % i.e. 0x7E, the frame start byte
                                % This is the start of a frame
                                bufferBytes = [];
                                bytePos = 1; % one-based indexing; zero means not in a frame
                                
                            elseif b == 125 % i.e. 0x7D, the escaping flag
                                % Register an escaping for the next byte (does not affect byte position)
                                isEscaping = true;
                                
                            elseif bytePos > 0
                                % Parsing the frame
                                
                                % Update current byte position
                                bytePos = bytePos + 1;
                                
                                % Perform escaping if the preceeding byte was '7D'
                                if isEscaping
                                    b = xor(b, hex2dec('7D'));
                                    isEscaping = false;
                                end
                                
                                % Get frame info depending on byte position
                                if bytePos == 2
                                    frameLength = b * 256; % add MSB into frame length
                                    
                                elseif bytePos == 3
                                    frameLength = frameLength + b; % add LSB into frame length
                                    
                                elseif bytePos >= 4
                                    bufferBytes(end+1) = b;
                                    %                                 fprintf('%d/%d(%d)\n', bytePos, frameLength, b);
                                    
                                    % Parse frame data when its complete
                                    if length(bufferBytes) == frameLength+1 % i.e. plus checksum
                                        bufferBytes(end) = []; % drop checksum
                                        fr = MSerial.ExtractFrameData(bufferBytes');
                                        if ~isempty(fr)
                                            mSerialObj.AddToSerialInBuffer(fr.data, event.Data.AbsTime);
                                        end
                                        bytePos = 0; % reset byte position
                                    end
                                end
                                
                            else
                                % Discard irrelevent bytes
                                % fprintf(char(b));
                            end
                        end
                    end
                    
                    % Update available byte number
                    numBytesAvailable = sObj.BytesAvailable;
                end
                
            catch e
                disp(e);
                mSerialObj.Disconnect();
            end
            
            % Check for the time used
            thisTime = toc;
            if thisTime > maxTime
                maxTime = thisTime;
                fprintf('MSerial: max time in callback: %f\n', maxTime);
            end
        end
        
        function output = ExtractFrameData(frameData)
            % EXTRACTFRAMEDATA Extract the data from the frame.
            
            output = [];
            
            % Extract the frame type
            frameType = frameData(1);
            
            % Based on the frame type, process the frame differently.
            switch (frameType)
                case hex2dec('97')
%                     disp('This is is a frame type of [AT Remote Command Response]');
                case hex2dec('88')
%                     disp('This is an AT Command Response');
                case hex2dec('8A')
%                     disp('This is a Modem Status');
                case hex2dec('8B')
%                     disp('This is a ZigBee Transmit Status');
                case hex2dec('90')
%                     disp('This is a ZigBee Receive Packet (AO=0)');
                    % Extract 64-bit source address of the packet
                    temp = dec2hex(frameData(2:9), 2);
                    output.srcAddress64 = reshape(temp', 1, numel(temp));
                    
                    % Extract 16-bit source address of the packet
                    temp = dec2hex(frameData(10:11), 2);
                    output.srcAddress16 = reshape(temp', 1, numel(temp));
                    
                    % Extract Remote AT Command
                    output.data = char(frameData(13:end))';
                    
                case hex2dec('91')
%                     disp('This is a ZigBee Explicit Rx Indicator (AO=1)');
                case hex2dec('92')
%                     disp('This is a ZigBee IO Data Sample Rx Indicator');
                case hex2dec('94')
%                     disp('This is an XBee Sensor Read Indicator (AO=0)');
                case hex2dec('95')
%                     disp('This is a Node Identification Indicator (AO=0)');
                otherwise
%                     disp('This is an unidentifiable framedata');
                    return;
            end            
        end
        
        function frame = PackFrameData(data)
            
            % Change 16 hexadecimal numbers to 8 decimal numbers.
            decDestAdd = MSerial.Hex16ToDec8('000000000000FFFF');
            
            % Structure Remote AT Command frame (Frame type - 0x17)
            frame = [ ...
                hex2dec('7E'), ... % Start byte
                hex2dec('00'), hex2dec('00'), ... % Length: fill in later
                hex2dec('10'), ... % Frame type 0x10 is Transmit Request
                hex2dec('01'), ... % Frame ID % This can be an identifier.
                decDestAdd,    ... % 64bit Destination Address
                hex2dec('FF'), hex2dec('FE'), ... % Destination Network Address
                hex2dec('00'), ... % Broadcast Radius
                hex2dec('00'), ... % Options
                uint8(data), ... % RF data
                ];
            
            % Include frame length in the frame. Frame structure specs needs it to be
            % broken into two parts LH and LL
            frameLength = length(frame(4:end));
            LH = floor(frameLength/ 256);
            LL = mod(frameLength, 256);
            frame(2) = LH;
            frame(3) = LL;
            
            % Include checksum in the frame
            checksum = hex2dec('FF') - mod(sum(frame(4:end)), 256);
            frame = [frame checksum];
        end
        
        function output = Hex16ToDec8(hex16Value)
            % HEX16TODEC8 Convert 16 char hexadecimal numbers to 8 digit decimal numbers.
            %
            %   xbee.hex16ToDec8('0013A200409BAE30') returns [ 0 19 162 0 64 155 174 48].
            
            str = upper(hex16Value);
            temp = zeros(1,8);
            if (length(str) ~= 16)
                error('hex16ToDec8:LengthMmatch', 'Check the size of string format. destination address should be 64bit HW address (e.g., ''0013A200408BAE30'')');
            else
                for i = 1:length(str)/2
                    x = [str( (i-1)*2 + 1) str( (i-1)*2 + 2)];
                    temp(i) = hex2dec(x);
                end
            end
            output = temp;
        end
        
    end
    
    methods(Access = private)
        function success = SetupSerialPort(this, portName, hsTx, hsRx)
            % Connect to a serial port
            
            % Disconnect currently connected port (if applicable)
            this.Disconnect();
            
            try
                % Initialize serial object
                this.serialObj = serial(portName, this.config);
                
                if strcmp(this.serialMode, 'XBeeAPI')
                    this.serialObj.Terminator = '~';
                end
                
                disp(['querying ' this.serialObj.Name]);
                
                % Open serial communication
                fopen(this.serialObj);
                
                % Handshaking
                if isempty(hsRx)
                    success = true;
                else
                    % Give some time for the communication to be functional
                    pause(2);
                    
                    % Clear bytes in the buffer, if any
                    flushinput(this.serialObj);
                    this.serialInBuffer = cell(0,2);
                    
                    % Transmit code
                    this.SendSerial(hsTx);
                    
                    % Receive code
                    pause(.3);
                    reply = this.ReadSerialInBuffer();
                    
                    % Compare code
                    success = ~isempty(regexp(reply, hsRx, 'once'));
                    
                    % Notification
                    if success
                        disp(['handshaked: ' hsTx ' => ' reply]);
                    else
                        disp(['non-match: ' hsTx ' => ' reply]);
                    end
                end
                
                if ~success
                    this.Disconnect();
                end
                
            catch e
                disp(e);
                if isa(this.serialObj, 'serial')
                    delete(this.serialObj);
                    this.serialObj = [];
                end
                success = false;
            end
        end
    end
    
    
    
    methods(Hidden = true)
        % Hide functions inherited from the handle class
        function addlistener(obj, property, eventname, callback)
            addlistener@addlistener(obj, property, eventname, callback)
        end
        
        function findobj(obj, property, eventname, callback)
            findobj@findobj(obj, property, eventname, callback)
        end
        
        function findprop(obj, property, eventname, callback)
            findprop@findprop(obj, property, eventname, callback)
        end
        
        function notify(obj, property, eventname, callback)
            notify@notify(obj, property, eventname, callback)
        end
    end
end

