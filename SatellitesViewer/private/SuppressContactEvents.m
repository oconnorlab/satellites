function SuppressContactEvents(obj)
%MANYMNMGNG Summary of this function goes here
%   Detailed explanation goes here

% Supress display for specific messages
if obj.BeginWith('lo,')
    isDisplay = false;
elseif obj.BeginWith('lf,')
    isDisplay = false;
elseif obj.BeginWith('po,')
    isDisplay = false;
elseif obj.BeginWith('pf,')
    isDisplay = false;
else
    isDisplay = true;
end

% Assign variables
obj.isDisplay = isDisplay;


end




