classdef Satellites
    %SATELLITES Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function [txtStr, txtLines] = ReadTxt(svPath)
            % Read plain text of SatellitesViewer log to string(s). 
            % 
            %   [txtStr, txtLines] = Satellites.ReadTxt()
            %   [txtStr, txtLines] = Satellites.ReadTxt(svPath)
            % 
            % Input
            %   svPath              The path of a SatellitesViewer log file. In fact, you can use this method
            %                       to read any text file where lines are delimited by newline return \n. If 
            %                       svPath is not specified, a file selection window will be prompted. 
            % Outputs
            %   txtStr              The entire text file in a single string (character array). 
            %   txtLines            A cell array where each element is a line of the text. 
            % 
            
            % Handles user input
            if nargin < 1 || isempty(svPath)
                [svName, svDir] = uigetfile('*.txt', 'Please select a SatellitesViewer log file');
                if ~svName
                    txtStr = '';
                    txtLines = {};
                    return;
                end
                svPath = fullfile(svDir, svName);
            end
            
            % Read SatellitesViewer log file to text
            try
                fid = fopen(svPath);
                txtStr = fread(fid, '*char')';
                fclose(fid);
            catch
                fclose(fid);
                error(['Error occured when reading ' svPath]);
            end
            
            % Split text string into lines
            txtLines = Satellites.StringToLines(txtStr);
        end
        
        function txtLines = StringToLines(txtStr)
            % Split a string into lines based on return characters. Empty lines are removed. 
            %
            %   txtLines = Satellites.StringToLines(txtStr)
            %
            
            txtLines = strsplit(txtStr, {'\n', '\r'})';
            isEmpty = cellfun(@isempty, txtLines);
            txtLines(isEmpty) = [];
        end
        
        function [ioType, sysTime, eventParts] = LineParts(txtLines, tagDelimiter, msgDelimiter)
            % Parse out IO tag and/or system time tag from message string
            % 
            %   [ioType, sysTime, eventParts] = Satellites.LineParts(txtLines);
            %   [ioType, sysTime, eventParts] = Satellites.LineParts(txtLines, tagDelimiter);
            %   [ioType, sysTime, eventParts] = Satellites.LineParts(txtLines, tagDelimiter, msgDelimiter);
            %
            % Inputs
            %   txtLines            A cell array of lines read from a SatellitesViewer log file.
            %   tagDelimiter        The delimiter for parsing IO and system time tags. The default is ','.
            %   msgDelimiter        The delimiter for parsing event parts. The default is ','.
            % Outputs
            %   ioType              A [nLine,1] character array in which 'I' indicates input, 'O' output, and 
            %                       'N' unspecified. 
            %   sysTime             A [nLine,1] array of datetime objects. Unspecified times are filled with 
            %                       placeholder values of 0001-01-01 00:00:00.000. 
            %   eventParts          A [nLine,1] cell array of [1,nPart] cell arrays of event parts strings. 
            % 
            
            % Handle user inputs
            if nargin < 3
                msgDelimiter = ',';
            end
            
            if nargin < 2
                tagDelimiter = ',';
            end
            
            % Preallocation
            ioType = repmat('N', numel(txtLines), 1);
            sysTime = cell(numel(txtLines), 1);
            eventParts = cell(numel(txtLines), 1);
            
            % Process each line
            for i = 1 : numel(txtLines)
                % Split fields by the tag delimiter
                strParts = strsplit(txtLines{i}, tagDelimiter);
                
                % Extract IO tag
                if any(strcmp(strParts{1}, {'I', 'O'}))
                    ioType(i) = strParts{1};
                    strParts(1) = [];
                end
                
                % Extract system time tag
                if any(regexp(strParts{1}, '^[0-9]{17}$'))
                    sysTime{i,1} = strParts{1};
                    strParts(1) = [];
                else
                    sysTime{i,1} = '00010101000000000';
                end
                
                % Split event string
                if strcmp(tagDelimiter, msgDelimiter)
                    eventParts{i} = strParts;
                else
                    eventStr = strjoin(strParts, tagDelimiter);
                    eventParts{i} = strsplit(eventStr, msgDelimiter);
                end
            end
            
            % Convert data type
            sysTime = datetime(sysTime, ...
                'InputFormat', 'yyyyMMddHHmmssSSS', ...
                'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        end
        
        function eventStruct = GroupEventsByType(eventParts)
            % Categorize different event types into fields of a structure
            % 
            %   eventStruct = Satellites.GroupEventsByType(eventParts)
            %
            % Input
            %   eventParts          A [nEvent,1] cell array of events. Each element is a [1,nPart] cell array 
            %                       of strings in which the first element is event name. 
            % Output
            %   eventStruct         A struct where each type of events are gathered in a field. 
            % 
            
            % Find unique event types
            eventTags = cellfun(@(x) x{1}, eventParts, 'Uni', false);
            [eventTypes, ~, eventInd] = unique(eventTags);
            
            for i = 1 : numel(eventTypes)
                % Legalize field name
                fieldName = eventTypes{i};
                isLegal = isstrprop(fieldName, 'alphanum') | fieldName == '_';
                fieldName(~isLegal) = '_';
                if ~isletter(fieldName(1))
                    fieldName = ['event_' fieldName];
                end
                
                % Add current type of events to struct
                eventStruct.(fieldName) = eventParts(eventInd == i);
            end
        end
        
        function episodes = GroupEventsByTime(eventParts, delimiterEvent)
            % Delimit and group events into episodes by the occurence of certain events
            % 
            %   episodes = Satellites.GroupEventsByTime(eventParts, delimiterEvent)
            %
            % Inputs
            %   eventParts          A [nEvent,1] cell array of events. Each element is a [1,nPart] cell array 
            %                       of strings in which the first element is event name. 
            %   delimiterEvent      Name of the event that delimits different episodes. 
            % Output
            %   episodes            A [nEpisode,1] cell array where each element contains a delimited portion
            %                       of the input eventParts. Importantly, The first episode contains events 
            %                       before the first delimiter event. 
            % 
            
            % Find episode limits
            eventTags = cellfun(@(x) x{1}, eventParts, 'Uni', false);
            eventTags = eventTags(:);
            delimiterInd = find(strcmp(eventTags, delimiterEvent));
            assert(~isempty(delimiterInd), 'The delimiter event, ''%s'', cannot be found.', delimiterEvent);
            episodeStartInd = [1; delimiterInd];
            episodeEndInd = [episodeStartInd(2:end)-1; numel(eventTags)];
            
            % Separate events into episodes
            episodes = cell(numel(episodeStartInd), 1);
            for i = 1 : numel(episodeStartInd)
                episodes{i} = eventParts(episodeStartInd(i) : episodeEndInd(i));
            end
        end
        
        function eventParts = RemoveEventsByType(eventParts, eventTypes)
            % Remove certain types of event
            % 
            %   eventParts = Satellites.RemoveEventsByType(eventParts, eventTypes)
            %
            % Inputs
            %   eventParts          A [nEvent,1] cell array of events. Each element is a [1,nPart] cell array 
            %                       of strings in which the first element is event name. 
            %   eventTypes          A string or an array of strings of event names for removal. 
            % Output
            %   eventParts          Resulting cell array after removal. 
            % 
            
            eventTypes = cellstr(eventTypes);
            
            eventTags = cellfun(@(x) x{1}, eventParts, 'Uni', false);
            
            isRm = false(size(eventParts));
            
            for i = 1 : numel(eventTypes)
                isRm = isRm | strcmp(eventTags, eventTypes{i});
            end
            
            eventParts(isRm) = [];
        end
        
        function result = Import(txt, varargin)
            % Read SatellitesViewer log and organize data into time table and value table.
            % 
            %   result = Satellites.Import()
            %   result = Satellites.Import(txt)
            %   result = Satellites.Import(txt, ..., 'TagDelimiter', ',');
            %   result = Satellites.Import(txt, ..., 'MsgDelimiter', ',');
            %   result = Satellites.Import(txt, ..., 'DelimiterEvent', '');
            %   result = Satellites.Import(txt, ..., 'TimeScaling', 1);
            %
            % Inputs
            %   txt                 1) The path of a SatellitesViewer log file. 2) A string of an entire log. 
            %                       3) Lines of log stored in cell array. If not specified, a file selection 
            %                       window will show up. 
            %   'TagDelimiter'      Delimiter used to parse IO and system time tags. The default is ','.
            %   'MsgDelimiter'      Delimiter used to parse parts in event message. The default is ','.
            %   'DelimiterEvent'    The name of event that delimit the start of an episode. 
            %   'TimeScaling'       A factor to scale timestamps. For example, a scaling factor of 1e-3 can 
            %                       convert millisecond to second. The default is 1 - no scaling. 
            % Output
            %   result              A struct with the following fields.
            %     txtLines            A [nLine,1] cell array of the original text. 
            %     invalidLine         Indices of invalid lines of the text. 
            %     lineParts           Output from Satellites.LineParts but only for valid lines. 
            %     timeTable           A [nEpisode,nEventType] table of event times (wrt episode start time). 
            %     valueTable          A [nEpisode,nEventType] table of event values correspongding to each 
            %                         event time in the timeTable. 
            %     episodeRefTime      A [nEpisode,1] array of absolute times when each episode begins. 
            % 
            
            warning('off', 'backtrace');
            
            % Handle user inputs
            p = inputParser();
            p.KeepUnmatched = true;
            p.addParameter('TagDelimiter', ',', @ischar);
            p.addParameter('MsgDelimiter', ',', @ischar);
            p.addParameter('DelimiterEvent', '', @ischar);
            p.addParameter('TimeScaling', 1, @isscalar);
            
            p.parse(varargin{:});
            tagDelimiter = p.Results.TagDelimiter;
            msgDelimiter = p.Results.MsgDelimiter;
            delimiterEvent = p.Results.DelimiterEvent;
            timeScaling = p.Results.TimeScaling;
            
            % Load text data from file
            if nargin < 1 || isempty(txt)
                [svName, svDir] = uigetfile('*.txt', 'Please select a SatellitesViewer log file');
                if ~svName
                    result = [];
                    return;
                end
                txt = fullfile(svDir, svName);
            end
            if ischar(txt) && exist(txt, 'file')
                [~, txt] = Satellites.ReadTxt(txt);
            end
            if ~iscell(txt)
                txt = Satellites.StringToLines(txt);
            end
            
            % Parse out IO and system time tags
            [ioType, sysTime, eventParts] = Satellites.LineParts(txt, tagDelimiter, msgDelimiter);
            
            % Validate data integrity
            isValid = true(size(eventParts));
            valFunc = @(x) all(isstrprop(x,'digit') | x == '-');
            for i = 1 : numel(eventParts)
                isNum = cellfun(valFunc, eventParts{i}(2:end));
                if ~all(isNum)
                    isValid(i) = false;
                    warning('Cannot interpret values in line %i: %s', i, txt{i});
                end
            end
            if ~all(isValid)
                warning('Invalid messages will be ignored.');
            end
            ioType = ioType(isValid);
            sysTime = sysTime(isValid);
            eventParts = eventParts(isValid);
            
            % Find all types of event
            eventParts = eventParts(ioType == 'I');
            eventTypeStruct = Satellites.GroupEventsByType(eventParts);
            eventTypes = fieldnames(eventTypeStruct);
            
            % Group events into episodes (e.g. trials)
            if isempty(delimiterEvent)
                episodes = {eventParts};
            else
                episodes = Satellites.GroupEventsByTime(eventParts, delimiterEvent);
            end
            
            % Preallocation
            refTime = NaN(numel(episodes), 1);
            timeTb = cell(numel(episodes), numel(eventTypes));
            valueTb = cell(numel(episodes), numel(eventTypes));
            
            % Extract events episode by episode
            for i = 1 : numel(episodes)
                
                % Categorize events
                epStruct = Satellites.GroupEventsByType(episodes{i});
                
                % Episode reference time
                if i == 1
                    % zero time
                    refTime(i) = 0;
                else
                    % the current delimiter event time
                    refTime(i) = getTimes(epStruct.(delimiterEvent)) * timeScaling;
                end
                
                % Extract for each event type
                for k = 1 : numel(eventTypes)
                    eType = eventTypes{k};
                    
                    % Fill in NaN when the event does not exist
                    if ~isfield(epStruct, eType)
                        timeTb{i,k} = NaN;
                        valueTb{i,k} = NaN;
                        continue;
                    end
                    
                    % Extract times
                    timeTb{i,k} = getTimes(epStruct.(eType)) * timeScaling - refTime(i);
                    
                    % Extract values
                    valueTb{i,k} = getValues(epStruct.(eType));
                end
            end
            
            timeTb = cell2table(timeTb, 'VariableNames', eventTypes);
            valueTb = cell2table(valueTb, 'VariableNames', eventTypes);
            
            function et = getTimes(eParts)
                % Get time stamp(s) from each event
                et = cellfun(@(x) str2double(x{2}), eParts);
            end
            
            function ev = getValues(eParts)
                % Get value(s) from each event
                ev = cellfun(@(x) str2double(x(3:end)), eParts, 'Uni', false); % out of range indexing returns NaN
                
                % Fill empty values with NaN
                isEpt = cellfun(@isempty, ev);
                ev(isEpt) = num2cell(NaN(sum(isEpt),1));
                
                % Denest output
                nVals = cellfun(@numel, ev);
                if min(nVals) == max(nVals)
                    ev = cell2mat(ev);
                end
            end
            
            % Denest table columns of cell array with scalar element
            for k = 1 : numel(eventTypes)
                eType = eventTypes{k};
                if isDenestable(timeTb.(eType))
                    timeTb.(eType) = cell2mat(timeTb.(eType));
                end
                if isDenestable(valueTb.(eType))
                    valueTb.(eType) = cell2mat(valueTb.(eType));
                end
            end
            
            function b = isDenestable(a)
                if iscell(a)
                    b = all(cellfun(@(x) isscalar(x) && isnumeric(x), a));
                else
                    b = false;
                end
            end
            
            % Return results
            result.txtLines = txt;
            result.invalidLine = find(~isValid);
            result.lineParts.ioType = ioType;
            result.lineParts.sysTime = sysTime;
            result.lineParts.eventParts = eventParts;
            result.timeTable = timeTb;
            result.valueTable = valueTb;
            result.episodeRefTime = refTime;
            
            warning('on', 'backtrace');
        end
    end
end