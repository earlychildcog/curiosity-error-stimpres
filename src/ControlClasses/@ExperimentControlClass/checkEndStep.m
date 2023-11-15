function flagResult = checkEndStep(xp,flagResult, timeStepStart, durMax, roiFix, roiTarget)

if GetSecs-timeStepStart>durMax
    if nargin < 5
        flagResult = -4;
    elseif ~any(roiTarget == roiFix)
        flagResult = -4;
    end

end

end