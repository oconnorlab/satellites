classdef MUdp < handle
    %MSERIAL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        udpObjs = cell(0,1);
        config = struct();
        defaultRemotePort = 8009;
        udpInBuffer = cell(0,2);
        udpInBufferSize = 1000;
        verbose = true;
    end
    
    properties(Dependent)
        localIP;
    end
    
    methods
        function val = get.localIP(~)
            address = java.net.InetAddress.getLocalHost;
            val = char(address.getHostAddress);
        end
    end
    
    methods
        function this = MUdp(isVerbose)
            % Constructor
            
            if nargin < 1
                isVerbose = true;
            end
            
            this.verbose = isVerbose;
        end
        
        function success = Connect(this, remoteHost, remotePort, localPort)
            % Setup UDP connection(s)
            % 
            
            % Check inputs
            remoteHost = cellstr(remoteHost);
            
            if nargin < 4
                localPort = cell(size(remoteHost));
            elseif isnumeric(localPort)
                localPort = num2cell(localPort);
            end
            
            if nargin < 3
                remotePort = repmat({this.defaultRemotePort}, size(remoteHost));
            elseif isnumeric(remotePort)
                remotePort = num2cell(remotePort);
            end
            
            % Try setting up each connection
            for i = 1 : length(remoteHost)
                
                success(i) = this.SetupUdp(remoteHost{i}, remotePort{i}, localPort{i});
                
                if success(i)
                    disp([remoteHost{i} ' (port: ' num2str(remotePort{i}) ') connected']);
                else
                    disp([remoteHost{i} ' (port: ' num2str(remotePort{i}) ') failed to connect']);
                end
            end
        end
        
        function maskDiscon = Disconnect(this, ind)
            % Disconnect the current serial port
            
            if nargin < 2
                ind = 1 : length(this.udpObjs);
            end
            
            maskDiscon = false(size(this.udpObjs));
            
            for k = 1 : length(ind)
                try
                    % Close UDP communication
                    portName = this.udpObjs{ind(k)}.Name;
                    fclose(this.udpObjs{ind(k)});
                    delete(this.udpObjs{ind(k)});
                    disp([portName ' disconnected'])
                    
                    maskDiscon(ind(k)) = 1;
                catch
                    % do nothing
                end
            end
            
            % Remove disconnected UDP objets
            this.udpObjs(maskDiscon) = [];
        end
        
        function delete(this)
            this.Disconnect();
        end
        
        function ShowUdpInfo(this, ind)
            % Disconnect the current serial port
            
            if nargin < 2
                ind = 1 : length(this.udpObjs);
            end
            
            for k = 1 : length(ind)
                get(this.udpObjs{ind(k)});
            end
        end
        
        function [successMask, errMsg] = SendUdp(this, outStr, ind)
            % Process and dispatch command string
            
            % Broadcast by default
            if nargin < 3
                ind = 1 : length(this.udpObjs);
            end
            
            if ~isempty(outStr)
                % Send via each UDP connection
                
                successMask = false(size(ind));
                errMsg = {};
                
                for k = 1 : length(ind)
                    try
                        fprintf(this.udpObjs{ind(k)}, outStr);
                        successMask(k) = true;
                    catch
                        errMsg{end+1,1} = {'ERROR: ' this.udpObjs{ind(k)}.Name ' is not working'};
                        this.Disconnect(ind(k));
                    end
                end
            end
        end
        
        function AddToUdpInBuffer(this, inStr, t)
            % Add string and time stamp into serial input buffer of the class
            
            if nargin < 3
                t = datevec(now());
            end
            
            % Check for the fullness of the buffer
            if size(this.udpInBuffer,1) >= this.udpInBufferSize
                if this.verbose
                    warning('UDP input buffer is full, no more message taken');
                end
                return;
            end
            
            if ~isempty(inStr)
                % Remove return characters
                charMask = inStr == sprintf('\n') | inStr == sprintf('\r');
                inStr(charMask) = [];
                
                % Add into buffer cell array
                this.udpInBuffer{end+1,1} = inStr;
                this.udpInBuffer{end,2} = t;
                
                if this.verbose
                    disp(inStr);
                end
            end
        end
        
        function [s, t] = ReadUdpInBuffer(this)
            % Read string and time stamp from the input buffer of the class
            
            if isempty(this.udpInBuffer)
                s = '';
                t = NaN;
            else
                s = this.udpInBuffer{1};
                t = this.udpInBuffer{2};
                this.udpInBuffer(1,:) = [];
            end
        end
        
    end
    
    methods(Access = private)
        function success = SetupUdp(this, remoteIP, remotePort, localPort)
            % Setup a UDP connection
            
            try
                % Initialize UDP object
                u = udp(remoteIP, remotePort);
                u.InputBufferSize = 30000;
                if ~isempty(localPort)
                    u.LocalPort = localPort;
                end
                
                % Setup read callback when the receiving port is explicitly specified
                % otherwise the connection is only used for sending unless user goes under the hood
                % and set things up
                if ~isempty(localPort)
                    u.BytesAvailableFcnMode = 'Terminator';
                    u.BytesAvailableFcn = {@MUdp.ReadUdp, this};
                end
                
                % Open port
                fopen(u);
                
                % Add connection to UDP object list
                this.udpObjs = this.udpObjs(:);
                this.udpObjs{end+1,1} = u;
                
                success = true;
                
            catch e
                if this.verbose
                    disp(e);
                end
                
                fclose(u);
                delete(u);
                
                success = false;
            end
            
        end
    end
    
    methods(Static, Access = private)
        function ReadUdp(uObj, event, mUdpObj)
            % Callback function of BytesAvailable event
            
            tic;
            
            persistent maxTime;
            
            if isempty(maxTime)
                maxTime = 0;
            end
            
            try
                inStr = fscanf(uObj);
                mUdpObj.AddToUdpInBuffer(inStr, event.Data.AbsTime);
            catch e
                disp(e);
            end
            
            % Check for the time used
            thisTime = toc;
            if mUdpObj.verbose && thisTime > maxTime
                maxTime = thisTime;
                fprintf('MUdp: max time in callback: %f\n', maxTime);
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

