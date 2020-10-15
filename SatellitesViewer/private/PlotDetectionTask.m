function PlotDetectionTask(obj)
%PlotDetectionTask Summary of this function goes here
%   Detailed explanation goes here

% Initialize figure and plots if absent
if any(~isfield(obj.userData, {'fig', 'axes1', 't0'})) || ~ishandle(obj.userData.fig)
    % Create GUI
    obj.userData.fig = figure;
    obj.userData.fig.Name = obj.channelName;
    
    obj.userData.axes1 = axes();
    obj.userData.axes1.XLim = [0 5];
    hold(obj.userData.axes1, 'on');
    xlabel(obj.userData.axes1, 'time (s)');
    title(obj.userData.axes1, 'Trial 0');
    
    % Runtime variables
    obj.userData.trialNum = 0;
    obj.userData.t0 = 0;
end


% Make shorthand version of variables for clarity
ax1 = obj.userData.axes1;
trialNum = obj.userData.trialNum;
t0 = obj.userData.t0;
isDisp = obj.isDisplay;


% Split incoming string
ss = strsplit(obj.msgIn, ',');
ss(2:end) = cellfun(@str2double, ss(2:end), 'Uni', false);


% Update plot based on incoming string
if obj.BeginWith('lick,')
    % Plot lick
    tLick = ss{2} / 1000 - t0;
    plot(ax1, tLick, 0, 'k*');
    
    if tLick > ax1.XLim(2)
        ax1.XLim(2) = tLick + 5;
    end
    isDisp = false;
    
elseif obj.BeginWith('trial,')
    % Clear plot for a new trial
    cla(ax1);
    ax1.XLim = [0 5];
    t0 = ss{2} / 1000;
    trialNum = ss{3};
    title(ax1, ['Trial ' num2str(trialNum)]);
    
elseif obj.BeginWith('stimulus delivered,')
    % Plot cue
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    plot(ax1, [tOn; tOn+dur], [0; 0], '-m', 'LineWidth', 4);
    
    if tOn+dur > ax1.XLim(2)
        ax1.XLim(2) = tOn + dur + 5;
    end
    
elseif obj.BeginWith('water delivered,')
    % Plot water
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    plot(ax1, [tOn; tOn+dur], [0; 0], '-b', 'LineWidth', 4);
    
    if tOn+dur > ax1.XLim(2)
        ax1.XLim(2) = tOn + dur + 5;
    end
    
elseif obj.BeginWith('detectionTaskEnd,')
    % do nothing
    
end


% Assign shorthand variables back
obj.userData.trialNum = trialNum;
obj.userData.t0 = t0;
obj.isDisplay = isDisp;


end








