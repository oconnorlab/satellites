classdef SatellitesViewerVM < handle
    %The view-model of SatellitesViewer
    %   Detailed explanation goes here
    
    properties
        % Interface
        svWin;
        chanConfigWin;
        cmdGroupWins;
        
        % Communication
        currentChannel;
        allChannels = {};
        dispatcherTimer;
        
        % Miscellaneous
        isVerbose = true;
    end
    
    methods
        function this = SatellitesViewerVM(appObj)
            % Constructor of the SatellitesViewerVM class
            %
            %   SatellitesViewerVM(appObj)
            %
            % Input:
            %   appObj      app object of AppDesigner
            %
            
            % Keep an internal reference of the app object
            this.svWin = appObj;
            
            
            % Hide window when changing UI controls
            this.svWin.UIFigure.Visible = 'off';
            
            % UI controls in Main tab
            this.svWin.LogFileNameEdit.Value = '';
            this.svWin.AppendTimeCheckBox.Value = true;
            
            % UI controls in Quick Commands tab
            quickCmds = repmat({''}, 60, 1);
            
            wEdit = 135;
            wButton = 22;
            h = 22;
            s = 15;
            
            gridMat = ones(20, 3);
            xPosMat = 17 + (cumsum(gridMat,2) - 1) * (wEdit + wButton + s);
            yPosMat = this.svWin.QuickCmdTab.Position(4) - 60 - (cumsum(gridMat,1) - 1) * h;
            
            for i = length(quickCmds) : -1 : 1
                this.svWin.quickCmdEdits{i} = uieditfield(this.svWin.QuickCmdTab, 'text', ...
                    'Position', [xPosMat(i), yPosMat(i), wEdit, h], ...
                    'Value', quickCmds{i});
                
                this.svWin.quickCmdButtons{i} = uibutton(this.svWin.QuickCmdTab, ...
                    'Position', [xPosMat(i)+wEdit, yPosMat(i), wButton, h], ...
                    'Text', '->', ...
                    'ButtonPushedFcn', @(btn,event) SendQuickCmd(this, i));
            end
            
            % About tab
            classPath = mfilename('fullpath');
            classDir = fileparts(classPath);
            this.svWin.TextArea.Value = fileread(fullfile(classDir, 'readme.txt'));
            
            % Show window
            this.svWin.UIFigure.Visible = 'on';
            
            
            % Setup communication processing routine
            this.dispatcherTimer = timer;
            this.dispatcherTimer.ExecutionMode = 'fixedSpacing';
            this.dispatcherTimer.TasksToExecute = inf;
            this.dispatcherTimer.Period = 1;
            this.dispatcherTimer.BusyMode = 'drop';
            this.dispatcherTimer.TimerFcn = @(~,~)DispatcherRoutine(this);
            start(this.dispatcherTimer);
            
        end
        
        function SaveSettings(this)
            % Save app settings to 'svConfig.mat' file
            
            [fileName, pathName] = uiputfile('*.mat', 'Save Settings', 'sv settings');
            
            if fileName == 0
                return;
            end
            
            try
                % Get main window info
                s.svWinPos = this.svWin.UIFigure.Position;
                s.logFileName = this.svWin.LogFileNameEdit.Value;
                s.isAppendTime = this.svWin.AppendTimeCheckBox.Value;
                
                % Collect configurations
                s.configs = cellfun(@(x) x.config, this.allChannels, 'Uni', false);
                
                if ~isempty(s.configs)
                    currentChannelName = this.currentChannel.chanName;
                    allChannelNames = cellfun(@(x) x.chanName, this.allChannels, 'Uni', false);
                    s.currentChannelIdx = find(strcmp(currentChannelName, allChannelNames));
                else
                    s.currentChannelIdx = [];
                end
                
                % Get log window status and position
                s.logWinPos = cellfun(@(x) x.logWinPos, this.allChannels, 'Uni', false);
                
                % Get quick commands
                s.quickCmds = cellfun(@(x) x.Value, this.svWin.quickCmdEdits', 'Uni', false);
                
                % Get command group positions
                % TBD
                
                % Save settings
                fullPath = fullfile(pathName, fileName);
                save(fullPath, '-struct', 's');
                
                % Report success
                uialert(this.svWin.UIFigure, ...
                    sprintf('Current settings is saved successfully.'), ...
                    'Save Settings', ...
                    'Icon', 'success', ...
                    'Modal', true);
                
            catch e
                % Report error
                this.DispIfVerbose(e);
                save('svException.mat', 'e');
                
                uialert(this.svWin.UIFigure, ...
                    sprintf('Error occured when saving settings.'), ...
                    'Save Settings', ...
                    'Icon', 'error', ...
                    'Modal', true);
            end
        end
        
        function LoadSettings(this)
            % Load app settings using GUI
            
            % Select settings file
            [fileName, dirPath] = uigetfile({'*.mat', 'MAT-file (*.mat)'});
            
            if ~fileName
                return;
            end
            
            filePath = fullfile(dirPath, fileName);
            
            % Load MAT file
            try
                load(filePath);
            catch
                uialert(this.svWin.UIFigure, 'Error occured when loading this MAT file.', ...
                    'Settings', ...
                    'Icon', 'warning', ...
                    'Modal', true);
                return;
            end
            
            % Check variables
            if ~exist('configs', 'var')
                uialert(this.svWin.UIFigure, 'Cannot find configs in this MAT file.', ...
                    'Settings', ...
                    'Icon', 'warning', ...
                    'Modal', true);
                return;
            end
            
            if ~exist('logWinPos', 'var')
                logWinPos = repmat({[]}, size(configs));
            end
            
            if ~exist('quickCmds', 'var')
                warning('quickCmds was not found. Use empty quick commands. ');
                quickCmds = repmat({''}, 60, 1);
            end
            
            if ~exist('currentChannelIdx', 'var')
                currentChannelIdx = 1;
            end
            
            % Apply main window options
            if exist('svWinPos', 'var')
                this.svWin.UIFigure.Position = svWinPos;
            end
            if exist('logFileName', 'var')
                this.svWin.LogFileNameEdit.Value = logFileName;
            end
            if exist('isAppendTime', 'var')
                this.svWin.AppendTimeCheckBox.Value = isAppendTime;
            end
            
            % Delete all channels
            stop(this.dispatcherTimer);
            cellfun(@(x) x.DeleteChannel(), this.allChannels);
            this.allChannels = {};
            this.currentChannel = [];
            
            try
                % Channels
                if ~isempty(configs)
                    for i = length(configs) : -1 : 1
                        this.allChannels{i,1} = SatellitesViewerChannel();
                        this.allChannels{i}.ConfigureChannel(configs{i});
                        if ~isempty(logWinPos{i})
                            this.allChannels{i}.ShowLogWindow(logWinPos{i});
                        end
                    end
                    this.currentChannel = this.allChannels{currentChannelIdx};
                end
                
                % Quick commands
                for i = 1 : min(length(quickCmds), length(this.svWin.quickCmdEdits))
                    if ~isempty(quickCmds{i})
                        this.svWin.quickCmdEdits{i}.Value = quickCmds{i};
                    end
                end
                
            catch e
                % Delete all channels
                cellfun(@(x) x.DeleteChannel(), this.allChannels);
                this.allChannels = {};
                this.currentChannel = [];
                
                uialert(this.svWin.UIFigure, 'Error occured when applying settings. Default settings is used.', ...
                    'Settings', ...
                    'Icon', 'warning', ...
                    'Modal', true);
                
                this.DispIfVerbose(e);
                save('svException.mat', 'e');
            end
            
            % Update GUI
            this.UpdateChannelUI();
            
            start(this.dispatcherTimer);
        end
        
        function LoadCmdGroup(this)
            % Add GUI controls for command group
            
            % Read Excel file
            [fileName, dirPath] = uigetfile({'*.xls; *.xlsx', 'Excel Files (*.xls, *.xlsx)'});
            
            if ~fileName
                return;
            end
            
            try
                filePath = fullfile(dirPath, fileName);
                [~, bareName] = fileparts(filePath);
                
                [~, sheets] = xlsfinfo(filePath);
                
                sheetInd = listdlg('PromptString', 'Select a sheet:', ...
                    'SelectionMode', 'multi', ...
                    'ListString', sheets);
                
                if isempty(sheetInd)
                    return;
                end
                
                % Create new UI controls
                winObj = uifigure('Name', bareName, 'Resize', 'off');
                winObj.Position = [winObj.Position(1:2) 100 100];
                tabgp = uitabgroup(winObj);
                
                for i = 1 : length(sheetInd)
                    [~, ~, xlsArray] = xlsread(filePath, sheetInd(i), '', 'basic');
                    tab = uitab(tabgp, 'Title', sheets{sheetInd(i)});
                    
                    try
                        this.CreatCmdGroupUI(winObj, tab, xlsArray);
                    catch e
                        delete(tab);
                        uialert(this.svWin.UIFigure, ...
                            'Cannot create this command group. Please check the format of the content.', ...
                            tab.Title, ...
                            'Icon', 'warning', ...
                            'Modal', true);
                    end
                end
                
                tabgp.Position = [0 0 winObj.Position(3:4)];
                
                this.cmdGroupWins{end+1} = winObj;
                
            catch e
                uialert(this.svWin.UIFigure, 'Error occured when reading this file.', ...
                    'Loading command group', ...
                    'Icon', 'warning', ...
                    'Modal', true);
                return;
            end
        end
        
        function CloseApp(this)
            % Close the app
            
            try
                % Stop timer for DispatcherRoutine() method
                stop(this.dispatcherTimer);
                delete(this.dispatcherTimer);
            catch e
                this.DispIfVerbose(e);
                save('svException.mat', 'e');
            end
            
            try
                % Delete all channels
                cellfun(@(x) x.DeleteChannel(), this.allChannels);
            catch e
                this.DispIfVerbose(e);
                save('svException.mat', 'e');
            end
            
            % Close existing command group windows
            for i = 1 : length(this.cmdGroupWins)
                try
                    delete(this.cmdGroupWins{i});
                catch
                end
            end
            
            this.delete();
        end
        
        function AddChannel(this)
            % Add a new communication channel
            
            if isa(this.chanConfigWin, 'ChannelConfig')
                this.chanConfigWin.delete();
                this.chanConfigWin = [];
            end
            
            this.DisableChannelUI();
            
            % Open channel configuration window and initialze with a new channel object
            this.chanConfigWin = ChannelConfig();
            this.chanConfigWin.vm.Initialize(this, SatellitesViewerChannel());
            
            waitfor(this.chanConfigWin);
            this.EnableChannelUI();
        end
        
        function ConfigureChannel(this)
            % Configure the current communication channel
            
            if ~this.IsCurrentChannelExist()
                return;
            end
            
            if isa(this.chanConfigWin, 'ChannelConfig')
                this.chanConfigWin.delete();
                this.chanConfigWin = [];
            end
            
            this.DisableChannelUI();
            
            % Open channel configuration window and initialze with the current channel object
            this.chanConfigWin = ChannelConfig();
            this.chanConfigWin.vm.Initialize(this, this.currentChannel);
            
            waitfor(this.chanConfigWin);
            this.EnableChannelUI();
        end
        
        function DeleteChannel(this)
            % Delete the current communication channel
            
            if ~this.IsCurrentChannelExist()
                return;
            end
            
            this.DisableChannelUI();
            
            % Double-check with user
            a = questdlg('Are you sure to delete the currently selected channel?', 'Delete Channel', 'Yes', 'No', 'No');
            
            if strcmpi(a, 'Yes')
                % Safely delete the current channel
                this.currentChannel.DeleteChannel();
                
                % Find and remove the entry in allChannels
                this.allChannels(~cellfun(@isvalid, this.allChannels)) = [];
                
                % Set new current channel
                if ~isempty(this.allChannels)
                    this.currentChannel = this.allChannels{1};
                else
                    this.allChannels = {};
                    this.currentChannel = [];
                end
                
                this.DispIfVerbose('this.currentChannel');
                this.DispIfVerbose(this.currentChannel);
                this.DispIfVerbose('this.allChannels');
                this.DispIfVerbose(this.allChannels);
                
                % Update GUI
                this.UpdateChannelUI();
            end
            
            this.EnableChannelUI();
        end
        
        function ChangeCurrentChannel(this)
            % Change the currently selected channel
            
            newChanName = this.svWin.CurrentChannelDropDown.Value;
            allChanNames = cellfun(@(x) x.config.chanName, this.allChannels, 'Uni', false);
            newChanIdx = find(strcmp(newChanName, allChanNames), 1, 'first');
            
            this.currentChannel = this.allChannels{newChanIdx};
            
            this.DispIfVerbose('this.currentChannel.config');
            this.DispIfVerbose(this.currentChannel.config);
            this.DispIfVerbose('this.allChannels');
            this.DispIfVerbose(this.allChannels);
            
            % Update GUI
            this.UpdateChannelUI();
        end
        
        function isEnable = SwitchChannelEnable(this, isEnable)
            % Enable or disable the current communication channel
            
            if ~this.IsCurrentChannelExist()
                isEnable = false;
                return;
            end
            
            if isEnable
                % Try enable
                [success, errMsg] = this.currentChannel.EnableChannel();
                
                if ~success
                    % Prompt error message box
                    uialert(this.svWin.UIFigure, [errMsg, 'The channel is not enabled.'], ...
                        'Channel', ...
                        'Icon', 'warning', ...
                        'Modal', true);
                end
            else
                this.currentChannel.DisableChannel();
            end
            
            isEnable = this.currentChannel.config.isChanEnabled;
            
            this.DispIfVerbose('this.currentChannel.config');
            this.DispIfVerbose(this.currentChannel.config);
            this.DispIfVerbose('this.allChannels');
            this.DispIfVerbose(this.allChannels);
            
            this.UpdateChannelUI();
        end
        
        function UpdateChannelUI(this)
            % Update channel related UI
            
            if isempty(this.currentChannel)
                % Restore default values on GUI
                this.svWin.ChannelTable.Data = [];
                this.svWin.EnableCheckBox.Value = false;
                
            else
                % Update channel table
                ct = cell(length(this.allChannels), 6); i = 1;
                ct(:,i) = cellfun(@(x) x.config.isChanEnabled, this.allChannels, 'Uni', false); i = i+1;
                ct(:,i) = cellfun(@(x) x.config.chanName, this.allChannels, 'Uni', false); i = i+1;
                ct(:,i) = cellfun(@(x) x.mainPort, this.allChannels, 'Uni', false); i = i+1;
                ct(:,i) = cellfun(@(x) lower(x.config.chanMode), this.allChannels, 'Uni', false); i = i+1;
                ct(:,i) = cellfun(@(x) [num2str(size(x.logArray,1)), ' lines'], this.allChannels, 'Uni', false); i = i+1;
                ct(:,i) = cellfun(@(x) x.config.userFuncName, this.allChannels, 'Uni', false);
                
                this.svWin.ChannelTable.Data = ct;
                
                % Current channel
                this.svWin.CurrentChannelDropDown.Items = ct(:,2);
                this.svWin.CurrentChannelDropDown.Value = this.currentChannel.config.chanName;
                this.svWin.EnableCheckBox.Value = this.currentChannel.config.isChanEnabled;
            end
        end
        
        function Send(this, outStr)
            % Process and dispatch command string
            
            if isempty(outStr)
                return;
            end
            
            % Check current channel
            if ~this.IsCurrentChannelExist()
                return;
            end
            
            if ~this.currentChannel.config.isChanEnabled
                uialert(this.svWin.UIFigure, ...
                    'The message is not sent because the current channel is not enabled.', ...
                    'Channel', ...
                    'Icon', 'warning', ...
                    'Modal', true);
                return;
            end
            
            % Send message via the current channel
            [success, errMsg] = this.currentChannel.SendMessage(outStr);
            
            if ~success
                % Update UI to reflect disabled state
                this.UpdateChannelUI();
                
                % Report error
                uialert(this.svWin.UIFigure, ...
                    sprintf([errMsg, '\nThe current channel is disabled.']), ...
                    'Channel', ...
                    'Icon', 'warning', ...
                    'Modal', true);
            end
        end
        
        function SaveLog(this)
            % Save log in the current channel
            
            if ~this.IsCurrentChannelExist()
                return;
            end
            
            % Initialize file name
            fileName = this.svWin.LogFileNameEdit.Value;
            
            if isempty(fileName)
                fileName = 'SatellitesViewer Log';
            end
            
            if this.svWin.AppendTimeCheckBox.Value
                fileName = [fileName, ' ', datestr(now, 'yyyy-mm-dd HH-MM-SS')];
            end
            
            % Prompt GUI
            [fileName, pathName] = uiputfile('*.txt', 'Save Log', [fileName '.txt']);
            
            if fileName
                % Save log
                [success, errMsg] = this.currentChannel.SaveLog(fullfile(pathName, fileName));
                
                if success
                    uialert(this.svWin.UIFigure, ...
                        sprintf('The log of %s channel is saved successfully.', this.currentChannel.config.chanName), ...
                        'Save', ...
                        'Icon', 'success', ...
                        'Modal', true);
                else
                    uialert(this.svWin.UIFigure, ...
                        sprintf('%s.\nFailed to save the log of %s channel.', errMsg, this.currentChannel.config.chanName), ...
                        'Save', ...
                        'Icon', 'error', ...
                        'Modal', true);
                end
            end
        end
        
        function DeleteLog(this)
            % Delete log in the current channel
            
            if ~this.IsCurrentChannelExist()
                return;
            end
            
            choice = questdlg( ...
                sprintf(['This will delete all input and output messages in the current channel. ' ...
                'Do you want to proceed doing this?']), ...
                'Warning', ...
                'Yes, delete all', 'No', 'No');
            
            if strcmp(choice, 'Yes, delete all')
                this.currentChannel.DeleteLog();
            end
        end
        
        function ShowLogWindow(this)
            % Show log window of the current channel
            
            if this.IsCurrentChannelExist()
                this.currentChannel.ShowLogWindow();
            end
        end
        
    end
    
    methods(Access = private)
        function DispatcherRoutine(this)
            % DispatcherRoutine
            
            try
                this.UpdateChannelUI();
            catch e
                this.DispIfVerbose(e);
                save('svException.mat', 'e');
            end
        end
        
        function isExist = IsCurrentChannelExist(this)
            % Check whether or not the current channel exists
            
            isExist = ~isempty(this.currentChannel);
            
            if ~isExist
                uialert(this.svWin.UIFigure, ...
                    sprintf('Current channel is not available.\nYou may want to add a new channel first.'), ...
                    'No Channel', ...
                    'Icon', 'info', ...
                    'Modal', true);
            end
        end
        
        function SendQuickCmd(this, cmdIdx)
            % Callback function for sending message after quick command button press
            
            this.Send(this.svWin.quickCmdEdits{cmdIdx}.Value);
        end
        
        function SendGroupCmd(this, winObj, cmdIdx)
            % Output formated command group
            %
            %   SendSerialCmdGroup(groupIdx)
            %
            % Inputs:
            %   groupIdx        The index of a command group. If it is zero, all command groups will be sent.
            
            if cmdIdx ~= 0
                outStr = winObj.UserData.cmds(cmdIdx).button.Text;
                for j = 1 : length(winObj.UserData.cmds(cmdIdx).edits)
                    if ~isempty(winObj.UserData.cmds(cmdIdx).edits{j})
                        outStr = [outStr ',' winObj.UserData.cmds(cmdIdx).edits{j}.Value];
                    end
                end
                this.Send(outStr);
            else
                for i = 1 : length(winObj.UserData.cmds)
                    this.SendGroupCmd(winObj, i);
                    pause(0.1);
                end
            end
        end
        
        function EnableChannelUI(this)
            % Enable communication related buttons
            
            this.svWin.AddChannelButton.Enable = 'on';
            this.svWin.CurrentChannelDropDown.Enable = 'on';
            this.svWin.EnableCheckBox.Enable = 'on';
            this.svWin.ConfigureButton.Enable = 'on';
            this.svWin.DeleteChannelButton.Enable = 'on';
            this.svWin.LoadSettingsButton.Enable = 'on';
            this.svWin.SaveSettingsButton.Enable = 'on';
        end
        
        function DisableChannelUI(this)
            % Disable communication related buttons
            
            this.svWin.AddChannelButton.Enable = 'off';
            this.svWin.CurrentChannelDropDown.Enable = 'off';
            this.svWin.EnableCheckBox.Enable = 'off';
            this.svWin.ConfigureButton.Enable = 'off';
            this.svWin.DeleteChannelButton.Enable = 'off';
            this.svWin.LoadSettingsButton.Enable = 'off';
            this.svWin.SaveSettingsButton.Enable = 'off';
        end
        
        function CreatCmdGroupUI(this, winObj, tab, xlsArray)
            % Create command group UI from one spreadsheet
            
            % Get content
            xlsArray = xlsArray(2:end, 1:3);
            
            isNotNaN = cellfun(@(x) ~isnan(x(1)), xlsArray);
            isCmdStr = isNotNaN(:,1);
            isVal = isNotNaN(:,2);
            isLabel = isNotNaN(:,3);
            
            cmdNames = xlsArray(isCmdStr,1);
            cmdInd = cumsum(isCmdStr);
            
            % UI position parameters
            xPos = 18;
            yPos = 15;
            
            hCmd = 22;
            wSpace = 10;
            wButton = 50;
            wEdit = 70;
            wLabel = max(cellfun(@length, xlsArray(isLabel,3)))*6;
            
            hFig = hCmd*(size(xlsArray,1) + 2) + yPos*2;
            wFig = wButton + wEdit + wLabel + wSpace*2 + xPos*2;
            
            winObj.Position = max(winObj.Position, [0 0 wFig hFig]);
            
            % Create a button for sending all command groups at the end
            allLabel = uilabel(tab, ...
                'Position', [xPos+wButton+wSpace, yPos-3, wButton+wSpace+wLabel, hCmd], ...
                'Text', 'apply all commands above');
            
            uibutton(tab, ...
                'Position', [xPos, yPos, wButton, hCmd], ...
                'Text', 'All', ...
                'ButtonPushedFcn', @(btn,event) SendGroupCmd(this, allLabel, 0));
            
            % Iterate through unique commands
            for i = length(cmdNames) : -1 : 1
                fieldInd = find(i == cmdInd);
                
                % Iterate through individual members
                for j = length(fieldInd) : -1 : 1
                    
                    yPos = yPos + hCmd;
                    
                    % Create a button for sending the command group at the first member
                    if j == 1
                        allLabel.UserData.cmds(i).button = uibutton(tab, ...
                            'Position', [xPos, yPos, wButton, hCmd], ...
                            'Text', cmdNames{i}, ...
                            'ButtonPushedFcn', @(btn,event) SendGroupCmd(this, allLabel, i));
                    end
                    
                    % Create a text edit
                    if isVal(fieldInd(j))
                        allLabel.UserData.cmds(i).edits{j} = uieditfield(tab, 'text', ...
                            'Position', [xPos+wButton+wSpace, yPos, wEdit, hCmd], ...
                            'Value', num2str(xlsArray{fieldInd(j),2}));
                    else
                        allLabel.UserData.cmdGroups(i).edits{j} = [];
                    end
                    
                    % Create a descriptive label
                    if isLabel(fieldInd(j))
                        uilabel(tab, ...
                            'Position', [xPos+wButton+wEdit+wSpace*2, yPos-3, wLabel, hCmd], ...
                            'Text', xlsArray{fieldInd(j),3});
                    end
                end
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