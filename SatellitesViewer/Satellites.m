classdef Satellites
    %SATELLITES Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function result = Read(svPath, varargin)
            % Read SatellitesViewer log
            % 
            %   result = Read(svPath)
            %   result = Read(svPath, svMetaPath)
            %   result = Read(svPath, ..., 'hasIOTag', ture);
            %   result = Read(svPath, ..., 'hasTimeTag', true);
            %   result = Read(svPath, ..., 'tagDelimiter', ',');
            %   result = Read(svPath, ..., 'msgDelimiter', ',');
            %
            % Inputs:
            %   svPath              Path of a Satellites (or legacy SerialViewer) log file.
            %   svMetaPath          Path of a Satellites metadata file.
            %   'hasIOTag'          Whether or not to parse IO tag.
            %   'hasTimeTag'        Whether or not to parse time tag.
            %   'tagDelimiter'      Delimiter used to parse tags.
            %   'msgDelimiter'      Delimiter used to parse message. Use empty string '' to prevent parsing.
            % 
            % Outputs:
            %   result              A struct of messages and, if applicable, related info. 
            %                       message is a vector of parsed (each a cell array) or unparsed (each a string)
            %                       messages. 
            %                       isInput is a logical vector indicating which messages are input. 
            %                       time is a vector of datetime object
            % 
            
            % Handle user inputs
            p = inputParser();
            p.addRequired('svPath', @(x) exist(x, 'file'));
            p.addOptional('svMetaPath', '', @(x) exist(x, 'file'));
            p.addParameter('hasIOTag', true, @islogical);
            p.addParameter('hasTimeTag', true, @islogical);
            p.addParameter('tagDelimiter', ',', @ischar);
            p.addParameter('msgDelimiter', ',', @ischar);
            
            p.parse(svPath, varargin{:});
            svMetaPath = p.Results.svMetaPath;
            isIO = p.Results.hasIOTag;
            isTime = p.Results.hasTimeTag;
            dTag = p.Results.tagDelimiter;
            dMsg = p.Results.msgDelimiter;
            
            if isIO && isTime && isempty(dTag)
                error('Tag dilimiter cannot be empty.');
            end
            
            
            % Read log file
            [~, ~, svExt] = fileparts(svPath);
            
            if strcmpi(svExt, '.txt')
                % Read SatellitesViewer log file
                try
                    fid = fopen(svPath);
                    svLog = textscan(fid, '%s', 'Delimiter', '\n');
                    svLog = svLog{1};
                    fclose(fid);
                catch
                    fclose(fid);
                    error(['Error occured when reading ' svPath]);
                end
                
                % Read SatellitesViewer metadata
                if ~isempty(svMetaPath)
                    try
                        load(svMetaPath);
                    catch
                        error(['Error occured when loading ' svMetaPath]);
                    end
                end
                
            elseif strcmpi(svExt, '.mat')
                % Read legacy SerialViewer log
                result = Satellites.ReadSerialViewer(svPath, dMsg);
                return;
            end
            
            
            % Process log data
            for i = length(svLog) : -1 : 1
                % Split fields by tag delimiter
                msgParts = strsplit(svLog{i}, dTag);
                
                % Extract tags
                if isIO
                    io(i,1) = msgParts{1};
                    msgParts(1) = [];
                end
                
                if isTime
                    sysTime{i,1} = msgParts{1};
                    msgParts(1) = [];
                end
                
                % Parse message
                if strcmp(dMsg, dTag)
                    fullMsg = strjoin(msgParts, dTag);
                    msgParts = strsplit(fullMsg, dMsg);
                end
                
                msg{i,1} = msgParts;
            end
            
            % Convert date string to datetime
            if isTime
                sysTime = datetime(sysTime, 'InputFormat', 'yyyyMMddHHmmssSSS');
            end
            
            % De-nest msg if no parsing occured
            numParts = cellfun(@length, msg);
            if all(numParts == 1)
                msg = cellfun(@(x) x{1}, msg, 'Uni', false);
            end
            
            
            % Output
            result.message = msg;
            
            if isIO
                result.isInput = io == 'I';
            end
            
            if isTime
                result.sysTime = sysTime;
            end
        end
        
        function result = ReadToTables(svPath, delimiterEventName, varargin)
            % Read SatellitesViewer log and organize data into time table and value table
            % 
            %   result = ReadToTables(svPath, delimiterEventName)
            %   result = ReadToTables(svPath, delimiterEventName, svMetaPath)
            %   result = ReadToTables(svPath, delimiterEventName, ..., 'timeVars', {});
            %   result = ReadToTables(svPath, delimiterEventName, ..., 'valueVars', {});
            %   result = ReadToTables(svPath, delimiterEventName, ..., 'mask', []);
            %
            % Inputs:
            %   svPath              Path of a Satellites (or legacy SerialViewer) log file.
            %   delimiterEventName  
            %   svMetaPath          Path of a Satellites metadata file.
            %   'timeVars'          
            %   'valueVars'         
            %   'mask'              
            % 
            % Outputs:
            %   result              
            % 
            
            % Handle user inputs
            p = inputParser();
            p.KeepUnmatched = true;
            p.addRequired('svPath');
            p.addRequired('delimiterEventName', @ischar);
            p.addOptional('svMetaPath', '', @(x) exist(x, 'file'));
            p.addParameter('timeVars', {}, @iscell);
            p.addParameter('valueVars', {}, @iscell);
            p.addParameter('mask', [], @(x) isnumeric(x) || islogical(x));
            
            p.parse(svPath, delimiterEventName, varargin{:});
            svMetaPath = p.Results.svMetaPath;
            timeVars = p.Results.timeVars;
            valueVars = p.Results.valueVars;
            trialMask = p.Results.mask(:);
            
            
            % Load SerialViewer history data
            if isempty(svPath)
                svPath = Browse.File([], 'Please select a SerialViewer log file', {'*.mat; *.txt'});
            end
            
            if isempty(svPath)
                return;
            else
                disp('Load SatellitesViewer (or SerialViewer) log file.');
                svLog = Satellites.Read(svPath);
                events = svLog.message(svLog.isInput);
            end
            
            
            % Decompose data temporally - by episode (usually trial)
            episodes = Satellites.ParseByEventTime(events, delimiterEventName);
            
            
            % Initialize tables
            trialTimeRef = NaN(size(episodes));
            timeTb = cell(length(episodes), length(timeVars));
            valueTb = cell(length(episodes), length(valueVars));
            
            
            % Extract events trial by trial
            for i = 1 : length(episodes)
                
                % Categorize events
                eventStruct = Satellites.ParseByEventType(episodes{i});
                
                % Find episode reference time which is determined by the episode delimiter event
                trialTimeRef(i) = str2double(eventStruct.(delimiterEventName){2});
                
                % Extract for time table
                for k = 1 : length(timeVars)
                    fieldName = timeVars{k};
                    
                    if isfield(eventStruct, fieldName)
                        % Take relative time wrt the reference time
                        t = str2double(eventStruct.(fieldName)(:,2));
                        timeTb{i,k} = t - trialTimeRef(i);
                    else
                        % Fill in NaN when the event does not exist
                        timeTb{i,k} = NaN;
                    end
                end
                
                % Extract for value table
                for k = 1 : length(valueVars)
                    fieldName = valueVars{k};
                    
                    if isfield(eventStruct, fieldName)
                        % Take event values
                        valueTb{i,k} = str2double(eventStruct.(fieldName)(:,3:end));
                    else
                        % Fill in NaN when the event does not exist
                        valueTb{i,k} = NaN;
                    end
                end
            end
            
            timeTb = cell2table(timeTb, 'VariableNames', timeVars);
            valueTb = cell2table(valueTb, 'VariableNames', valueVars);
            
            
            
            % Try to convert cell array to numeric array
            for k = 1 : length(timeVars)
                try
                    fieldName = timeVars{k};
                    timeTb.(fieldName) = cell2mat(timeTb.(fieldName));
                catch
                end
            end
            
            for k = 1 : length(valueVars)
                try
                    fieldName = valueVars{k};
                    valueTb.(fieldName) = cell2mat(valueTb.(fieldName));
                catch
                end
            end
            
            
            % Remove unwanted trials
            if ~isempty(trialMask)
                timeTb = timeTb(trialMask,:);
                valueTb = valueTb(trialMask,:);
                trialTimeRef = trialTimeRef(trialMask);
            end
            
            
            % Return results
            result.timeTable = timeTb;
            result.valueTable = valueTb;
            result.trialTimeRef = trialTimeRef;
            result.info.log = svLog;
            
        end
        
        function events = RemoveEvents(events, eventTypes)
            % Remove events by specified event type(s)
            % 
            %   events = RemoveEvents(events, eventTypes)
            %
            % Inputs:
            %   events              A 1-D cell array of parsed messages. Each element is a 1-D 
            %                       cell array where the first element is event name of the message. 
            %   eventTypes          A string or an array of strings of event names for removal. 
            % 
            % Outputs:
            %   events              Resulting messages after removal. 
            % 
            
            eventTypes = cellstr(eventTypes);
            
            if isstruct(events)
                
                events = rmfield(events, eventTypes);
                
            elseif iscell(events)
                
                eventTags = cellfun(@(x) x{1}, events, 'Uni', false);
                
                eventExcludeMask = false(size(events));
                
                for i = 1 : length(eventTypes)
                    eventExcludeMask = eventExcludeMask | strcmp(eventTypes{i}, eventTags);
                end
                
                events(eventExcludeMask) = [];
                
            else
                error('Wrong data format. Should be either a struct or a vector of cell arrays.');
            end
        end
        
        function eventStruct = ParseByEventType(events)
            % Categorize different event types into fields of a structure
            % 
            %   eventStruct = ParseByEventType(events)
            %
            % Inputs:
            %   events              A 1-D cell array of parsed messages. Each element is a 1-D 
            %                       cell array where the first element is event name of the message. 
            % 
            % Outputs:
            %   eventStruct         A struct in which each type of events are gathered in a field. 
            % 
            
            % Find types
            eventTags = cellfun(@(x) x{1}, events, 'Uni', false);
            [eventTypes, ~, eventInd] = unique(eventTags);
            
            for i = length(eventTypes) : -1 : 1
                % Masking for the current event type
                eventDataVect = events(eventInd == i);
                
                % When the length of data is not uniform, take the shortest
                eventLengths = cellfun(@length, eventDataVect);
                if length(unique(eventLengths)) > 1
                    warning(['"' fieldName '" has variable length of data. Only the common parts are taken.']);
                    minLength = min(eventLengths);
                    eventDataVect = cellfun(@(x) x(1:minLength), eventDataVect, 'Uni', false);
                end
                
                % Legalize field name
                try
                    fieldName = strrep(eventTypes{i}, ' ', '_');
                    eventStruct.(fieldName) = cat(1, eventDataVect{:});
                catch
                    warning(['"' fieldName '" is not a legal field name thus cannot included in the output struct']);
                end
            end
        end
        
        function [episodes, preEpisode] = ParseByEventTime(events, delimiterTag)
            % Delimit and group events into episodes by the occurence of certain events
            % 
            %   [episodes, preEpisode] = ParseByEventTime(events, delimiterTag)
            %
            % Inputs:
            %   events              A 1-D cell array of parsed messages. Each element is a 1-D 
            %                       cell array where the first element is event name of the message. 
            %   delimiterTag        
            % 
            % Outputs:
            %   episodes            A struct in which each type of events are gathered in a field. 
            %   preEpisode          
            % 
            
            eventTags = cellfun(@(x) x{1}, events, 'Uni', false);
            episodeOnInd = find(strcmp(delimiterTag, eventTags));
            episodeOffInd = [episodeOnInd(2:end) - 1; length(eventTags)];
            
            preEpisode = events(1 : episodeOnInd(1)-1);
            
            for i = length(episodeOnInd) : -1 : 1
                episodes{i,1} = events(episodeOnInd(i) : episodeOffInd(i));
            end
        end
        
        function result = ReadSerialViewer(svPath, d)
            % Convert SerialViewer data format to SatellitesViewer data format
            
            if nargin < 2
                d = ',';
            end
            
            load(svPath);
            
            % Find valid data messages
            hasRigId = regexp(serialInHistory(:,1), ['^\d{1,3}' d]);
            hasRigId = ~cellfun(@isempty, hasRigId);
            if any(hasRigId)
                serialInHistory = serialInHistory(hasRigId, :);
            end
            
            % Split fields by delimiter
            msg = cellfun(@(x) strsplit(x, d), serialInHistory(:,1), 'Uni', false);
            
            % Remove rig ID field
            if any(hasRigId)
                msg = cellfun(@(x) x(2:end), msg, 'Uni', false);
            end
            
            % Convert numeric time to DateTime object
            sysTime = datevec(cell2mat(serialInHistory(:,2)));
            sysTime = datetime(sysTime);
            
            % Screen split data by length
            numParts = cellfun(@length, msg);
            isTooShort = numParts < 2;
            if any(isTooShort)
                warning(['Found message(s) having data fields less than 2 (EventTag,TimeStamp,...). ' ...
                    'They will be excluded from result.']);
            end
            msg(isTooShort) = [];
            sysTime(isTooShort) = [];
            
            % Output
            result.message = msg;
            result.sysTime = sysTime;
            result.isInput = true(size(msg));
        end
    end
    
end









