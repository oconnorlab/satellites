classdef SatellitesViewerCmdGroup < handle
    %SatellitesViewerCmdGroup Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Interface
        svVM;
        cgWin;
        
        % Content
        winName;
        tabNames;
        tables;
    end
    
    properties(Dependent)
        isWinOpen;
        winPos;
    end
    
    methods
        function val = get.isWinOpen(this)
            % Check if the log window is open
            val = isvalid(this.cgWin);
        end
        function val = get.winPos(this)
            % Find the position of the window
            if this.isWinOpen
                val = get(this.cgWin, 'Position');
            else
                val = [];
            end
        end
    end
    
    methods
        function this = SatellitesViewerCmdGroup(svVM)
            % Constructor of the SatellitesViewerChannel class
            % 
            %   SatellitesViewerCmdGroup()
            %
            
            this.svVM = svVM;
            this.LoadXls();
            this.CreateUI();
            this.RepositionWindow();
        end
        
        function LoadXls(this)
            % Read Excel file
            
            [fileName, dirPath] = uigetfile({'*.xls; *.xlsx', 'Excel Files (*.xls, *.xlsx)'});
            if ~fileName
                return;
            end
            
            try
                filePath = fullfile(dirPath, fileName);
                [~, fileName] = fileparts(filePath);
                [~, sheetNames] = xlsfinfo(filePath);
                
                sheetInd = listdlg('PromptString', 'Select a sheet:', ...
                    'SelectionMode', 'multi', ...
                    'ListString', sheetNames);
                sheetNames = sheetNames(sheetInd);
                
                sheets = cell(numel(sheetInd), 1);
                for i = 1 : numel(sheetInd)
                    [~, ~, sheets{i}] = xlsread(filePath, sheetInd(i), '', 'basic');
                end
                
            catch e
                uialert(this.svVM.svWin.UIFigure, 'Error occured when reading this file.', ...
                    'Loading command group', ...
                    'Icon', 'warning', ...
                    'Modal', true);
                return;
            end
            
            this.winName = fileName;
            this.tabNames = sheetNames;
            this.tables = sheets;
        end
        
        function CreateUI(this)
            % Add GUI controls for command group
            
            if isempty(this.tables)
                return
            end
            
            this.cgWin = uifigure('Name', this.winName, 'Resize', 'off');
            this.cgWin.Position = [this.cgWin.Position(1:2) 100 100];
            tabgp = uitabgroup(this.cgWin);
            
            for i = 1 : numel(this.tabNames)
                tab = uitab(tabgp, 'Title', this.tabNames{i});
                try
                    this.MakeTab(tab, this.tables{i});
                catch e
                    delete(tab);
                    uialert(this.svVM.svWin.UIFigure, ...
                        'Cannot turn spreadsheets to command groups. Please check the format of the content.', ...
                        tab.Title, ...
                        'Icon', 'warning', ...
                        'Modal', true);
                end
            end
            
            tabgp.Position = [0 0 this.cgWin.Position(3:4)];
        end
        
        function RepositionWindow(this)
            % Reposition window based on a table of positional info for all command groups
            
            if ~this.isWinOpen
                return
            end
            
            tb = this.svVM.cmdGroupTb;
            for i = 1 : height(tb)
                if strcmp(tb.winName{i}, this.winName)
                    this.cgWin.Position = tb.winPos{i};
                    break;
                end
            end
        end
    end
    
    methods(Access = private)
        function MakeTab(this, tabObj, tb)
            % Create command group UI from one spreadsheet
            
            % Get content
            tb = tb(2:end, 1:3);
            
            isNotNaN = cellfun(@(x) ~isnan(x(1)), tb);
            isCmdStr = isNotNaN(:,1);
            isVal = isNotNaN(:,2);
            isLabel = isNotNaN(:,3);
            
            cmdNames = tb(isCmdStr,1);
            cmdInd = cumsum(isCmdStr);
            
            % UI position parameters
            xPos = 18;
            yPos = 15;
            
            hCmd = 22;
            wSpace = 10;
            wButton = 50;
            wEdit = 70;
            wLabel = max(cellfun(@length, tb(isLabel,3)))*6;
            
            hFig = hCmd*(size(tb,1) + 2) + yPos*2;
            wFig = wButton + wEdit + wLabel + wSpace*2 + xPos*2;
            
            this.cgWin.Position = max(this.cgWin.Position, [0 0 wFig hFig]);
            
            % Create a button for sending all command groups at the end
            allLabel = uilabel(tabObj, ...
                'Position', [xPos+wButton+wSpace, yPos-3, wButton+wSpace+wLabel, hCmd], ...
                'Text', 'apply all commands above');
            
            uibutton(tabObj, ...
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
                        allLabel.UserData.cmds(i).button = uibutton(tabObj, ...
                            'Position', [xPos, yPos, wButton, hCmd], ...
                            'Text', cmdNames{i}, ...
                            'ButtonPushedFcn', @(btn,event) SendGroupCmd(this, allLabel, i));
                    end
                    
                    % Create a text edit
                    if isVal(fieldInd(j))
                        allLabel.UserData.cmds(i).edits{j} = uieditfield(tabObj, 'text', ...
                            'Position', [xPos+wButton+wSpace, yPos, wEdit, hCmd], ...
                            'Value', num2str(tb{fieldInd(j),2}));
                    else
                        allLabel.UserData.cmdGroups(i).edits{j} = [];
                    end
                    
                    % Create a descriptive label
                    if isLabel(fieldInd(j))
                        uilabel(tabObj, ...
                            'Position', [xPos+wButton+wEdit+wSpace*2, yPos-3, wLabel, hCmd], ...
                            'Text', tb{fieldInd(j),3});
                    end
                end
            end
        end
        
        function SendGroupCmd(this, allLabel, cmdIdx)
            % Output formated command group
            %
            %   SendGroupCmd(allLabel, cmdIdx)
            %
            % Inputs:
            %   groupIdx        The index of a command group. If it is zero, all command groups will be sent.
            
            if cmdIdx ~= 0
                outStr = allLabel.UserData.cmds(cmdIdx).button.Text;
                for j = 1 : length(allLabel.UserData.cmds(cmdIdx).edits)
                    if ~isempty(allLabel.UserData.cmds(cmdIdx).edits{j})
                        outStr = [outStr ',' allLabel.UserData.cmds(cmdIdx).edits{j}.Value];
                    end
                end
                this.svVM.Send(outStr);
            else
                for i = 1 : length(allLabel.UserData.cmds)
                    this.SendGroupCmd(allLabel, i);
                    pause(0.1);
                end
            end
        end
        
    end
end