function SuppressBlinkEvents(obj)
%SuppressBlinkEvents Summary of this function goes here
%   Detailed explanation goes here

if obj.BeginWith('ledOff,')
    obj.isDisplay = false;
end

end




