function MoveAndHold(obj)
%TONGUE Summary of this function goes here
%   Detailed explanation goes here


% Initialize figure and plots if absent
if any(~isfield(obj.userData, {'fig', 'axes1', 'axes2', 't0', 'trialNum', 'lickportPos', 'trialOutcome'})) ...
        || ~ishandle(obj.userData.fig)
    % Create GUI
    obj.userData.fig = figure;
    obj.userData.fig.Name = obj.channelName;
    
    obj.userData.axes1 = subplot(2,1,1);
    obj.userData.axes1.XLim = [0 10];
    obj.userData.axes1.YLim = [0 1];
    hold(obj.userData.axes1, 'on');
    
    obj.userData.axes2 = subplot(2,1,2);
    hold(obj.userData.axes2, 'on');
    
    % Runtime variables
    obj.userData.t0 = 0;
    obj.userData.trialNum = [];
    obj.userData.lickportPos = [];
    obj.userData.trialOutcome = [];
end



% Make shorthand version of variables for clarity
ax1 = obj.userData.axes1;
ax2 = obj.userData.axes2;
t0 = obj.userData.t0;
trialNum = obj.userData.trialNum;
lickportPos = obj.userData.lickportPos;
trialOutcome = obj.userData.trialOutcome;
isDisp = obj.isDisplay;



% Split incoming string
ss = strsplit(obj.msgIn, ',');
ss(2:end) = cellfun(@str2double, ss(2:end), 'Uni', false);



% Update plot based on incoming string
if obj.BeginWith('lickOn,')
    % Plot lick
    tLick = ss{2} / 1000 - t0;
    plot(ax1, tLick, 0.5, 'k*');
    
    if tLick > ax1.XLim(2)
        ax1.XLim(2) = ax1.XLim(2) + 10;
    end
    isDisp = false;
    
elseif obj.BeginWith('lickOff,')
    % Supress display
    isDisp = false;
    
elseif obj.BeginWith('sessionStart,')
    % Update trial info
    trialNum = [];
    lickportPos = [];
    trialOutcome = [];
    cla(ax1);
    cla(ax2);
    
elseif obj.BeginWith('trialNum,')
    % Clear plot for a new trial
    cla(ax1);
    ax1.XLim = [0 10];
    t0 = ss{2} / 1000;
    trialNum(end+1) = ss{3};
    trialOutcome(end+1) = NaN;
    
elseif obj.BeginWith('lickport,')
    % Plot lickport movement
    tOn = ss{2} / 1000 - t0;
    line(ax1, [tOn tOn], [0 1], 'Color', [0 .7 0], 'LineWidth', 2);
    
    if tOn > ax1.XLim(2)
        ax1.XLim(2) = ax1.XLim(2) + 10;
    end
    
    % Plot history
    lickportPos(end+1) = ss{3} / 1000;
    
    cla(ax2);
    plot(ax2, trialNum, lickportPos, '.-');
    
    m = trialOutcome == 1;
    plot(ax2, trialNum(m), lickportPos(m), 'b*');
    
    ylim(ax2, [min(lickportPos)-1, max(lickportPos)+1]);
    xlim(ax2, [trialNum(1)-1, trialNum(end)+1]);
    
elseif obj.BeginWith('cue,')
    % Plot cue
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    x = [tOn, tOn+dur, tOn+dur, tOn];
    y = [0, 0, 1, 1];
    patch(ax1, x, y, 'm', 'EdgeColor', 'none');
    
    if tOn+dur > ax1.XLim(2)
        ax1.XLim(2) = ax1.XLim(2) + 10;
    end
    
elseif obj.BeginWith('water,')
    % Plot water
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    x = [tOn, tOn+dur, tOn+dur, tOn];
    y = [0, 0, 1, 1];
    patch(ax1, x, y, [.3 .3 1], 'EdgeColor', 'none');
    
    if tOn+dur > ax1.XLim(2)
        ax1.XLim(2) = ax1.XLim(2) + 10;
    end
    
    % Update trial outcome history
    trialOutcome(end) = 1;
    
    % Plot the latest outcome
    plot(ax2, trialNum(end), lickportPos(end), 'b*');
end



% Assign shorthand variables back
obj.userData.t0 = t0;
obj.userData.trialNum = trialNum;
obj.userData.lickportPos = lickportPos;
obj.userData.trialOutcome = trialOutcome;
obj.isDisplay = isDisp;



end








