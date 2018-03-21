classdef UserFuncModel < handle
    % UserFuncModel object is the only input to user function
    % 
    % Properties
    %   channelName         The name of Channel in string where the user funtion is used
    %   msgIn               The incoming message string
    %   isDisplay           Logical variable indicating whether or not this message should be displayed in log window
    %   userData            Where user stores everything (e.g. runtime data, figure handles, etc.)
    %   msgOut              A message string or a cell array of message strings to send out
    %   
    % Methods
    %   SendMessage         Send a message string out to device
    %   ClearUserData       Clear user data
    %   BeginWith           Test whether or not the incoming message begins with a given substring
    %
    % More functionalities will be added in the future.
    % 
    % 
    
    properties
        channelName = '';
        msgIn = '';
        isDisplay = true;
        msgOut = {};
        userData;
    end
    
    methods
        function this = UserFuncModel()
            % Constructor of UserFuncData class
            % do nothing
        end
        
        function SendMessage(this, m)
            % Add message to a queue for output
            if ischar(m) && ~isempty(m)
                this.msgOut{end+1,1} = m;
            end
        end
        
        function ClearUserData(this)
            % Set userData variable to empty
            this.userData = [];
        end
        
        function isBegin = BeginWith(this, beginStr, fullStr)
            % Check if a message begins with the given string
            if nargin < 3
                fullStr = this.msgIn;
            end
            isBegin = ~isempty(regexp(fullStr, ['^' beginStr], 'once'));
        end
    end
    
end

