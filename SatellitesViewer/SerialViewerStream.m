classdef SerialViewerStream < handle
    %SERIALVIEWERSTREAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        blockLength;
        updateInterval = inf;
        
        blocks;
        
        lastBlockIdx = 0;
        lastElementIdx = 0;
        lastUpdateTime = 0;
    end
    
    properties(Dependent)
        status;
        lastSample;
    end
    
    methods
        function val = get.status(this)
            % Return a cell array of strings about the current status of the data stream
            
            if isempty(this.blocks)
                val = { ...
                    '#Samples: 0'; ...
                    ['Block length: ' num2str(this.blockLength)]; ...
                    };
            else
                tBegin = this.blocks{1}(1,1);
                tCurrent = this.lastSample(1);
                numSamples = (this.lastBlockIdx-1) * this.blockLength + this.lastElementIdx;
                
                val = { ...
                    ['#Samples: ' num2str(numSamples)]; ...
                    ['Begin time: ' num2str(tBegin)]; ...
                    ['Current time: ' num2str(tCurrent)]; ...
                    ['Span: ' num2str(tCurrent-tBegin)]; ...
                    ['Current block: ' num2str(this.lastBlockIdx)]; ...
                    ['Block length: ' num2str(this.blockLength)]; ...
                    };
            end
        end
        function val = get.lastSample(this)
            % Return the latest sample
            
            if isempty(this.blocks)
                val = [];
            else
                val = this.blocks{this.lastBlockIdx}(this.lastElementIdx,:);
            end
        end
    end
    
    methods
        function this = SerialViewerStream(varargin)
            % Constructor of the SerialViewerStream class
            
            % Handles input parameters
            p = inputParser();
            p.addParameter('blockLength', 1e5, @isscalar);
            p.parse(varargin{:});
            this.blockLength = p.Results.blockLength;
            
            % Initialize parameters
            this.Clear();
        end
        
        function Clear(this)
            % Clear all data and reset the stream
            
            this.blocks = [];
            this.lastBlockIdx = 0;
            this.lastElementIdx = this.blockLength;
            this.lastUpdateTime = 0;
        end
        
        function Save(this)
            % Save SerialViewerStream object
            
            dateTimeStr = datestr(now(), 'yyyymmdd_HHMMSS');
            
            svStream = this;
            
            save([dateTimeStr '_SerialViewerStream'], 'svStream');
        end
        
        
        
        function Add(this, val)
            % Add a sample to the stream
            
            if this.lastElementIdx == this.blockLength
                this.lastBlockIdx = this.lastBlockIdx + 1;
                this.blocks{this.lastBlockIdx,1} = NaN(this.blockLength, length(val));
                this.lastElementIdx = 0;
            end
            
            this.lastElementIdx = this.lastElementIdx + 1;
            this.blocks{this.lastBlockIdx}(this.lastElementIdx,:) = val;
        end
        
        
        
        function val = GetLatestByNumber(this, numSamples)
            % Retrive latest data points from the data stream by sample number
            
            if isempty(this.blocks)
                val = [];
                return;
            end
            
            % Retreive samples from the current block
            idxBlockRead = this.lastBlockIdx;
            numSampleCurrentBlock = min(numSamples, this.lastElementIdx);
            val = this.blocks{idxBlockRead}(this.lastElementIdx-numSampleCurrentBlock+1:this.lastElementIdx,:);
            
            % Retreive samples from previous full blocks
            while numSamples - size(val,1) >= this.blockLength
                idxBlockRead = idxBlockRead - 1;
                val = [this.blocks{idxBlockRead}; val];
            end
            
            % Retreive remaining samples
            numSampleRemain = numSamples - size(val,1);
            if numSampleRemain > 0 && idxBlockRead > 1
                idxBlockRead = idxBlockRead - 1;
                val = [this.blocks{idxBlockRead}(end-numSampleRemain+1:end, :); val];
                numSampleRemain = 0;
            end
            
            % Make up the length of data
            if numSampleRemain > 0
                val = [NaN(numSampleRemain, size(val,2)); val];
            end
        end
        
        function val = GetLatestByTime(this, dur)
            % Retrive latest data points from the data stream by duration
            
            tCurrent = this.lastSample(1);
            
            % Find indices in the current block
            indLastBlock = this.blocks{this.lastBlockIdx}(:,1) > tCurrent-dur;
            val = this.blocks{this.lastBlockIdx}(indLastBlock,:);
            
            % Find indices of full blocks before the current block
            tBlockHeads = cellfun(@(x) x(1,1), this.blocks);
            indFullBlock = find(tCurrent-dur < tBlockHeads(1:end-1));
            val = vertcat(this.blocks{indFullBlock}, val);
            
            % Find indices before the first full block
            if ~isempty(indFullBlock) && indFullBlock(1) > 1
                firstBlockIdx = indFullBlock(1) - 1;
                indFirstBlock = this.blocks{firstBlockIdx}(:,1) > tCurrent-dur;
                val = vertcat(this.blocks{firstBlockIdx}(indFirstBlock,:), val);
            end
            
        end
        
        function val = GetAll(this)
            % Retrieve all data in an array
            
            if isempty(this.blocks)
                val = [];
            else
                val = vertcat(this.blocks{1:this.lastBlockIdx-1}, ...
                    this.blocks{this.lastBlockIdx}(1:this.lastElementIdx,:));
            end
        end
    end
    
end





