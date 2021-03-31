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
    %   ReadMessage         Read the incoming message, which is stored in msgIn
    %   ClearUserData       Clear user data
    %   BeginWith           Test whether or not the incoming message begins with a given substring
    %
    
    properties
        channelName = '';
        msgIn = '';
        msgOut = {};
        isDisplay = true;
        userData;
    end
    
    methods
        function this = UserFuncModel()
            % Constructor of UserFuncData class
            % do nothing
        end
        
        function m = ReadMessage(this)
            % Read the incoming message
            m = this.msgIn;
        end
        
        function SendMessage(this, varargin)
            % Add message(s) to a queue for output
            for i = 1 : numel(varargin)
                m = varargin{i};
                if ischar(m) && ~isempty(m)
                    this.msgOut{end+1,1} = m;
                end
            end
        end
        
        function ClearUserData(this)
            % Set userData variable to empty
            this.msgIn = '';
            this.msgOut = {};
            this.isDisplay = true;
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

