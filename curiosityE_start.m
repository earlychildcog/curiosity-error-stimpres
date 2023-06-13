%% Experimental script for the error task of the curiosity longitudinal study
% Presenting objects on cards in a contingent manner
%
% NB: Make sure that development variables are re-sat to proper testing
%     values before starting to test with a participant:
%   - eyetrackingOn = true
%   - eegOn = true
%   - xp.debug = false
%


function curiosityE_start(debug)
% debugging keep accepting keyboard/mouse input, else they are disabled
% debug: 0: -debug, 1: +debug +eyetracking +eeg, 2: +debug -eyetracking -eeg
arguments
    debug uint8 {mustBeMember(debug, [0 1 2])} = 0
end
% make sure in case of error that cursor and keyboard are reactivated
try
    addpath(genpath('src'))
    syssetMonitor("eyelink")        % set the intended primary monitor and resolution
    syssetWifi("off")               % turns wifi off
    start_main(debug)                      %run the experiment script
    syssetWifi("on")               % turns wifi on again
    rmpath(genpath('src'))
catch my_error
    ListenChar(0);                  %reactivate keyboard
    ShowCursor();                   %show cursor again
    Screen('CloseAll');             %Close screen window, in case it had opened
    PsychPortAudio('Close');        % turn off sound
    try
        Eyelink('Shutdown');        %close eyetracker
    catch
        warning('Eyelink not connected or not shutting down properly')
    end
    clear ExperimentControlClass
    syssetWifi("on")               % turns wifi on again
    rmpath(genpath('src'))
    rethrow(my_error);              %show what happened in case of an error
end
end


function start_main(debug)

%% settings
if ismac
    debug = 2;
end
xp            = ExperimentControlClass; % main experiment structure

% checking if debugging (hence no eyetracking/eeg) or not
xp.debug      = false;
eyetrackingOn = true;
xp.eegon      = true;                   % using EEG?
if debug > 0
    xp.debug      = true;                   % true keeps keyboard/mouse input, false disables them
end
if debug > 1
    eyetrackingOn = false;
    xp.eegon      = false;                   % using EEG?
end

if ismac
    xp.screen.nr  = min(Screen('Screens'));
else
    xp.screen.nr  = max(Screen('Screens'));
end

xp.getExpName;                          % prompt for experiment name
xp.setSubjNo;                           % prompt for subject/session numbers
xp.init;
xp.trial.videoList = arrayfun(@(x)string(fullfile(x.folder, x.name)), dir('stimuli/videos/03-break/*.mp4'));

xp.settings.durToHighlight      = 0.2;
xp.settings.durMinToFlip        = 0.3;  % time to flip after highlighting
xp.settings.durMaxTrial         = 60;
xp.settings.durMaxLookAway      = 10;

xp.settings.timeOut             = 0.1;   % time fixating away to reset fixation timer
xp.settings.timeOutOfScreenMax  = 5;
if xp.eegon
    xp.eeg.init;
end

% <-:      fake fixation to left ROI
% ->:      fake fixation to right ROI
% ^:       fake fixation to middle ROI
% SPACE:   move to next trial
% Escape:  exit animation loop
% c:       recalibrate
% s:       sound (only works during fixation cross)
% q:       quit experiment (only works during fixation cross)
% b:       take a break (with video)

xp.keyboard.keyStrings = {'q' 'leftarrow' 'rightarrow' 'uparrow' 'space' 'escape' 'c' 's' 'p'};
xp.keyboard.init;

yFull = 1024;
xFull = 1280;

xBuff = 0;
yBuff = 100;
xRduc = xFull - xBuff;
yRduc = yFull - yBuff;

W = 1280;
H = 1024;
YB0 = 51/50;
YT0 = -1/50;
YB = 7.5/10;
YT = 2.5/10;
CardRadius = 1/6;
ObjRadius  = 1/8;
xp.settings.rectCard = round([0 1 0 1]'*CardRadius); % [20 100 -40 0]';
xp.settings.rectObj  = round([0 1 0 1]'*ObjRadius);  % [20 100 -40 0]';
FamPos1 = 0.8/4;
FamPos2 = 1/2;
FamPos3 = 3.2/4;

% Positions in array: [LB RB MT]
rectCard  = round(repmat([1/4 YB; 3/4 YB; 1/2 YT]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(CardRadius));        %regular positions of cards (LB, RB, T)
rectObj   = round(repmat([1/4 YB; 3/4 YB; 1/2 YT]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(ObjRadius));
rectCard0 = round(repmat([-1/50 YB0; 51/50 YB0; 1/2 YT0]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(CardRadius)); %position outside of the screen from which cards fly in (LB, RB, T)
rectObj0  = round(repmat([-1/50 YB0; 51/50 YB0; 1/2 YT0]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(ObjRadius));
rectCard1 = round(repmat([1/4 YT; 3/4 YT]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(CardRadius));                %position of cards when they move up (L, R)
rectObj1  = round(repmat([1/4 YT; 3/4 YT]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(ObjRadius));
rectCard2 = round(repmat([5/4 YB; 5/4 YT]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(CardRadius));                %position outside of the screen to which cards fly out (B, T)
rectObj2  = round(repmat([5/4 YB; 5/4 YT]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(ObjRadius));

% FAMFLIP - positions in array: [T row: L, M, R; M row; B row]
% NB: took out central card (FamPos2 FamPos2, had to keep it at the end of
% the array but is skipped by 
rectCardFam = round(repmat([FamPos1 FamPos1; FamPos2 FamPos1; FamPos3 FamPos1;...
    FamPos1 FamPos2; FamPos3 FamPos2;...
    FamPos1 FamPos3; FamPos2 FamPos3; FamPos3 FamPos3]',...
    2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(CardRadius));                                                        %positions in fam flip trial (9 cards) -- took out FamPos2 FamPos2
rectObjFam  = round(repmat([FamPos1 FamPos1; FamPos2 FamPos1; FamPos3 FamPos1;...
    FamPos1 FamPos2; FamPos3 FamPos2;...
    FamPos1 FamPos3; FamPos2 FamPos3; FamPos3 FamPos3]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(ObjRadius));

% fixation cross
rectCentreSmall = round([W/2 H/2 W/2 H/2]' + [-1 -1 1 1]'*H/20);
rectCentreBig   = round([W/2 H/2 W/2 H/2]' + [-1 -1 1 1]'*H/8);

xp.screen.rect  = [[0 0 W H]' rectCard rectObj rectCard0 rectObj0 rectCard1 rectObj1 rectCard2 rectObj2 rectCardFam rectObjFam rectCentreSmall rectCentreBig];

xp.image.load                           % load images from stimuli/images folder
xp.sound.load


%% Play video at start + calibrate & then start EEG
Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
xp.flip;
xp.waitSpace;
% xp.sound.which = xp.sound.data{3,2}; %Mozart mushroom sound
% result = videoPlay(xp, fullfile(pwd, 'stimuli/videos/03-break/mushrooms.avi'), 1, 1);
WaitSecs(0.2);
xp.sound.which = xp.sound.data{3,5};
videoPlay(xp, fullfile(pwd, 'stimuli/videos/03-break/waybuloo.mp4'), 1, 1);

if eyetrackingOn
    xp.eyelink.calib_pahandle = xp.sound.pahandle;
    xp.eyelink.init                     % initialise eyelink
    xp.eyelink.calibrate                % calibrate eyetracker
    WaitSecs(0.1)
end



%% trial preparation
xp.trial.varInit({'trialtype' 'difficulty' 'trialno' 'objL' 'objR' 'objT' 'result' 'durFixFirst' 'trialID' 'accuracy' 'chosenSide'});
xp.log.init([xp.name xp.session num2str(xp.subject)]);


xp.eeg.startrec;

fileRando = sprintf('rand/StimOrder_00test_ExtraFam.csv');
fileScaling = 'rand/scaling.csv';
% fileRando = sprintf('rand_stim/StimOrderPilotStim_Subj%03d.csv',xp.subject); %FOR STIM PILOT
RandomisationTable = readtable(fileRando);
RandomisationTable.trialID = (1:size(RandomisationTable,1))';

tableScaling = readtable(fileScaling);
tableScaling.playedTimes = zeros(size(tableScaling,1),1);        % will save how many time each row has been played
tableScaling.playedLast = false(size(tableScaling,1),1);        % will save which row played last
tableScaling.trialID = (1:size(tableScaling,1))';
levels  = [0 0 1];
success = [0 0 0];
difficulties = {'Easy' 'Medium' 'Hard'};
% nTrial = size(RandomisationTable, 1);
% fam-colour, visible, invisible
% names = {'fam1' 'fam2' 'TestVis' 'TestInvis'};
iFamRepeatTrial = 99;
iTrial = 0;
nTrial = 40; %size(RandomisationTable, 1); % we may need some better way to end
nFam = sum(~strcmp(RandomisationTable.TrialType, 'Test'));
% nTest = sum(strcmp(RandomisationTable.TrialType, 'Test'));
%% trial loop

while iTrial < nTrial
    %xp.eeg.sync;
    xp.trial.nTrial = nTrial;
    iTrial = iTrial + 1;
    flagRepeat = false;
    flagResultBreak = 0;
    if iTrial > 6 && size(xp.trial.flagResult,2) > 3 %need criterion 2 for when skipping a lot of trials e.g. restarting expt
        % check if trial was aborted 4 times in a row
        flagFamRepeat = sum(xp.trial.flagResult(end-3:end) == [-4, -5, -6]',1) == 4;
        if size(xp.trial.sideRevealed,2) > 3
            % check if always looking to the same side in the last 4
            % trials when revelaed something
            flagRepeatFam = numel(unique(xp.trial.sideRevealed(end-3:end))) == 1;
        else
            flagRepeatFam = false;
        end
    else
        flagRepeatFam = false;
    end

    %Enter the fam repeat loop -- initialise tr #
    if flagRepeatFam && iFamRepeatTrial == 99
        iFamRepeatTrial = 1;
        %Exit the fam repeat loop when 4 trials have been done
    elseif iFamRepeatTrial == 4
        iFamRepeatTrial = 99;
        flagRepeatFam   = false;
        %Increment the fam repeat loop until 4 trials have been done (always doing all 4)
    elseif iFamRepeatTrial < 4
        iFamRepeatTrial = iFamRepeatTrial +1;
    end

    % flagResult:
    %   -9: quit
    %   -6: aborted by looking away
    %   -5: aborted by max trial durationaway
    %   -4: aborted by not flipping
    %   -3: skipped trial
    %   -2: pause/video
    %   -1: recalibrate
    %    0: nothing
    %    6: ended trial, repeating it because not enough cards were flipped (FamFlip trials only)


    if iTrial <= 2
        trialtype        = RandomisationTable.TrialType{iTrial};
        idStimInPosition = [4,6,13,17,25,29,37,41,49];
        difficulty       = RandomisationTable.Difficulty{iTrial};
        trialID          = RandomisationTable.trialID(iTrial);
        fprintf('fam-flip trial id %d\n', iTrial)
    elseif iTrial <= nFam
        trialtype        = RandomisationTable.TrialType{iTrial};
        idStimInPosition = RandomisationTable{iTrial,{'objL' 'objR' 'objT'}};
        difficulty       = RandomisationTable.Difficulty{iTrial};
        trialID          = RandomisationTable.trialID(iTrial);
        fprintf('fam-match trial id %d\n', iTrial)
    elseif flagRepeatFam
        % /!\ need a loop run var to run through the fam trials
        trialtype        = RandomisationTable.TrialType{iFamRepeatTrial+2};
        idStimInPosition = RandomisationTable{iFamRepeatTrial+2,{'objL' 'objR' 'objT'}};
        difficulty       = RandomisationTable.Difficulty{iFamRepeatTrial+2};
        trialID          = RandomisationTable.trialID(iFamRepeatTrial+2);
        fprintf('fam-match trial id %d\n', iFamRepeatTrial+2)
    else
        trialtype = 'Test';
        %get new level, check how good the subject has been in previous trials
        [levels, success] = getDifficultyLevel(levels, success, length(difficulties));
        difficulty        = difficulties{levels(end)};    % we get new difficulty
        tableScaling      = getScaledObjects(tableScaling, difficulty);
        idStimInPosition_ = tableScaling{tableScaling.playedLast, {'objL' 'objR' 'objT'}};
        idStimInPosition  = cellfun(@(x)str2num(x(1:2)), idStimInPosition_); %#ok<ST2NM>
        trialID           = tableScaling.trialID(tableScaling.playedLast);
        fprintf('test trial id %d: difficulty %s, previous successes %d %d %d, previous levels %d %d %d, objects:\n', trialID, difficulty, success, levels)
        for i=1:length(idStimInPosition_)
            fprintf('%s\n', idStimInPosition_{i});
        end
    end

    % initialise and set
    flagResult = -10;
    xp.trial.varValue.trialtype  = trialtype;
    xp.trial.varValue.difficulty = difficulty;
    xp.trial.varValue.trialno    = iTrial;
    xp.trial.varValue.trialID    = trialID;
    xp.trial.varValue.objL       = num2str(idStimInPosition(1));
    xp.trial.varValue.objR       = num2str(idStimInPosition(2));
    xp.trial.varValue.objT       = num2str(idStimInPosition(3));
    xp.trial.varValue.result     = flagResult;
    xp.trial.varValue.accuracy   = NaN;
    xp.trial.varValue.chosenSide = 'NA';

    % attention getter part
    flagResultAttget = xp.attgetPart;
    % set repeat conditions for attention getter results
    if flagResultAttget < 0 && strcmp(trialtype, 'Test')
        flagRepeat = true;                     %repeat trial at the end
    elseif any(flagResultAttget == [-1 -2]) && ~strcmp(trialtype, 'Test')
        flagRepeat = true;
    end
    while flagResultAttget == 1
        flagResultAttget = 0;
        flagResult = trialrun(xp, idStimInPosition, trialtype);
        xp.trial.varValue.result = flagResult;
        xp.eyelink.stoprec
        % if break, replay now
        if flagResult < -20
            idBreak = -flagResult-20;
            xp.sound.which = xp.sound.data{3,idBreak};
            flagResultBreak = xp.videoPlay(xp.trial.videoList(idBreak), 1, 1);
            if flagResultBreak == -1
                xp.eyelink.calibrate;
            elseif flagResultBreak == -9
                break
            end
            flagResultAttget = xp.attgetPart;
        end
    end
    % set repeat trial flag (push a new trial at the end)
    if any(flagResult == [ (-25:-21) -6 -5 -4 -3  -1 ]) && strcmp(trialtype, 'Test')
        flagRepeat = true;
    elseif any(flagResult == [ (-25:-21) -6 -5 -4 -1 6 ]) && ~strcmp(trialtype, 'Test')
        flagRepeat = true;
    end

    % if not correct/incorrect (eg skipped trial) to not update the success variable, so last entry is going to remain 0
    if strcmp(trialtype, 'Test')
        if xp.trial.varValue.accuracy == 1 && flagResult >= 0
            success(end) = 1;
        elseif xp.trial.varValue.accuracy == 0 && flagResult >= 0
            success(end) = -1;
        end
    end

    % repeat trial, test
    if flagRepeat || flagRepeatFam
        % if strcmp(trialtype, 'Test')
            nTrial = nTrial + 1;
            tableScaling.playedTimes(tableScaling.playedLast) = tableScaling.playedTimes(tableScaling.playedLast) - 0.5;
            fprintf('trial added, total number of trials %d\n',nTrial)
        % else
        %     iTrial = iTrial - 1;            % repeat fam trials
        %     fprintf('repeat fam trial %d\n',iTrial)
        % end
    end
    if flagResult == -1
        xp.eyelink.calibrate;
    elseif flagResult == -9 || flagResultAttget == -9 || flagResultBreak == -9
        break
    end
end

%%

xp.eeg.stoprec;
xp.eeg.disconnect;
% play video in the end of experiment
WaitSecs(0.2);
xp.sound.which = xp.sound.data{4,1};
videoPlay(xp, fullfile(pwd, 'stimuli/videos/04-end/ClappingEndExpt.mp4'), 1, 1, 0);

xp.finish
%%
end

function flagResult = trialrun(xp, idStim, trialtype)
% initialise
flagResult = 0;

% reset persistent variables in functions
resetFunctions;

if length(idStim) == 3
    stimMatch = idStim(1:end-1) == idStim(end);
end

% event start
xp.eeg.eventSave('strt', GetSecs);
xp.eyelink.write('trial %d starts', xp.trial.varValue.trialID)

% trial
[flagResult, flagAccuracy] = trialrun_main(xp, idStim, trialtype);
xp.trial.flagResult(end+1) = flagResult;

goodbyeMessage    = 'end:result %d @%.3f';
tTrialEnd = GetSecs;
xp.eyelink.write(goodbyeMessage, flagResult, tTrialEnd);
xp.eeg.eventSave('endT', tTrialEnd);
if ~strcmp(trialtype, 'FamFlip')
    sides      = {'left','right'};
    if flagAccuracy
        flagChosenSide = sides{stimMatch};
    else
        flagChosenSide = sides{~stimMatch};
    end
    xp.trial.varValue.accuracy    = flagAccuracy;
    xp.trial.varValue.chosenSide  = flagChosenSide;
    %     xp.trial.varValue.durFixFirst = countFirstROI;
    xp.trial.varValue.durFixFirst = NaN;
else
    xp.trial.varValue.accuracy    = NaN;
    xp.trial.varValue.chosenSide  = 'NA';
    xp.trial.varValue.durFixFirst = NaN;
    flagChosenSide = 'NA';
end
xp.eeg.eventSend('type', xp.trial.varValue.trialtype, 'trial', xp.trial.varValue.trialno, 'diff', xp.trial.varValue.difficulty, 'result', flagResult, 'accuracy', flagAccuracy, 'chosenSide', flagChosenSide, 'objL', xp.trial.varValue.objL, 'objR', xp.trial.varValue.objR, 'objT', xp.trial.varValue.objT);
xp.log.write();
%fprintf([goodbyeMessage '\n'], flagResult, tTrialEnd)
xp.erase();
end


function [flagResult, flagAccuracy] = trialrun_main(xp, idStim, trialtype)
% initialise output
flagResult   = 0;
flagAccuracy = 0;
% stim
nStimOnScreen             = length(idStim);
xp.settings.idStim        = idStim;
xp.settings.nStimOnScreen = nStimOnScreen;
% rects
xp.settings.rectCards     = xp.screen.rect(:, 1 + (1:nStimOnScreen));
xp.settings.padding       = xp.screen.rect(:,5)-xp.screen.rect(:,2);
% states
cardsPos     = [1 1 2];
stateCards   = [0 0 2];
switch trialtype
    case 'FamFlip'
        flagResult = xp.stepFam9cards;
        if flagResult<0, return, end
    case 'FamMatch1'
        flagResult = xp.stepFlyIn; %#ok<*NASGU>
        if flagResult<0, return, end
        flagResult = xp.stepTrackTop;
        if flagResult<0, return, end
        [flagResult, stateCards, flagAccuracy] = xp.stepTrackBottomAndTiltTop(stateCards); %#ok<*ASGLU>
        if flagResult<0, return, end
        if ~flagAccuracy
            [flagResult, stateCards] = stepMoveUpDown(xp, stateCards);
            if flagResult<0, return, end
            [flagResult, stateCards, flagAccuracy] = xp.stepTrackBottomAndTiltTop(stateCards);
            if flagResult<0, return, end
        end
        [flagResult, stateCards, cardsPos] = xp.stepMoveMatchUp(stateCards);
        if flagResult<0, return, end
        flagResult = xp.stepFeedback(flagAccuracy, stateCards, cardsPos);
        if flagResult<0, return, end
        if flagAccuracy
            flagResult = xp.stepFlyOut(flagAccuracy, stateCards, cardsPos);
            if flagResult<0, return, end
        end
    case 'FamMatch2'
        flagResult = xp.stepFlyIn;
        if flagResult<0, return, end
        flagResult = xp.stepTrackTop;
        if flagResult<0, return, end
        [flagResult, stateCards, flagAccuracy] = xp.stepTrackBottom(trialtype);
        if flagResult<0, return, end
        [flagResult, stateCards, cardsPos] = xp.stepMoveMatchUp(stateCards);
        if flagResult<0, return, end
        flagResult = xp.stepFeedback(flagAccuracy, stateCards, cardsPos);
        if flagResult<0, return, end
        if flagAccuracy
            flagResult = xp.stepFlyOut(flagAccuracy, stateCards, cardsPos);
            if flagResult<0, return, end
        end
    case 'Test'
        flagResult = xp.stepFlyIn;
        if flagResult<0, return, end
        flagResult = xp.stepTrackTop;
        if flagResult<0, return, end
        [flagResult, stateCards, flagAccuracy] = xp.stepTrackBottom(trialtype);
        if flagResult<0, return, end
        if flagAccuracy
            [flagResult, stateCards, cardsPos] = xp.stepMoveMatchUp(stateCards);
            if flagResult<0, return, end
        end
        flagResult = xp.stepFeedback(flagAccuracy, stateCards, cardsPos);
        if flagResult<0, return, end
        if flagAccuracy
            flagResult = xp.stepFlyOut(flagAccuracy, stateCards, cardsPos);
            if flagResult<0, return, end
        end
end

end

function resetFunctions
clear checkEndTrial checkFix checkROI
end