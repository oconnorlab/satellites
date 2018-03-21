function isDisplay = DiscrimGNG(msg, funcData)
%MANYMNMGNG Summary of this function goes here
%   Detailed explanation goes here

% Default output
isDisplay = true;


% Declare persistent (static) variables
persistent figHandle axes1 axes2 t0 xLims;
persistent trialNum trialType trialOutcome;



% Initialize figure and plots if absent
if isempty(figHandle) || ~ishandle(figHandle)
    figHandle = 466;
    figure(figHandle);
    axes1 = subplot(2,1,1);
    hold(axes1, 'on');
    
    t0 = 0;
    xLims = [0 10];
    xlim(axes1, xLims);
    ylim(axes1, [0 1]);
    
    axes2 = subplot(2,1,2);
    hold(axes2, 'on');
    
    trialNum = [];
    trialType = {0, 0};
    trialOutcome = [];
end



% Split incoming string
ss = strsplit(msg, ',');
ss(2:end) = cellfun(@str2double, ss(2:end), 'Uni', false);



% Update plot based on incoming string
if regexp(msg, GetPattern('lo'))
    % Plot lick
    tLick = ss{2} / 1000 - t0;
    plot(axes1, tLick, 0.5, 'k*');
    
    if tLick > xLims(2)
        xLims(2) = xLims(2) + 10;
    end
    xlim(axes1, xLims);

    isDisplay = false;

elseif regexp(msg, GetPattern('lf'))
    % Supress display
    isDisplay = false;

elseif regexp(msg, GetPattern('sessionStart'))
    % Update trial info
    trialNum = [];
    trialOutcome = [];
    
elseif regexp(msg, GetPattern('trialBegin'))
    % Update trial info
    trialNum(end+1) = ss{3};
    
elseif regexp(msg, GetPattern('trialType'))
    % Update trial info
    trialType = ss(3:4);
    
elseif regexp(msg, GetPattern('nolickITI'))
    % Clear plot for a new trial
    cla(axes1);
    xLims = [0 10];
    xlim(axes1, xLims);
    t0 = ss{2} / 1000;

elseif regexp(msg, GetPattern('stim'))
    % Plot stimulus
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    x = [tOn, tOn+dur, tOn+dur, tOn];
    y = [0, 0, 1, 1];
    
    switch trialType{1}
        case 0
            c = [1 .3 .3];      % up sweep
        case 1
            c = [.3 1 .3];      % down sweep
        case 2
            c = [1 .3 .3];      % front vib
        case 3
            c = [.3 1 .3];      % back vib
        otherwise
            c = [.8 .8 .8];     % no stim
    end
    
    patch(axes1, x, y, c, 'EdgeColor', 'none');
    
    if tOn+dur > xLims(2)
        xLims(2) = xLims(2) + 10;
    end
    xlim(axes1, xLims);

elseif regexp(msg, GetPattern('shake'))
    % Plot punishment
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    
    x = [tOn, tOn+dur, tOn+dur, tOn];
    y = [0, 0, 1, 1];
    patch(axes1, x, y, [0 0 0], 'EdgeColor', 'none');
    
    if tOn+dur > xLims(2)
        xLims(2) = xLims(2) + 10;
    end
    xlim(axes1, xLims);
    
elseif regexp(msg, GetPattern('water'))
    % Plot water
    tOn = ss{2} / 1000 - t0;
    dur = ss{3} / 1000;
    x = [tOn, tOn+dur, tOn+dur, tOn];
    y = [0, 0, 1, 1];
    patch(axes1, x, y, [.3 .3 1], 'EdgeColor', 'none');
    
    if tOn+dur > xLims(2)
        xLims(2) = xLims(2) + 10;
    end
    xlim(axes1, xLims);
    
elseif regexp(msg, GetPattern('result'))
    % Plot punishment
    trialOutcome(end+1) = ss{3};
    
    % Premature, no paw, hit, FA, miss, CR
    cc = {'m*', 'co', 'g*', 'r*', 'ko', 'go'};
    pos = [1, 0, 5, 2, 3, 4];
    
    cla(axes2);
    
    for i = 1 : length(cc)
        r = double(trialOutcome == i-1);
        r(r == 0) = NaN;
        plot(axes2, trialNum, r * pos(i), cc{i});
    end
    ylim(axes2, [0 max(pos)+1]);
    xlim(axes2, [trialNum(1)-1, trialNum(end)+1]);
end


end



function re = GetPattern(tag)
    re = ['^' tag ','];
end









