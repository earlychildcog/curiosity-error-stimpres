function trialResult = checkEndTrial(xp, trialResult, roiFix, roiTarget, timeStepStart, durMaxStep)
persistent timeTrialStart   % to be kept for duration of a trial, and reset (manually) before each trial
% if already trial aborts
if nargin>1 && trialResult < 0
    return
end
% trial ends by looking away too long
if nargin>2 && roiFix == -6
    trialResult = -6;
    return
end
if isempty(timeTrialStart)
    timeTrialStart = GetSecs;
end

if (GetSecs-timeTrialStart>xp.settings.durMaxTrial) &&...
        (nargin<4 || ~any(roiTarget == roiFix)) &&...
        (nargin<6 || GetSecs - timeStepStart > durMaxStep)
    trialResult = -5;
end