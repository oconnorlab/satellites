classdef ChannelConfigVM < handle
    %CHANNELCONFIGVM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cfgWin;                 % handle of the configuration window
        svVm;                   % handle of SatellitesViewer's viewmodel
        chan;                   % handle of a channel
        isVerbose = true;       % whether display debugging info
    end
    
    methods
        function this = ChannelConfigVM(app)
            % Constructor of ChannelConfigVM class
            
            this.cfgWin = app;
        end
        
        function Initialize(this, svVmObj, chanObj)
            % Display channel settings in UI
            
            % Save object handles
            this.svVm = svVmObj;
            this.chan = chanObj;
            
            % Reset saving state
            this.chan.isSaved = false;
            
            % Update GUI
            cfg = this.chan.config;
            
            % General
            this.cfgWin.ChannelModeButtonGroup.SelectedObject = eval(['this.cfgWin.' cfg.chanMode 'Button']);
            this.ChangeChannelModeUI();
            this.cfgWin.ChannelNameEditField.Value = cfg.chanName;
            this.cfgWin.RefreshRateEditField.Value = cfg.refreshRate;
            this.cfgWin.MessagePrefixEditField.Value = cfg.msgPrefix;
            
            % Logging
            this.cfgWin.LogOutMsgCheckBox.Value = cfg.isLogOutputs;
            this.cfgWin.AddIOTagCheckBox.Value = cfg.isTagIO;
            this.cfgWin.AddTimeTagCheckBox.Value = cfg.isTagTime;
            this.cfgWin.TagDelimiterEditField.Value = cfg.tagDelimiter;
            this.SimulateLogging();
            
            % Find available user functions
            classPath = mfilename('fullpath');
            classDir = fileparts(classPath);
            userFuncFolderStruct = what(fullfile(classDir, 'private'));
            userFuncNames = cellfun(@(x) x(1:end-2), userFuncFolderStruct.m, 'Uni', false);
            this.cfgWin.UserFunctionDropDown.Items = [{'none'}; userFuncNames];
            
            % Select user function
            try
                this.cfgWin.UserFunctionDropDown.Value = cfg.userFuncName;
            catch
                this.cfgWin.UserFunctionDropDown.Value = 'none';
                uialart(this.cfgWin.UIFigure, ...
                    sprintf('''%s'' is no longer an available user function. No user function is used.', userFuncName), ...
                    'Connection Error', ...
                    'Icon', 'error', ...
                    'Modal', true);
            end
            
            % Serial communication
            this.RefreshSerialPorts(cfg.serialPort);
            this.cfgWin.SerialProtocolButtonGroup.SelectedObject = eval(['this.cfgWin.' cfg.serialMode 'Button']);
            this.cfgWin.BaudRateEditField.Value = cfg.serialBaudRate;
            
            % UDP/IP communication
            this.cfgWin.LocalIPEditField.Value = this.chan.mudp.localIP;
            this.cfgWin.LocalPortEditField.Value = cfg.udpLocalPort;
            this.cfgWin.ServerIPEditField.Value = cfg.udpServerIP;
            this.cfgWin.ServerPortEditField.Value = cfg.udpServerPort;
            this.cfgWin.ClientTable.Data = cfg.udpClientTable;
            this.OrganizeClientTable();
        end
        
        function ChangeChannelModeUI(this)
            % Change availability of UI controls according to the channel mode
            
            % Turn off all UI control by default
            this.cfgWin.SerialPortDropDown.Enable = 'off';
            this.cfgWin.RefreshButton.Enable = 'off';
            this.cfgWin.BaudRateEditField.Enable = 'off';
            
            this.cfgWin.LocalIPEditField.Enable = 'off';
            this.cfgWin.LocalPortEditField.Enable = 'off';
            
            this.cfgWin.ServerIPEditField.Enable = 'off';
            this.cfgWin.ServerPortEditField.Enable = 'off';
            
            this.cfgWin.ClientTable.Enable = 'off';
            
            
            % Selectively switch UI controls on
            switch this.cfgWin.ChannelModeButtonGroup.SelectedObject.Text
                case 'Standalone'
                    this.cfgWin.SerialPortDropDown.Enable = 'on';
                    this.cfgWin.RefreshButton.Enable = 'on';
                    this.cfgWin.BaudRateEditField.Enable = 'on';
                    
                case 'Client'
                    this.cfgWin.LocalIPEditField.Enable = 'on';
                    this.cfgWin.LocalPortEditField.Enable = 'on';
                    this.cfgWin.ServerIPEditField.Enable = 'on';
                    this.cfgWin.ServerPortEditField.Enable = 'on';
                    
                case 'Server'
                    this.cfgWin.SerialPortDropDown.Enable = 'on';
                    this.cfgWin.RefreshButton.Enable = 'on';
                    this.cfgWin.BaudRateEditField.Enable = 'on';
                    this.cfgWin.LocalIPEditField.Enable = 'on';
                    this.cfgWin.LocalPortEditField.Enable = 'on';
                    this.cfgWin.ClientTable.Enable = 'on';
            end
        end
        
        function RefreshSerialPorts(this, currentPort)
            % Refresh options of serial port
            
            % Find available serial ports
            if ~isempty(currentPort)
                portList = [{currentPort}; this.chan.mserial.availableSerialPorts];
            else
                portList = this.chan.mserial.availableSerialPorts;
            end
            portList = unique(portList, 'stable');
            
            % Display the list
            this.cfgWin.SerialPortDropDown.Items = portList;
            
            % Hightlight port
            try
                this.cfgWin.SerialPortDropDown.Value = portList{1};
            catch
                % when port list is empty
            end
        end
        
        function OrganizeClientTable(this)
            % Add a row to Client table
            
            t = this.cfgWin.ClientTable.Data;
            
            % Remove empty rows
            emptyCell = cellfun(@isempty, t);
            emptyRow = all(emptyCell, 2);
            t(emptyRow,:) = [];
            
            % Add empty row to the end
            t(end+1,:) = cell(1,3);
            
            this.cfgWin.ClientTable.Data = t;
        end
        
        function SimulateLogging(this)
            % Simulate logging
            
            % Get options from GUI
            rawMsg = this.cfgWin.RawMessageEditField.Value;
            msgType = this.cfgWin.MessageTypeButtonGroup.SelectedObject.Text;
            isLogOutputs = this.cfgWin.LogOutMsgCheckBox.Value;
            isTagTime = this.cfgWin.AddTimeTagCheckBox.Value;
            isTagIO = this.cfgWin.AddIOTagCheckBox.Value;
            tagDelimiter = this.cfgWin.TagDelimiterEditField.Value;
            
            if isempty(rawMsg)
                this.cfgWin.LoggedMessageEditField.Value = '';
                return;
            end
            
            % Construct string
            if isTagIO
                ioTag = [msgType(1), tagDelimiter];
            else
                ioTag = '';
            end
            
            if isTagTime
                timeTag = [datestr(now, 'yyyymmddHHMMSSFFF'), tagDelimiter];
            else
                timeTag = '';
            end
            
            % Show logged string
            if msgType(1) == 'I' || isLogOutputs
                this.cfgWin.LoggedMessageEditField.Value = [ioTag, timeTag, rawMsg];
            else
                this.cfgWin.LoggedMessageEditField.Value = '';
            end
        end
        
        function ClearUserFuncData(this)
            % Clear user function data
            
            this.chan.userFuncObj.funcData = [];
        end
        
        function SaveConfig(this)
            % Save configuration
            
            % Get user inputs from GUI
            newCfg.chanMode = this.cfgWin.ChannelModeButtonGroup.SelectedObject.Text;
            
            newCfg.chanName = this.cfgWin.ChannelNameEditField.Value;
            newCfg.refreshRate = this.cfgWin.RefreshRateEditField.Value;
            newCfg.msgPrefix = this.cfgWin.MessagePrefixEditField.Value;
            newCfg.userFuncName = this.cfgWin.UserFunctionDropDown.Value;
            
            newCfg.serialPort = this.cfgWin.SerialPortDropDown.Value;
            newCfg.serialMode = this.cfgWin.SerialProtocolButtonGroup.SelectedObject.Text;
            newCfg.serialBaudRate = this.cfgWin.BaudRateEditField.Value;
            
            newCfg.udpLocalPort = this.cfgWin.LocalPortEditField.Value;
            newCfg.udpServerIP = this.cfgWin.ServerIPEditField.Value;
            newCfg.udpServerPort = this.cfgWin.ServerPortEditField.Value;
            newCfg.udpClientTable = this.cfgWin.ClientTable.Data(1:end-1,:);
            
            newCfg.isLogOutputs = this.cfgWin.LogOutMsgCheckBox.Value;
            newCfg.isTagTime = this.cfgWin.AddTimeTagCheckBox.Value;
            newCfg.isTagIO = this.cfgWin.AddIOTagCheckBox.Value;
            newCfg.tagDelimiter = this.cfgWin.TagDelimiterEditField.Value;
            
            
            % Find whether this is a new channel
            isNewChan = isempty(this.chan.config.chanName);
            
            
            % Check for same names
            allChanNames = cellfun(@(x) x.config.chanName, this.svVm.allChannels, 'Uni', false);
            
            if ~strcmp(newCfg.chanName, this.chan.config.chanName) && any(strcmp(newCfg.chanName, allChanNames))
                uialert(this.cfgWin.UIFigure, ...
                    sprintf('Channel name has to be unique. \nConfiguration is not saved.'), ...
                    'Configuration', ...
                    'Icon', 'warning', ...
                    'Modal', true);
                return;
            end
            
            
            % Apply configuration
            [success, errMsg] = this.chan.ConfigureChannel(newCfg);
            
            
            % GUI feedback
            if success
                if isNewChan
                    this.svVm.allChannels{end+1,1} = this.chan;
                    this.svVm.currentChannel = this.chan;
                end
                
                this.svVm.UpdateChannelUI();
                
                if isempty(errMsg)
                    uialert(this.cfgWin.UIFigure, ...
                        sprintf('Configuration is saved successfully.'), ...
                        'Configuration', ...
                        'Icon', 'success', ...
                        'Modal', true);
                else
                    uialert(this.cfgWin.UIFigure, ...
                        sprintf(['Configuration is saved but the channel cannot be re-enabled.\n' errMsg]), ...
                        'Configuration', ...
                        'Icon', 'info', ...
                        'Modal', true);
                end
            else
                uialert(this.cfgWin.UIFigure, ...
                    sprintf([errMsg, 'Configuration is not saved.']), ...
                    'Configuration', ...
                    'Icon', 'warning', ...
                    'Modal', true);
            end
        end
        
    end
    
    methods(Access=private)
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









