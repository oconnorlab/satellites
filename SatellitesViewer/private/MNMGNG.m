function MNMGNG(obj)
%MANYMNMGNG Summary of this function goes here
%   Detailed explanation goes here


% Initialize figure and plots if absent
if any(~isfield(obj.userData, {'fig', 'axes1', 'axes2', 't0', 'trialNum', 'trialType', 'trialOutcome'})) ...
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
    obj.userData.trialType = {0, 0};
    obj.userData.trialOutcome = [];
end



% Make shorthand version of variables for clarity
ax1 = obj.userData.axes1;
ax2 = obj.userData.axes2;
t0 = obj.userData.t0;
trialNum = obj.userData.trialNum;
trialType = obj.userData.trialType;
trialOutcome = obj.userData.trialOutcome;
isDisp = obj.isDisplay;



% Split incoming string
ss = strsplit(obj.msgIn, ',');
ss(2:end) = cellfun(@str2double, ss(2:end), 'Uni', false);



% Update plot based on incoming string
if obj.BeginWith('lo,')
    % Plot lick
    tLick = ss{2} / 1000 - t0;
    plot(ax1, tLick, 0.5, 'k*');
    
    if tLick > ax1.XLim(2)
        ax1.XLim(2) = ax1.XLim(2) + 10;
    end

    isDisp = false;

elseif obj.BeginWith('lf,')
    % Supress display
    isDisp = false;

elseif obj.BeginWith('sessionStart,')
    % Update trial info
    trialNum = [];
    trialOutcome = [];
    
elseif obj.BeginWith('trialBegin,')
    % Clear plot for a new trial
    cla(ax1);
    ax1.XLim = [0 10];
    t0 = ss{2} / 1000;
    trialNum(end+1) = ss{3};
    
elseif obj.BeginWith('trialType,')
    % Update trial info
    trialType = ss(3:4);
    
elseif obj.BeginWith('cue,')
    % Plot cue
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    x = [tOn, tOn+dur, tOn+dur, tOn];
    y = [0, 0, 1, 1];
    
    if trialType{2} == 0
        c = [1 .3 .3];
    else
        c = [.3 1 .3];
    end
    
    patch(ax1, x, y, c, 'EdgeColor', 'none');
    
    if tOn+dur > ax1.XLim(2)
        ax1.XLim(2) = ax1.XLim(2) + 10;
    end
    
elseif obj.BeginWith('stim,')
    % Plot stimulus
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    x = [tOn, tOn+dur, tOn+dur, tOn];
    y = [0, 0, 1, 1];
    
    if trialType{1} == 2
        c = [.8 .8 .8];     % no stim
    elseif trialType{1} == trialType{2}
        c = [1 .3 .3];      % front vib
    else
        c = [.3 1 .3];      % back vib
    end
    
    patch(ax1, x, y, c, 'EdgeColor', 'none');
    
    if tOn+dur > ax1.XLim(2)
        ax1.XLim(2) = ax1.XLim(2) + 10;
    end

elseif obj.BeginWith('airPuff,')
    % Plot punishment
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    
    x = [tOn, tOn+dur, tOn+dur, tOn];
    y = [0, 0, 1, 1];
    patch(ax1, x, y, [0 0 0], 'EdgeColor', 'none');
    
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
    
elseif obj.BeginWith('result,')
    % Plot punishment
    trialOutcome(end+1) = ss{3};
    
    % Premature, no paw, hit, FA, miss, CR
    cc = {'m*', 'co', 'g*', 'r*', 'ko', 'go'};
    pos = [1, 0, 5, 2, 3, 4];
    
    cla(ax2);
    
    for i = 1 : length(cc)
        r = double(trialOutcome == i-1);
        r(r == 0) = NaN;
        plot(ax2, trialNum, r * pos(i), cc{i});
    end
    ylim(ax2, [0 max(pos)+1]);
    xlim(ax2, [trialNum(1)-1, trialNum(end)+1]);
end



% Assign shorthand variables back
obj.userData.t0 = t0;
obj.userData.trialNum = trialNum;
obj.userData.trialType = trialType;
obj.userData.trialOutcome = trialOutcome;
obj.isDisplay = isDisp;



end








