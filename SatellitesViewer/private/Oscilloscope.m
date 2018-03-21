function Oscilloscope(obj)
%Oscilloscope Summary of this function goes here
%   Detailed explanation goes here


% Declare runtime variables
numChan = 4;
dur = 3;

% Initialize figure and plots if absent
if any(~isfield(obj.userData, {'svStream', 'figHandle', 'axesHandles', 'plotHandles'})) || ~ishandle(obj.userData.figHandle)
    % Create SerialViewerStream object to facilitate streaming
    obj.userData.svStream = SerialViewerStream();
    
    % Create GUI
    obj.userData.figHandle = figure;
    
    for i = numChan : -1 : 1
        obj.userData.axesHandles(i) = subplot(numChan, 1, i);
        obj.userData.plotHandles(i) = plot(NaN, NaN, 'k');
        set(gca, 'XLim', [-dur, 0], 'YLim', [0, 1023]);
    end
end

% Update plot based on incoming string
if obj.BeginWith('i')
    
    % Split incoming string
    ss = strsplit(obj.msgIn, ',');
    ss = cellfun(@str2double, ss(2:end));
    ss(1) = ss(1) / 1e3;
    obj.userData.svStream.Add(ss);
    
    if mod(obj.userData.svStream.lastElementIdx, 10) == 0
        
        val = obj.userData.svStream.GetLatestByTime(3);
        
        if ~isempty(val)
            
            t = val(:,1);
            val = val(:,2:end);
            
            for i = numChan : -1 : 1
                set(obj.userData.plotHandles(i), 'XData', t, 'YData', val(:,i));
                set(obj.userData.axesHandles(i), 'XLim', [t(end) - dur, t(end)]);
            end
            
        end
    end
    
    obj.isDisplay = false;
end


end





