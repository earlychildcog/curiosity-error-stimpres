%% Experimental script for the error task of the curiosity longitudinal study
% Presenting objects on cards in a contingent manner
%
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



xp            = ExperimentControlClass; % main experiment structure
eyetrackingOn = true;
eegOn      = true;                   % using EEG?

% checking if debugging (hence no eyetracking/eeg) or not
if ismac        % always use highest debug mode in macos
    debug = 2;
end
if debug > 0
    xp.debug      = true;                   % true keeps keyboard/mouse input, false disables them
end
if debug > 1
    eyetrackingOn = false;
    eegOn      = false;                   % using EEG?
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
if eegOn
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
xp.trial.varInit({'trialtype' 'difficulty' 'trialno' 'objL' 'objR' 'objT'...
    'result' 'delayFirstFixT' 'delayFirstFixB' 'trialID' 'accuracy' 'sideMatch' 'sideChosen' 'keyboardFlip'});
xp.log.init([xp.name xp.session num2str(xp.subject)]);

nameSides      = {'left','right','NA'};

xp.eeg.startrec;


fileRando = sprintf('rand/StimOrder_Subj%03d_Session%d.csv',xp.subject, xp.sessionNo);
opts = detectImportOptions(fileRando);
opts.VariableTypes = strrep(opts.VariableTypes, 'char', 'string');      % load replace char encoding to string encoding for simplicity in the code later
% fileRando = sprintf('rand/StimOrder_00test_ExtraFam.csv');
% fileScaling = 'rand/scaling.csv';
% fileRando = sprintf('rand_stim/StimOrderPilotStim_Subj%03d.csv',xp.subject); %FOR STIM PILOT
tableFam = readtable(fileRando, opts);
% RandomisationTable = RandomisationTable()
tableTest = tableFam(tableFam.TrialType == "Test", 1:5);
tableFam = tableFam(tableFam.TrialType ~= "Test", :);
tableFam.trialID = (1:size(tableFam,1))';
tableFam.playedTimes = zeros(size(tableFam,1),2);
tableFam.playing = zeros(size(tableFam,1),1);
tableFam.Properties.VariableNames(3:5) = ["objL" "objR" "objT"];

% RandomisationTest = readtable(fileScaling);
tableTest.playedTimes = zeros(size(tableTest,1),2);        % will save how many time each row has been played
tableTest.playing = zeros(size(tableTest,1),1);        % will save which row played last
tableTest.trialID = (1:size(tableTest,1))';
tableTest.Properties.VariableNames(3:5) = ["objL" "objR" "objT"];
% randT = rand([size(tableTest,1) 1]) > 0.5;      % to change after
% tableTest.objT(randT) = tableTest.objL(randT);
% tableTest.objT(~randT) = tableTest.objR(~randT);

nameObjFam = arrayfun(@(x)string(x.name), dir("stimuli/images/04-ObjFamMatch/*.png"));
nameObjTest = arrayfun(@(x)string(x.name), dir("stimuli/images/05-ObjTest/*.png"));

levels  = [0 0 1];
success = [0 0 0];
sides = randi(2);

difficulties = ["Easy" "Medium" "Hard" "xHard"];

iFamRepeatTrial = 99;       % just 
iTrial = 0;
nFam = 6;
nTrial = 50+nFam; %size(RandomisationTable, 1); % we may need some better way to end
% nTest = sum(strcmp(RandomisationTable.TrialType, 'Test'));
%% trial loop

while iTrial < nTrial
    %xp.eeg.sync;
    xp.trial.nTrial = nTrial;       % updates in case `nTrial` changes
    iTrial = iTrial + 1;
    flagRepeat = false;
    flagResultBreak = 0;
    if iTrial > 6 && size(xp.trial.flagResult,2) > 3 %need criterion 2 for when skipping a lot of trials e.g. restarting expt
        % check if trial was aborted 4 times in a row
        flagRepeatFam = sum(xp.trial.flagResult(end-3:end) == [-4, -5, -6]',1) == 4;    % TO CHECK
        if size(xp.trial.sideRevealed,2) > 3
            % check if always looking to the same side in the last 4
            % trials when revelaed something
            flagRepeatFam = numel(unique(xp.trial.sideRevealed(end-3:end))) == 1 && sum(xp.trial.flagAccuracy(end-3:end) == 0) >= 2;
            if flagRepeatFam
                sideBiased = xp.trial.sideRevealed(end);
            end
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
        trialtype        = tableFam.TrialType{iTrial};
        idStimInPosition_ = tableFam{iTrial, 3:10};
        idStimInPosition_ = idStimInPosition_(randperm(length(idStimInPosition_)));
        idStimInPosition = splitapply(@find, idStimInPosition_ == nameObjTest, 1:length(idStimInPosition_));
        difficulty       = tableFam.Difficulty{iTrial};
        trialID          = tableFam.trialID(iTrial);
        fprintf('fam-flip trial number %d\n', iTrial)
    elseif iTrial <= nFam
        if iTrial > 3
            sides(end+1) = 3-sides(end); %#ok<AGROW>
        end
        trialtype        = tableFam.TrialType{iTrial};
        if iTrial <= 4
            trialtype = [trialtype 'Chance'];   % if we give a second chance or not ---> we may need to specify more cases when to do that
        end
        tableFam           = selectNextObject(tableFam, "FamEasy");
        idStimInPosition_ = tableFam{tableFam.playing>0,["objL" "objR" "objT"]};
        idStimInPosition_(end) = idStimInPosition_(sides(end));
        idStimInPosition = splitapply(@find, idStimInPosition_ == nameObjFam, 1:length(idStimInPosition_));
        difficulty       = tableFam.Difficulty{tableFam.playing>0};
        trialID          = tableFam.trialID(tableFam.playing>0);
        fprintf('fam-match trial %d number %d\n', iTrial, find(tableFam.playing>0))
    elseif flagRepeatFam
        sides(end+1) = 3-sides(end); %#ok<AGROW>
        % /!\ need a loop run var to run through the fam trials
        trialtype        = tableFam.TrialType{iFamRepeatTrial+2};
        if iFamRepeatTrial <= 2
            trialtype = [trialtype 'Chance'];   % if we give a second chance or not ---> we may need to specify more cases when to do that
        end
        tableFam         = selectNextObject(tableFam, "FamEasy");
        idStimInPosition_ = tableFam{tableFam.playing>0,["objL" "objR" "objT"]};
        idStimInPosition_(3) = idStimInPosition_(sides(end));       % to change
        idStimInPosition = splitapply(@find, idStimInPosition_ == nameObjFam, 1:length(idStimInPosition_));
        difficulty       = tableFam.Difficulty{tableFam.playing>0};
        trialID          = tableFam.trialID(tableFam.playing>0);
        fprintf('fam-match repeat %d trial number %d (anti-bias repeatition)\n', iFamRepeatTrial+2,find(tableFam.playing>0))
        % set the non-biased side match
        isBiased = find(idStimInPosition == idStimInPosition(3),1) == sideBiased;
        if (isBiased && mod(iFamRepeatTrial,2)==1) || (~isBiased && mod(iFamRepeatTrial,2)==0) % we play bias - nonbias - bias - nonbias
            idStimInPosition(1:2) = idStimInPosition(2:-1:1);
            idStimInPosition_(1:2) = idStimInPosition_(2:-1:1);
        end
        sides(end) = find(idStimInPosition(1:end-1) == idStimInPosition(end),1);
    else
        trialtype = 'Test';
        if all(sides(end-2:end) == 1)
            sides(end+1) = 2;                               %#ok<AGROW>
        elseif all(sides(end-2:end) == 2)
            sides(end+1) = 1;                               %#ok<AGROW>
        elseif length(sides) > 9    % this part tries to equalise  the frequency of sides appearing a bit more
            sides(end+1) = 1+(rand() > mean(sides == 2));                        %#ok<AGROW>
        else      
            sides(end+1) = randi(2);                        %#ok<AGROW>
        end
        %get new level, check how good the subject has been in previous trials
        [levels, success]   = getDifficultyLevel(levels, success, length(difficulties));
        difficulty          = difficulties(levels(end));    % we get new difficulty
        tableTest                  = selectNextObject(tableTest, difficulty);
        idStimInPosition_   = tableTest{tableTest.playing>0, ["objL" "objR" "objT"]}; 
        if sides(end) ~= find(idStimInPosition_(1:end-1) == idStimInPosition_(end),1)
            idStimInPosition_([1 2]) = idStimInPosition_([2 1]);
        end
        idStimInPosition    = splitapply(@find, idStimInPosition_ == nameObjTest, 1:length(idStimInPosition_));
        trialID             = tableTest.trialID(tableTest.playing>0);
        fprintf('test trial number %d: difficulty %s, previous successes %d %d %d, previous levels %d %d %d, objects:\n', iTrial, difficulty, success, levels)
        for i=1:length(idStimInPosition_)
            fprintf('%s\n', idStimInPosition_{i});
        end
    end

    % initialise and set
    flagResult = -10;
    xp.trial.varValue.trialtype  = char(trialtype);
    xp.trial.varValue.difficulty = char(difficulty);
    xp.trial.varValue.trialno    = iTrial;
    xp.trial.varValue.trialID    = trialID;
    xp.trial.varValue.objL       = idStimInPosition_{1};
    xp.trial.varValue.objR       = idStimInPosition_{2};
    xp.trial.varValue.objT       = strcat(idStimInPosition_{3:end});    % so that in FamFlip it gathers the rest of the objects
    xp.trial.varValue.result     = flagResult;
    xp.trial.varValue.accuracy   = NaN;
    xp.trial.varValue.sideMatch = nameSides{3-2*strcmp(xp.trial.varValue.objL,xp.trial.varValue.objT) - strcmp(xp.trial.varValue.objR, xp.trial.varValue.objT)};
    xp.trial.varValue.sideChosen = 'NA';
    xp.trial.varValue.delayFirstFixT = NaN;
    xp.trial.varValue.delayFirstFixB = NaN;
    xp.trial.varValue.keyboardFlip       = false;

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
    elseif strcmp(trialtype, 'FamFlip')
        if any(flagResult == [ (-25:-21) 6 ])
            flagRepeat = true;
        end
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
        if startsWith(trialtype, 'Fam') && flagRepeat
            iTrial = iTrial - 1;            % repeat fam trials
            fprintf('repeat fam trial %d again now\n',iTrial)
        else
            nTrial = nTrial + 1;
            tableTest.playedTimes(tableTest.playing>0) = tableTest.playedTimes(tableTest.playing>0) - 0.5;
            fprintf('trial added, total number of trials %d\n',nTrial)
        end
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

% trial
[flagResult, flagAccuracy] = trialrun_main(xp, idStim, trialtype);
xp.trial.flagResult(end+1) = flagResult;
xp.trial.flagAccuracy(end+1) = flagAccuracy;

goodbyeMessage    = 'end:result %d @%.3f';
tTrialEnd = GetSecs;
xp.eyelink.write(goodbyeMessage, flagResult, tTrialEnd);
xp.eeg.eventSave('endT', tTrialEnd);
if ~strcmp(trialtype, 'FamFlip')
    sides      = {'left','right','NA'};
    if flagAccuracy
        flagSideChosen = sides{stimMatch};
    else
        flagSideChosen = sides{~stimMatch};
    end
    xp.trial.varValue.accuracy    = flagAccuracy;
    xp.trial.varValue.sideChosen  = flagSideChosen;
else
    xp.trial.varValue.accuracy    = NaN;
    xp.trial.varValue.sideChosen  = 'NA';
    flagSideChosen = 'NA';
end
xp.eeg.eventSendAll(xp.trial.varValue)
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
    case 'FamMatchChance'
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
    case 'FamMatch'
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