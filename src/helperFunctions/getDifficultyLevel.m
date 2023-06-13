function [levels, success] = getDifficultyLevel(levels, success, levelMax)
% function to choose the difficulty level
% current: 3 difficulty levels, goes up (down) with 2 consecutive successes (failure) within a difficulty level
% input:
%       levels: 1 X 3 array, the levels of 3 last trials (update last entry)
%       success: 1 X 3 array, the success result of 3 last trials: -1 fail, 0 n/a, 1 pass (update last entry)
%       levelMax: max difficulty level, current 3
consecTrialsToChange = 2;
% check if we increase/decrease difficulty
if all(success((end-consecTrialsToChange+1):end) == 1) && levels(end) < levelMax
    levelChange = 1;
    % reset success variable when changing difficulty
    success(:)  = 0;
elseif all(success((end-consecTrialsToChange+1):end) == -1) && levels(end) > 1
    levelChange = -1;
    % reset success variable when changing difficulty
    success(:) = 0;
else
    levelChange = 0;
    % update success variable
    success(1:end-1) = success(2:end);
    success(end) = 0;
end
% update levels
levelNew = levels(end) + levelChange;
levels(1:end-1) = levels(2:end);
levels(end) = levelNew;



%fprintf('old success %d %d %d, old leve')





end