classdef SatellitesViewerChannel < handle
    %SERIALVIEWERCHANNEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % General
        config = struct();
        isSaved = false;
        dispatcherTimer;
        isVerbose = true;
        
        % Communication
        mserial;
        mudp;
        
        % Logging
        logMetadata;
        logArray = cell(0,3);
        logArrayForDisplay = cell(0,1);
        logWin;
        
        % User data
        userFuncObj;
    end
    
    properties(Dependent)
        chanName;
        mainPort;
    end
    
    methods
        function val = get.mainPort(this)
            % Return a single port name that is representative to this channel
            switch lower(this.config.chanMode)
                case {'standalone', 'server'}
                    val = this.config.serialPort;
                case 'client'
                    val = this.config.udpServerIP;
                otherwise
                    val = 'NA';
            end
        end
        function val = get.chanName(this)
            % Return the channel name
            val = this.config.chanName;
        end
    end
    
    methods
        function this = SatellitesViewerChannel()
            % Constructor of the SatellitesViewerChannel class
            % 
            %   SatellitesViewerChannel()
            %
            
            % Set default values to configuration
            this.config.isChanEnabled = false;
            
            this.config.chanMode = 'Standalone';
            this.config.chanName = '';
            this.config.refreshRate = 10;               % Hz
            this.config.msgPrefix = '';
            this.config.userFuncName = 'none';
            
            this.config.serialPort = '';
            this.config.serialBaudRate = 115200;
            this.config.serialMode = 'Transparent';
            
            this.config.udpLocalPort = 8009;
            this.config.udpServerIP = '';
            this.config.udpServerPort = 8009;
            this.config.udpClientTable = cell(1,3);
            
            this.config.isLogOutputs = true;
            this.config.isTagIO = true;
            this.config.isTagTime = true;
            this.config.tagDelimiter = ',';
            
            
            % Create communication objects
            this.mserial = MSerial(false);      % set 'verbose' mode to false
            this.mudp = MUdp(false);            % set 'verbose' mode to false
            
            
            % Initialize user function data object
            this.userFuncObj = UserFuncModel();
            
            
            % Setup communication processing routine
            this.dispatcherTimer = timer;
            this.dispatcherTimer.ExecutionMode = 'fixedSpacing';
            this.dispatcherTimer.TasksToExecute = inf;
            this.dispatcherTimer.Period = 1 / this.config.refreshRate;
            this.dispatcherTimer.BusyMode = 'drop';
            this.dispatcherTimer.TimerFcn = @(~,~)DispatcherRoutine(this);
        end
        
        function DeleteChannel(this)
            % Delete this object
            
            this.DisableChannel();
            
            try
                delete(this.logWin.fig);
            catch
                % do nothing
            end
            
            delete(this);
        end
        
        function [success, errMsg] = ConfigureChannel(this, newCfg)
            % Configure channel by configuration structure
            
            % Validating inputs
            errMsg = '';
            
            % Channel name
            if isempty(newCfg.chanName)
                errMsg = [errMsg, 'Channel name cannot be empty.\n'];
            end
            
            % Serial port
            if isempty(newCfg.serialPort) && any(strcmpi(newCfg.chanMode, {'server', 'standalone'}))
                errMsg = [errMsg, 'Plase make sure you have available serial port.\n'];
            end
            
            % Server IP (local and server port is validated by GUI control built-in validation)
            if isempty(newCfg.udpServerIP) && strcmpi(newCfg.chanMode, 'client')
                errMsg = [errMsg, 'Server IP cannot be empty in Client mode.\n'];
            end
            
            % Client IPs and ports
            if strcmpi(newCfg.chanMode, 'server')
                
                t = newCfg.udpClientTable;
                
                if isempty(t)
                    errMsg = [errMsg, 'Client UDP/IP table cannot be empty in Server mode. ', ...
                        'Please use Standalone mode if you do not need to relay messages to other computers.\n'];
                end
                
                % Go through each row
                for i = 1 : size(t,1)
                    % IP (better to use regular expression)
                    if isempty(t{i,2})
                        errMsg = [errMsg, 'Client IP in row ', num2str(i) ,' is empty.\n'];
                    end
                    
                    % Port (better to use regular expression)
                    if isempty(t{i,3})
                        errMsg = [errMsg, 'Client port in row ', num2str(i) ,' is empty.\n'];
                    elseif isnan(str2double(t{i,3}))
                        errMsg = [errMsg, 'Client port in row ', num2str(i) ,' must be a number.\n'];
                    end
                end
            end
            
            success = isempty(errMsg);
            
            
            % Configuration
            if success
                % Find available fields
                fieldNames = intersect(fieldnames(newCfg), fieldnames(this.config));
                
                % Clear user data if the user function is changed
                if any(strcmp('userFuncName', fieldNames)) && ~strcmp(this.config.userFuncName, newCfg.userFuncName)
                    this.userFuncObj.ClearUserData();
                end
                
                % Update old configuration
                for i = 1 : length(fieldNames)
                    this.config.(fieldNames{i}) = newCfg.(fieldNames{i});
                end
                
                % Update serial communication settings
                this.mserial.config.BaudRate = this.config.serialBaudRate;
                
                this.DispIfVerbose('this.config');
                this.DispIfVerbose(this.config);
                
                this.isSaved = true;
                
                % Apply changes to enabled channel
                if this.config.isChanEnabled
                    [~, errMsg] = this.EnableChannel();
                end
            end
        end
        
        function [success, errMsg] = EnableChannel(this)
            % Enable this channel based on parameters in channel configuration
            
            % Prepare variables for later use
            success = true;
            errMsg = '';
            cfg = this.config;       % shorthand variable name
            
            
            % Stop timer to prevent unexpected error
            stop(this.dispatcherTimer);
            this.dispatcherTimer.Period = 1 / cfg.refreshRate;
            
            
            % Connect to a new or different serial port
            if any(strcmpi(cfg.chanMode, {'standalone', 'server'}))
                if ~strcmp(this.mserial.currentPort, cfg.serialPort) || this.mserial.serialObj.BaudRate ~= cfg.serialBaudRate
                    if ~this.mserial.Connect(cfg.serialPort)
                        success = false;
                        errMsg = sprintf('%sFailed to connect to serial %s.\n', errMsg, cfg.serialPort);
                    end
                end
            end
            
            
            % Connect UDP as client
            if strcmpi(cfg.chanMode, 'client')
                this.mudp.Disconnect();
                
                if ~this.mudp.Connect(cfg.udpServerIP, cfg.udpServerPort, cfg.udpLocalPort)
                    success = false;
                    errMsg = sprintf('%sFailed to apply UDP settings.\n', errMsg);
                end
            end
            
            
            % Connect to receiver UDP port
            if strcmpi(cfg.chanMode, 'server')
                this.mudp.Disconnect();
                
                udpIPs = cfg.udpClientTable(:,2);
                udpRemotePorts = cellfun(@str2double, cfg.udpClientTable(:,3), 'Uni', false);
                
                udpLocalPorts = cell(size(cfg.udpClientTable,1), 1);
                udpLocalPorts{1} = cfg.udpLocalPort;
                
                if ~this.mudp.Connect(udpIPs, udpRemotePorts, udpLocalPorts)
                    success = false;
                    errMsg = sprintf('%sFailed to apply UDP settings.\n', errMsg);
                end
            end
            
            
            % Disconnect unrelated connections
            switch lower(cfg.chanMode)
                case 'standalone'
                    this.mudp.Disconnect();
                    
                case 'client'
                    this.mserial.Disconnect();
            end
            
            
            % Finalize
            if success
                % Start timer
                start(this.dispatcherTimer);
                
                % Apply enable state
                this.config.isChanEnabled = true;
                
            else
                % Disable channel
                this.DisableChannel();
            end
            
        end
        
        function DisableChannel(this)
            % Disable this channel
            
            stop(this.dispatcherTimer);
            
            this.mserial.Disconnect();
            this.mudp.Disconnect();
            
            this.config.isChanEnabled = false;
        end
        
        function [success, errMsg] = SendMessage(this, outStr)
            % Process and dispatch command string
            
            success = true;
            errMsg = '';
            
            if ~isempty(outStr)
                % Attach prefix to the string
                outStr = [this.config.msgPrefix, outStr];
                
                if any(strcmpi(this.config.chanMode, {'server', 'standalone'}))
                    % Send through serial communication if channel mode is server or standlone
                    [success, errMsgCell] = this.mserial.SendSerial(outStr);
                    
                    if ~isempty(errMsgCell)
                        errMsg = errMsgCell{1};
                    end
                else
                    % Send through UDP communication if channel mode is client
                    [success, errMsgCell] = this.mudp.SendUdp(outStr);
                    
                    if ~isempty(errMsgCell)
                        errMsg = errMsgCell{1};
                    end
                end
                
                if success
                    % Print command
                    this.LogMessageOut(outStr);
                else
                    % Disable channel
                    this.DisableChannel();
                end
            end
        end
        
        function LogMessageIn(this, inStr, isDisplay)
            % Add an incoming message to log
            %
            %   LogMessageIn(cmdStr)
            %
            % Inputs:
            %   cmdStr          a string to log
            
            if nargin < 2
                isDisplay = true;
            end
            
            this.logArray(end+1,:) = {'I', datestr(now, 'yyyymmddHHMMSSFFF'), inStr};
            
            if isDisplay
                this.logArrayForDisplay{end+1,1} = ['<- ' inStr];
                this.DisplayLog();
            end
        end
        
        function LogMessageOut(this, outStr)
            % Add an outgoing message to log
            %
            %   LogMessageOut(cmdStr)
            %
            % Inputs:
            %   cmdStr          a string to log
            
            if this.config.isLogOutputs
                this.logArray(end+1,:) = {'O', datestr(now, 'yyyymmddHHMMSSFFF'), outStr};
                this.logArrayForDisplay{end+1,1} = ['-> ' outStr];
                this.DisplayLog();
            end
        end
        
        function ShowLogWindow(this)
            % Show the log window of this channel
            
            try
                % Bring window to focus
                figure(this.logWin.fig);
            catch
                % Create window
                this.logWin.fig = figure(...
                    'Name', this.config.chanName, ...
                    'NumberTitle', 'off', ...
                    'MenuBar', 'none');
                
                figPos = get(this.logWin.fig, 'Position');
                set(this.logWin.fig, 'Position', [figPos(1:2)-100 400 500]);
                
                this.logWin.logBox = uicontrol(this.logWin.fig, ...
                    'Style', 'listbox', ...
                    'FontSize', 9, ...
                    'Units', 'normalized', ...
                    'Position',[0 0 1 .95]);
                
                this.logWin.cmdEdit = uicontrol(this.logWin.fig, ...
                    'Style', 'edit', ...
                    'FontSize', 9, ...
                    'HorizontalAlignment', 'left', ...
                    'Units', 'normalized', ...
                    'Position',[0 .95 1 .05], ...
                    'KeyPressFcn', {@CmdKeyPressCallback, this});
                
                this.DisplayLog();
            end
            
            function CmdKeyPressCallback(src, event, chan)
                if strcmp(event.Key, 'return')
                    pause(0.01);
                    strOut = get(src, 'String');
                    chan.SendMessage(strOut);
                    set(src, 'String', '');
                end
            end
        end
        
        function DisplayLog(this)
            % Dispaly communication log stored in logArrayForDisplay to the channel's log window. 
            % (The number of entries is limitted to ensure performance.)
            %
            %   DisplayLog()
            %
            
            % Keep the number of items low to ensure performance
            if length(this.logArrayForDisplay) > 1100
                this.logArrayForDisplay(1:end-1000) = [];
            end
            
            try
                if isfield(this.logWin, 'fig') && ishandle(this.logWin.fig)
                    % Update ListBox
                    set(this.logWin.logBox, 'String', this.logArrayForDisplay);
                    
                    % Scroll ListBox to the bottom (latest item)
                    if ~isempty(this.logArrayForDisplay)
                        set(this.logWin.logBox, 'Value', length(this.logArrayForDisplay));
                    end
                end
            catch e
                this.DispIfVerbose(e);
                save('svException.mat', 'e');
            end
        end
        
        function [success, errMsg] = SaveLog(this, filePath)
            % Save log in the current channel
            
            success = true;
            errMsg = '';
            
            try
                fileID = fopen(filePath, 'wt');
                
                tagMask = [this.config.isTagIO, this.config.isTagTime];
                tagArray = cellfun(@(x) [x, this.config.tagDelimiter], this.logArray(:,1:length(tagMask)), 'Uni', false);
                
                for i = 1 : size(this.logArray,1)
                    fprintf(fileID, [tagArray{i,tagMask}, this.logArray{i,3}, '\n']);
                end
            catch e
                success = false;
                errMsg = 'Error when saving log';
                
                this.DispIfVerbose(e);
                save('svException.mat', 'e');
            end
            
            try
                fclose(fileID);
            catch
            end
        end
        
        function DeleteLog(this)
            % Delete log in the current channel
            
            this.logArrayForDisplay = cell(0,1);
            this.logArray = cell(0,3);
            this.DisplayLog();
        end
        
    end
    
    methods(Access = private)
        function DispatcherRoutine(this)
            %DispatcherRoutine
            
            tic
            
            persistent maxTime;
            if isempty(maxTime)
                maxTime = 0;
            end
            
            chanMode = this.config.chanMode;
            
            % Process serial inputs
            if any(strcmpi(chanMode, {'Server', 'Standalone'}))
                
                [inStr, ~] = this.mserial.ReadSerialInBuffer();
                
                while ~isempty(inStr)
                    if strcmpi(chanMode, 'Server')
                        % Broadcast message to subscribers
                        this.mudp.SendUdp(inStr);
                    end
                    
                    % Execute local user function
                    isDisplay = this.UserFunc(inStr);
                    
                    % Log serial input
                    this.LogMessageIn(inStr, isDisplay);
                    
                    % Keep reading for more input
                    [inStr, ~] = this.mserial.ReadSerialInBuffer();
                end
            end
            
            
            % Process UDP/IP inputs
            if any(strcmpi(chanMode, {'Server', 'Client'}))
                [inStr, ~] = this.mudp.ReadUdpInBuffer();
                
                while ~isempty(inStr)
                    if strcmpi(chanMode, 'Server')
                        % Forward message from users to rigs (no modification needed)
                        this.SendMessage(inStr);
                    else
                        % Process input form rig
                        isDisplay = this.UserFunc(inStr);
                        this.LogMessageIn(inStr, isDisplay);
                    end
                    
                    % Keep reading for more input
                    [inStr, ~] = this.mudp.ReadUdpInBuffer();
                end
            end
            
            
            % Check for the time used
            thisTime = toc;
            if thisTime > maxTime
                maxTime = thisTime;
                fprintf('Channel %s: max time in callback %f seconds\n', this.config.chanName, maxTime);
            end
        end
        
        function isDisplay = UserFunc(this, inStr)
            % Execute user function
            
            isDisplay = true;
            
            if ~strcmp(this.config.userFuncName, 'none')
                % Prepare user function object
                this.userFuncObj.channelName = this.config.chanName;
                this.userFuncObj.msgIn = inStr;
                this.userFuncObj.isDisplay = true;
                
                % Try to execute user function
                try
                    % Execute user function
                    feval(this.config.userFuncName, this.userFuncObj);
                    
                    % Read output
                    isDisplay = this.userFuncObj.isDisplay;
                    
                    % Send messages
                    msgOut = cellstr(this.userFuncObj.msgOut);
                    for i = 1 : length(msgOut)
                        this.SendMessage(msgOut{i});
                    end
                    
                catch e
                    % Reset user function to default
                    this.config.userFuncName = 'none';
                    this.userFuncObj.ClearUserData();
                    
                    % Report and save error
                    this.DispIfVerbose(e);
                    save('svException.mat', 'e');
                end
            end
            
            if ~islogical(isDisplay)
                isDisplay = true;
            end
        end
        
        function DispIfVerbose(this, c)
            % Display for debugging
            if this.isVerbose
                try
                    disp(c);
                catch
                    fprintf('%s is not applicable for disp().\n', class(c));
                end
            end
        end
        
    end
    
end

