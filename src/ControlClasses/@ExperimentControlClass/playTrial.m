function flagResult = playTrial(xp, idStimInPosition, trialtype)
%% types of trials
durTrialMax          = 45;
timeOutOfScreenMax   = xp.settings.timeOutOfScreenMax;
countFirstROI        = 0;
xp.eeg.eventReset;
flagEndIfLookAway    = true;
flagFlipAllCards     = false; % not representative? Call it 'FamTrial'?
cardPos              = {'left','right','top'};
switch trialtype
    % ------ 1. For the real task/the task pilot
    case 'FamFlip'
        cardPos              = {'Tleft','Tmiddle','Tright','Mleft','Mmiddle','Mright','Bleft','Bmiddle','Bright'};
        flagEndIfLookAway    = false;
        flagFlipAllCards     = true;
        idStim               = [4,6,13,17,25,29,37,41,49];
%         idStim               = idStim(randperm(size(idStim,2)));   % QUICK FIX - NEED TO SAVE THIS SOMEWHERE IN THE SUBJ StimOrder FILE
        nStimOnScreen        = length(idStim);                     % how many on screen (experiment phase)
        %         durTrialMax          = Inf;                      % No dur max for FamFlip trials (SHOULD WE put a really long length of several minutes?)
    case 'FamMatch' % change to FamMatch1 + change the stimorder file
        flagEndIfLookAway    = false;
        flagFlipAllCards     = true;
        idStim               = idStimInPosition;
        idStimMatch          = idStimInPosition(end);
        nStimOnScreen        = length(idStim);                     % how many on screen (experiment phase)
        positionStimMatch    = find(idStimInPosition(1:nStimOnScreen-1)==idStimMatch);% 1: correct = L; 2: correct = R
    case 'Fam'      % change to FamMatch2 + change the stimorder file
        flagFlipAllCards     = true;
        idStim               = idStimInPosition;
        idStimMatch          = idStimInPosition(end);
        nStimOnScreen        = length(idStim);                     % how many on screen (experiment phase)
        positionStimMatch    = find(idStimInPosition(1:nStimOnScreen-1)==idStimMatch);% 1: correct = L; 2: correct = R
    case 'Test'
        idStim               = idStimInPosition;
        idStimMatch          = idStimInPosition(end);
        nStimOnScreen        = length(idStim);                     % how many on screen (experiment phase)
        positionStimMatch    = find(idStimInPosition(1:nStimOnScreen-1)==idStimMatch);% 1: correct = L; 2: correct = R
    otherwise
        error('wrong trialtype')
end

%% object settings
timeToTrigger1   = xp.settings.timeToTrigger;    % time for fixation to trigger, when card is closed
xp.settings.durToTrigger = timeToTrigger1;
timeMinVisible   = 2;                            % time to ensure bottom cards are seen before top can be flipped
timeToTriggerFam = timeToTrigger1;               % time for fixation to trigger, when card is highlighted
timeOut          = xp.settings.timeOut;          % time fixating away to reset fixation timer

if ~strcmp(trialtype,'FamFlip')
    roiTop           = nStimOnScreen;
    roiReward        = positionStimMatch;
end

xp.settings.rectCards     = xp.screen.rect(:, 1 + (1:nStimOnScreen));
xp.settings.padding       = xp.screen.rect(:,5)-xp.screen.rect(:,2);

xp.settings.idStim        = idStim;
xp.settings.nStimOnScreen = nStimOnScreen;


%% timing movement settings
% HFR = 0; % 1/(2*Screen('FrameRate'));
cardsPos        = [1,1,2];    % 1 = B (bottom); 2 = T (top)
% ---- Setting movement variables
durMove         = 1;          % in s
timeStep        = 1/30;       % warning: make sure that durMove/timeStep is an integer! Best way to ensure that is to set timeStep as durMove/n for some n integer
% For flying in
kStep           = timeStep/durMove;
K               = 0:kStep:1;
iFrameMovement  = 0;
k               = -1;
% For moving match card up
kStep2          = timeStep/durMove;
K2              = 0:kStep2:1;
iFrameMovement2 = 0;
% For tilting and kissing; consists of 3 parts/phases: tilting in, staying, tilting back
angleStart      = 0;
angleEnd        = 20;
durAngleParts   = [0.5 0.25 0.5];
kStepAngle      = timeStep./durAngleParts;
KAngle          = [0:kStepAngle(1):1, ones(1,round(1./kStepAngle(2))), 1:-kStepAngle(3):0];
KAngle2         = [0:kStepAngle(1):1, 1:-kStepAngle(3):-1, -1:kStepAngle(1):0];
% For fading out
alphaStart      = 1;
alphaEnd        = 0;
durAlpha        = 2;
kStepAlpha      = timeStep/durAlpha;
KAlpha          = 0:kStepAlpha:1;

%% other settings
goodbyeMessage    = 'end:-';
key               = xp.keyboard.key;

%% Initialise experimental variables
% Initialise flags
flagResult        = 1;       % if keys are pressed
flagEndTrial      = 0;
flagLoop          = true;    % should the trial keep going (or be terminated)?
flagTrialStep     = 'start';
flagAccuracy      = 'NA';
flagChosenSide    = 'NA';
flagFlippedBottomChosen = 0;
flagFlippedBottomOther  = 0;
flagMoveUpDone    = 0;
flagCardHighlight = 0;
flagChance        = 2;
flagCardFlipped   = zeros(1, nStimOnScreen);   % states: 0 = face down; 1 = face up
stateCards        = [0,0,0]; % start with all face down; 0 = face down; 1 = highlighted; 2 = face up; 3 = face up + highlighted (FamMatch1)
flippedCards      = [0,0,0,0,0,0,0,0,0];
roiFixLast        = 0;
durFixIn          = 0;

% Initialise timing variables
timeLastSound        = GetSecs;
timeLastIn           = repmat(GetSecs, 1, nStimOnScreen+1);     % timestamp of last visit of ROI (starting with rest of screen roi)
timeOutOfScreenStart = GetSecs;
timeFirstIn          = GetSecs;


%% loop
while flagLoop

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start new trial settings
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% cards fly in, face down
    switch flagTrialStep
        case 'start' %

            % Write triggers to EEG + eyetracker, set up cards vars
            if iFrameMovement == 0
                tTrialStart  = GetSecs;
                xp.eyelink.write('trial start @%.3fsec',tTrialStart)
                xp.eeg.eventSave('strt' ,tTrialStart)            % start
            end

            % Stop sound that may be playing, and play new sound
            if k == -1
                xp.sound.stop;
                xp.sound.which = xp.sound.data{2,2}; %whoop in
                xp.sound.play;
            end

            % If fam flip type of trial, go to this trial type
            if strcmp(trialtype, 'FamFlip')
                flagTrialStep  = 'Fam F';
                stateCards     = [0 0 0 0 0 0 0 0 0];            % 9 cards
                tTurnUp        = 0; %initialise
                DrawAllCards(xp, stateCards);
                stimOnset      = xp.flip;

            else % Else, make cards fly in with a sound
                % Draw cards -- they fly in from out of the screen
                stateCards     = [2 2 0];                        % 3 cards
                iFrameMovement = iFrameMovement + 1;
                k              = K(iFrameMovement);
                rectTraject    = round(xp.screen.rect(:, 1 + 2*nStimOnScreen + (1:nStimOnScreen)) * (1-k) + k * [xp.screen.rect(:,1 + (1:nStimOnScreen))]);
                DrawAllCards(xp, stateCards, rectTraject);
                stimOnset = xp.flip;
                if k == 1
                    xp.eyelink.write('cards in place face down @%.3fsec',stimOnset)
                    WaitSecs(.2);
                    iFrameMovement = 0;                          % Reset vars for next movement
                    k = -1;
                    xp.eyelink.write('bottom cards face up @%.3fsec',stimOnset)
                    xp.eeg.eventSave('bcfu', stimOnset)          % bottom cards face up
                    flagTrialStep        = 'track gaze top';     % Go to next step
                    timeOutOfScreenStart = stimOnset;
                    timeStepStart        = stimOnset;
                    %                     end
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Tracking gaze on TOP card
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Highlight & flip when fixated long enough
        case 'track gaze top'

            % Get how long fixation has been going and whether to switch to a new AOI
            % if fixation is lost, then timer resets to new roi after $timeOut seconds
            if roiFix == roiFixLast % if look away then back to the same: add to the former count
                durFixIn               = timeLastIn(roiFix + 1) - timeFirstIn;     % update duration if continuing fixating !!! Need to make sure no rounding errors mess things too much, too many additions? !!!!
                timeLastIn(roiFix + 1) = timeFix;
            else % if looks to a roi different to last roi: make a new count
                % Log time fixating prospective AOI
                timeLastIn(roiFix + 1) = timeFix;
                timeFirstIn            = timeFix;
                % Check if looked for long enough out of last ROI to make
                % prospective AOI current AOI
                durFixOut              = timeFix - timeLastIn(roiFixLast + 1);    % seconds not looking on last roi
                if durFixOut > timeOut
                    xp.eyelink.write('roichange: from %d to %d at states %s after %.3fsec @%.3fsec', roiFixLast, roiFix, num2str(flagCardFlipped), timeLastIn(roiFixLast + 1), timeFix)
                    durFixIn           = min(timeFix - timeLastIn(timeLastIn ~= timeFix));
                    roiFixLast         = roiFix;
                end
            end

            % Highlight the current AOI card if fixated for long enough
            % If fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
            if roiFix == nStimOnScreen && roiFix == roiFixLast && stateCards(roiFix) == 0 && (GetSecs - timeStepStart > timeMinVisible) && (durFixIn > timeToTrigger1)
                stateCards(roiFix) = 1;
                DrawAllCards(xp, stateCards);
                tHighlight         = xp.flip;

                xp.sound.stop;
                xp.sound.which = xp.sound.data{2,8}; %click
                xp.sound.play;
            end

            % Flip the current AOI card if fixated for long enough
            % if fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
            if roiFix == nStimOnScreen && roiFix == roiFixLast && stateCards(roiFix) == 1 && (GetSecs - tHighlight > timeToTrigger1) && (durFixIn > timeToTrigger1)
                % Move on to next step
                % Change which card should face up or down
                stateCards(1:nStimOnScreen-1) = 0;
                stateCards(nStimOnScreen)     = 2;
                % Draw cards
                DrawAllCards(xp, stateCards);
                tTopCardUp = xp.flip;
                xp.eyelink.write('top card faces up @%.3fsec',tTopCardUp)
                xp.eeg.eventSave('tcfu', tTopCardUp) % top card faces up
                % Play sounds
                xp.sound.stop;
                xp.sound.which = xp.sound.data{2,3}; %flip
                xp.sound.play;
                % Go to next step
                if strcmp(trialtype, 'FamMatch')
                    flagTrialStep  = 'Fam M1 - match';
                    flagBeginMatch = true;
                    WaitSecs(1)
                    tTopCardTilts  = GetSecs;
                    xp.eyelink.write('top card tilts @%.3fsec', tTopCardTilts)
                    xp.eeg.eventSave('f2ti', tTopCardTilts)  % t top card titlts (matching can start)
                else
                    flagTrialStep  = 'track bottom';
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Tracking gaze on BOTTOM cards
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Highlight & flip when fixated long enough
        case 'track bottom'

            if ~flagFlippedBottomChosen % track only while choosen card has not been flipped yet
                % Get how long fixation has been going and whether to switch to a new AOI
                % if fixation is lost, then timer resets to new roi after $timeOut seconds
                if roiFix == roiFixLast % if look away then back to the same: add to the former count
                    durFixIn               = timeLastIn(roiFix + 1) - timeFirstIn;     % update duration if continuing fixating !!! Need to make sure no rounding errors mess things too much, too many additions? !!!!
                    timeLastIn(roiFix + 1) = timeFix;
                else % if looks to a roi different to last roi: make a new count
                    % Log time fixating prospective AOI
                    timeLastIn(roiFix + 1) = timeFix;
                    timeFirstIn            = timeFix;
                    % Check if looked for long enough out of last ROI to make
                    % prospective AOI current AOI
                    durFixOut             = timeFix - timeLastIn(roiFixLast + 1);    % seconds not looking on last roi
                    if durFixOut > timeOut
                        xp.eyelink.write('roichange: from %d to %d at states %s after %.3fsec @%.3fsec', roiFixLast, roiFix, num2str(flagCardFlipped), timeLastIn(roiFixLast + 1), timeFix)
                        if roiReward > 0 && roiFixLast == roiReward && flagCardFlipped(roiReward) ~= 2
                            countFirstROI  = countFirstROI + durFixIn; %not sure if logging this is really necessary
                        end
                        durFixIn           = min(timeFix - timeLastIn(timeLastIn ~= timeFix));
                        roiFixLast         = roiFix;
                    end
                end

                % Highlight the current AOI card if fixated for long enough
                % If fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
                if roiFix > 0 && stateCards(roiFix) == 0 && durFixIn > timeToTrigger1 && roiFix == roiFixLast && roiFix < nStimOnScreen %&& flagCardHighlight == 0
                    flagCardHighlight  = roiFix;
                    stateCards(roiFix) = 1;              % highlight
                    DrawAllCards(xp, stateCards);
                    tHighlight         = xp.flip;

                    xp.sound.stop;
                    xp.sound.which     = xp.sound.data{2,8}; %click
                    xp.sound.play;
                end

                % Flip the current AOI card if fixated for long enough
                % if fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated

                % 1... CARD THAT BABY LOOKED AT
                if roiFix > 0 && stateCards(roiFix) == 1 && durFixIn > timeToTrigger1 && (GetSecs - tHighlight) > timeToTrigger1 && flagFlippedBottomChosen == 0
                    % Change which card should face up or down
                    stateCards(flagCardHighlight) = 2;
                    DrawAllCards(xp, stateCards);
                    tBottCardUp2                     = xp.flip;
                    xp.sound.stop;
                    if ~strcmp(trialtype,'Test') % for fam trials only
                        if flagCardHighlight == positionStimMatch
                            xp.sound.which = xp.sound.data{2,4}; %Yay
                        else
                            xp.sound.which = xp.sound.data{2,5}; %Uh-Oh
                        end
                        xp.sound.play;
                    end
                    flagFlippedBottomChosen = 1;
                end
            end
            % 2... OTHER CARDS IF flagFlipAllCards (FAM TRIALS)
            if  flagFlippedBottomChosen && (GetSecs > (tBottCardUp2 + 1))
                if flagFlipAllCards && flagFlippedBottomOther == 0
                    % Change which card should face up or down
                    stateCards(1:nStimOnScreen-1) = 2;
                    DrawAllCards(xp, stateCards);
                    tAllBottCardUp                = xp.flip;

                    xp.sound.stop;
                    xp.sound.which = xp.sound.data{2,3}; %Flip
                    xp.sound.play;
                    flagFlippedBottomOther = 1;
                elseif ~flagFlipAllCards
                    flagFlippedBottomOther = 1;
                    tAllBottCardUp         = tBottCardUp2;
                end
            end

            % THEN MOVE ON TO NEXT STEP
            if flagFlippedBottomOther && GetSecs > (tAllBottCardUp + 1 )
                % Save timings
                xp.eyelink.write('flipped bottom card (%s) to face up@%.3fsec',cardPos{flagCardHighlight},tBottCardUp2)
                xp.eeg.eventSave('look', timeFirstIn)  % t looked at bottom card which triggered the flip
                xp.eeg.eventSave('bcfl', tBottCardUp2) % t bottom card flips
                flagTrialStep = 'move match up'; % MIGHT NEED TO MOVE TO A DIFFERENT STEP FOR FamMatch1 TRIALS
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MOVE MATCH CARD UP
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% If Fam trial / test trial correct

        case 'move match up'

            % if Fam trial or if correct test trial
            if (flagFlipAllCards || flagCardHighlight == positionStimMatch) && ~flagMoveUpDone
                % Draw cards
                % Iniate movement vars
                if iFrameMovement2 == 0
                    tCardGoesUp  = GetSecs;
                    xp.eyelink.write('start move up @%.3fsec',tCardGoesUp)
                    xp.eeg.eventSave('movu', tCardGoesUp) % bottom card moves up
                end
                % Increment
                iFrameMovement2  = iFrameMovement2 + 1;
                k2               = K2(iFrameMovement2);
                % Calculate positions
                rectTrajectCard  = round(xp.screen.rect(:, 1 + positionStimMatch) * (1-k2) + k2 * [xp.screen.rect(:,1 + 4*nStimOnScreen + positionStimMatch)]);
                rect                      = round(xp.settings.rectCards);
                rect(:,positionStimMatch) = rectTrajectCard;
                DrawAllCards(xp, stateCards, rect);
                stimOnset                 = xp.flip;
                stimOnset0                = stimOnset;
                % Exit this loop when reached the last movement frame (k = 1)
                if k2 == 1
                    xp.eyelink.write('card is next to top @%.3fsec',stimOnset)
                    cardsPos(flagCardHighlight) = 2;
                    % Reset vars for next movement phase
                    flagMoveUpDone  = 1;
                    iFrameMovement2 = 0;
                end
            end

            % Start next step if move up is done or if incorrect test trial
            if ((~flagFlipAllCards && flagCardHighlight ~= positionStimMatch)) || flagMoveUpDone
                stimOnset0     = GetSecs;
                iFrameMovement = 0;
                flagTrialStep  = 'feedback'; % MIGHT NEED TO MOVE TO A DIFFERENT STEP FOR FamMatch1 TRIALS
            end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FEEDBACK
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Play either reward or bad
        case 'feedback'

            % NOW PLAY REWARD & TILT
            if flagMoveUpDone &&  (flagCardHighlight == positionStimMatch)
                tRewardStart = GetSecs;
                % Reward sound
                if iFrameMovement == 0
                    xp.eyelink.write('start reward @%.3fsec',tRewardStart)
                    xp.eeg.eventSave('rew0', tRewardStart) % start reward
                    flagAccuracy   = 'Correct';
                    flagChosenSide = cardPos{flagCardHighlight};
                    xp.sound.stop;
                    xp.sound.which = xp.sound.data{2,6};
                    xp.sound.play;
                end
                % Draw cards
                % Increment
                iFrameMovement  = iFrameMovement + 1;
                k               = KAngle(iFrameMovement);
                % Calculate angle
                newAngle = (k*angleEnd + (1-k)*angleStart) * (-positionStimMatch*2+3); %1=L, 2=R -> L = -1, R = 1
                rect = round(xp.settings.rectCards);
                rect(:,positionStimMatch) = rectTrajectCard;
                angle = zeros(1,nStimOnScreen);
                angle(positionStimMatch) = newAngle;
                DrawAllCards(xp, stateCards, rect, angle)
                stimOnset = xp.flip;
                % Exit this loop when reached the last movement frame (k = 1)
                if iFrameMovement == length(KAngle)
                    tRewardEnd = stimOnset;
                    xp.eyelink.write('end reward @%.3fsec',tRewardEnd)
                    cardsPos(flagCardHighlight) = 2;
                    WaitSecs(1);
                    % Reset vars for next movement phase
                    k              = -1;
                    iFrameMovement = 0;
                    flagTrialStep  = 'end';
                end


                % OR PLAY BAD
            elseif GetSecs > (stimOnset0 + .5)
                % Cards disintegrate
                % Draw background
                Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
                % Draw cards
                % Iniate movement vars
                if iFrameMovement == 0
                    tBad   = GetSecs;
                    xp.eyelink.write('start bad @%.3fsec',tBad)
                    xp.eeg.eventSave('bad0', tBad) % start bad feedback = fading
                    flagAccuracy   = 'Incorrect';
                    flagChosenSide = cardPos{flagCardHighlight};
                end
                % Increment
                iFrameMovement  = iFrameMovement + 1;
                k               = KAlpha(iFrameMovement);
                % Calculate alpha (transparency)
                newAlpha        = (k*alphaEnd + (1-k)*alphaStart);
                % Draw cards (moving + non-moving ones)
                for iObject = 1:nStimOnScreen
                    if iObject == flagCardHighlight % bottom, face up
                        rectC(:,iObject) = xp.screen.rect(:, 1 + iObject); %#ok<*AGROW>
                        rectO(:,iObject) = xp.screen.rect(:, 1 + nStimOnScreen + iObject);
                        tC(iObject)      = xp.image.texture{3,3};
                        tO(iObject)      = xp.image.texture{5,idStim(iObject)};
                    elseif stateCards(iObject)      % top, face up
                        if flagFlipAllCards && iObject == positionStimMatch
                            rectC(:,iObject) = xp.screen.rect(:, 1 + 4*nStimOnScreen + iObject);
                            rectO(:,iObject) = xp.screen.rect(:, 1 + 4*nStimOnScreen + 2 + iObject);
                            tC(iObject)      = xp.image.texture{3,3};
                            tO(iObject)      = xp.image.texture{5,idStim(iObject)};
                        else
                            rectC(:,iObject) = xp.screen.rect(:,1 + iObject);
                            rectO(:,iObject) = xp.screen.rect(:,1 + nStimOnScreen + iObject);
                            tC(iObject)      = xp.image.texture{3,3};
                            tO(iObject)      = xp.image.texture{5,idStim(iObject)};
                        end
                    else                            % bottom, face down
                        rectC(:,iObject) = xp.screen.rect(:, 1 + iObject);
                        rectO(:,iObject) = xp.screen.rect(:, 1 + iObject);
                        tC(iObject)      = xp.image.texture{3,1};
                        tO(iObject)      = xp.image.texture{3,1};
                    end
                end
                textures  = [tC tO];
                rects     = [rectC, rectO];
                Screen('DrawTextures', xp.screen.win, textures,[],rects,[],[],newAlpha );
                stimOnset = xp.flip;
                % Exit this loop when reached the last movement frame (k = 1)
                if iFrameMovement == length(KAlpha)
                    xp.eyelink.write('cards disintegrated @%.3fsec',stimOnset)
                    cardsPos(flagCardHighlight) = 2;
                    WaitSecs(1);
                    % Reset vars for next movement phase
                    k              = -1;
                    iFrameMovement = 0;
                    flagTrialStep  = 'end';
                end
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END OF TRIAL
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Cards fly out
        case 'end'

            if flagCardHighlight == positionStimMatch
                % FLY OUT
                if iFrameMovement == 0
                    timeFlyOut = GetSecs;
                    xp.eyelink.write('cards start flying out @%.3fsec',timeFlyOut)
                    xp.eeg.eventSave('cfly', timeFlyOut) % cards (start) flying out
                    xp.sound.stop;
                    xp.sound.which = xp.sound.data{2,7};
                    xp.sound.play;
                end
                % Draw background
                Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
                % Draw cards
                % Increment
                iFrameMovement  = iFrameMovement + 1;
                k               = K(iFrameMovement);
                for iObject = 1:nStimOnScreen
                    % Calculate positions & Draw cards (moving + non-moving ones)
                    if iObject == nStimOnScreen   % top middle card (always face up)
                        rectTrajectCard(:,iObject) = round(xp.screen.rect(:, 1 + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 2)]);
                        rectTrajectObj(:,iObject)  = round(xp.screen.rect(:, 1 + nStimOnScreen + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 4)]);
                        tC(iObject) = xp.image.texture{3,3};
                        tO(iObject) = xp.image.texture{5,idStim(iObject)};
                    elseif cardsPos(iObject) == 2 % any other card at the top (always face up)
                        rectTrajectCard(:,iObject) = round(xp.screen.rect(:, 1 + 4*nStimOnScreen + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 2)]);
                        rectTrajectObj(:,iObject)  = round(xp.screen.rect(:, 1 + 4*nStimOnScreen + 2 + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 4)]);
                        tC(iObject) = xp.image.texture{3,3};
                        tO(iObject) = xp.image.texture{5,idStim(iObject)};
                    elseif flagFlipAllCards       % any bottom card face up
                        rectTrajectCard(:,iObject) = round(xp.screen.rect(:, 1 + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 1)]);
                        rectTrajectObj(:,iObject)  = round(xp.screen.rect(:, 1 + nStimOnScreen + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 3)]);
                        tC(iObject) = xp.image.texture{3,3};
                        tO(iObject) = xp.image.texture{5,idStim(iObject)};
                    else                          % any bottom card, face down
                        rectTrajectCard(:,iObject) = round(xp.screen.rect(:, 1 + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 1)]);
                        tC(iObject) = xp.image.texture{3,1};
                        % Need to add an object to concatenate -- copied card
                        rectTrajectObj(:,iObject) = round(xp.screen.rect(:, 1 + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 1)]);
                        tO(iObject) = xp.image.texture{3,1};
                    end
                end
                textures = [tC tO];
                rects    = [rectTrajectCard, rectTrajectObj];
                Screen('DrawTextures', xp.screen.win, textures,[],rects);
                stimOnset = xp.flip;
                % Exit this loop when reached the last movement frame (k = 1)
                if k == 1
                    xp.eyelink.write('cards flied out @%.3fsec',stimOnset)
                    WaitSecs(.2);
                    flagLoop     = 0;
                    flagEndTrial = 1;
                end
            else
                flagLoop     = 0;
                flagEndTrial = 1;
            end

        case 'Fam F'

            % FAM TRIAL 1: 9 cards to flip, flip back when flip a new card
            % Terminate when time >45s and no flip for >10s:
            %    - if flipped at least 6 cards -> move on to next trial type
            %    - if not                      -> repeat the same trial
            % If t < 45s: keep going and check again later.


            %% CHECK WHICH CARD IS FLIPPED AND KEEP TRACK OF IT (and the timings)

            % Get how long fixation has been going and whether to switch to a new AOI
            % if fixation is lost, then timer resets to new roi after $timeOut seconds
            if roiFix == roiFixLast % if look away then back to the same: add to the former count
                durFixIn               = timeLastIn(roiFix + 1) - timeFirstIn;     % update duration if continuing fixating !!! Need to make sure no rounding errors mess things too much, too many additions? !!!!
                timeLastIn(roiFix + 1) = timeFix;
            else % if looks to a roi different to last roi: make a new count
                % Logging time fixating prospective AOI
                timeLastIn(roiFix + 1) = timeFix;
                timeFirstIn            = timeFix;
                % Checking whether looked for long enough out of last ROI to
                % make prospective AOI current AOI
                durFixOut              = timeFix - timeLastIn(roiFixLast + 1);     % seconds not looking on last roi
                if durFixOut > timeOut
                    xp.eyelink.write('roichange: from %d to %d at states %s after %.3fsec @%.3fsec', roiFixLast, roiFix, num2str(flagCardFlipped), timeLastIn(roiFixLast + 1), timeFix)
                    durFixIn           = min(timeFix - timeLastIn(timeLastIn ~= timeFix));
                    roiFixLast         = roiFix;
                end
            end

            % Highlight the current AOI card if fixate for long enough
            % if fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
            if (roiFix>0) && stateCards(roiFix)==0 && (durFixIn > timeToTrigger1) && (roiFix == roiFixLast)
                stateCards(roiFix) = 1;
                DrawAllCards(xp, stateCards);
                tHighlight         = xp.flip;
                xp.sound.stop;
                xp.sound.which     = xp.sound.data{2,8};
                xp.sound.play;
            end

            % Flip the current AOI card if fixate for long enough
            % if fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
            if (roiFix>0)  && stateCards(roiFix)==1 && (durFixIn > timeToTrigger1) && (GetSecs - tHighlight > timeToTrigger1) 
                stateCards(:)        = 0;              % flip the other card back when a new card is flipped
                stateCards(roiFix)   = 2;
                flippedCards(roiFix) = 1;              % keep track of which card was flipped here
                DrawAllCards(xp, stateCards);
                tTurnUp              = xp.flip;
                xp.eyelink.write('flipped card (%s) to face up @%.3fsec',cardPos{roiFix},tTurnUp) % EEG trig
                xp.eeg.eventSave('f1lo', timeFirstIn)  % t looked at card which triggered the flip
                xp.eeg.eventSave('f1fl', tTurnUp)      % t card flips

                xp.sound.stop;
                xp.sound.which = xp.sound.data{2,3};
                xp.sound.play;
            end

            % Terminate when:
            % >45s and no flip for >10s: repeat if flipped < 6 cards, else move on
            % OR flipped all 9 cards > 3s ago: move one
            if (GetSecs >= tTrialStart + 45 && GetSecs >= tTurnUp + 10) || (sum(flippedCards) == 9 && GetSecs >= tTurnUp + 3)
                if sum(flippedCards) < 6
                    flagResult   = 6;
                end
                flagEndTrial     = 1;
            end

            %%%%%%%%%%%%%%%%%%%% SAY SEE AND TILT TOP CARD
            %%%%%%%%%%%%%%%%%%%% + track gaze on bottom cards, highlight & flip
        case 'Fam M1 - match'
            % After top card fixated for long enough: flips and tilts

            % Set defaults and movement vars at start
            if flagBeginMatch
                stateCards(nStimOnScreen) = 2; %flipped not highlighted
                iFrameMovement = 0;
                flagBeginMatch = false;
                flagTilt       = true;
                % Say see at start
                xp.sound.stop;
                xp.sound.which = xp.sound.data{2,9};
                xp.sound.play;
                timeBeginMatch = GetSecs;
                timeHighlight  = 0;
                flagPickedCard = 0;
            end

            % Top card tilting
            if flagTilt
                if iFrameMovement>=length(KAngle2)
                    iFrameMovement = 0;
                end
                iFrameMovement  = iFrameMovement + 1;
                k               = KAngle2(iFrameMovement);
                % Calculate angle
                angle = (k*angleEnd + (1-k)*angleStart) * (-positionStimMatch*2+3); %1=L, 2=R -> L = -1, R = 1
                DrawAllCards(xp, stateCards, [], [0 0 angle]);
                xp.flip;
            end
            % End tilting
            if k == 0 && GetSecs - timeBeginMatch >= .7 %|| any(stateCards == 3))
                DrawAllCards(xp, stateCards, []);
                iFrameMovement = 0;
                flagTilt = false;
            end

            % Get how long fixation has been going and whether to switch to a new ROI
            % if fixation is lost, then timer resets to new roi after $timeOut seconds
            if roiFix == roiFixLast
                durFixIn               = timeLastIn(roiFix + 1) - timeFirstIn;     % update duration if continuing fixating !!! Need to make sure no rounding errors mess things too much, too many additions? !!!!
                timeLastIn(roiFix + 1) = timeFix;
            else
                durFixOut              = timeFix - timeLastIn(roiFixLast + 1);     % seconds not looking on last roi
                timeLastIn(roiFix + 1) = timeFix;
                timeFirstIn            = timeFix;
                if durFixOut > timeOut
                    xp.eyelink.write('roichange: from %d to %d at states %s after %.3fsec @%.3fsec', roiFixLast, roiFix, num2str(flagCardFlipped), timeLastIn(roiFixLast + 1), timeFix)
                    if roiTop > 0 && roiFixLast == roiTop && flagCardFlipped(roiTop) ~= 2
                        countFirstROI  = countFirstROI + durFixIn;
                    end
                    durFixIn           = min(timeFix - timeLastIn(timeLastIn ~= timeFix));
                    roiFixLast         = roiFix;
                end
            end

            % Highlight ROI fixated (if not top card)
            if  roiFix > 0 && (stateCards(roiFix) == 0 || stateCards(roiFix) == 2) && durFixIn > timeToTrigger1 && roiFix < nStimOnScreen ...
                     && roiFix == roiFixLast && (GetSecs - timeBeginMatch) > .7 %&& (all(stateCards < 3) || (GetSecs - timeHighlight) > timeToTrigger1)
                %                 stateCards(stateCards==1) = 0; stateCards(stateCards==3) = 2; % reset non-fixated cards
                if stateCards(roiFix) == 0
                    stateCards(1:end-1) = 0;
                    stateCards(roiFix) = 1;   % fixated card is highlighted
                elseif stateCards(roiFix) == 2
                    stateCards(1:end-1) = 2;
                    stateCards(roiFix) = 3;   % fixated card is flipped AND highlighted
                end
                DrawAllCards(xp, stateCards, []);
                xp.flip
                xp.sound.stop;
                xp.sound.which    = xp.sound.data{2,8}; %click
                xp.sound.play;
                flagCardHighlight = roiFix;
                timeHighlight     = GetSecs;
            end

            % Flip & send to feedback if fixated one of the bottom cards for long enough
            if roiFix > 0 && (stateCards(roiFix) == 1 || stateCards(roiFix) == 3) ...
                    && durFixIn > timeToTrigger1 && (GetSecs - timeHighlight) > timeToTrigger1/2 && roiFix == roiFixLast && durFixIn > timeToTrigger1
                % Flip
                stateCards(:)  = 2;  % non fixated card is flipped
                stateCards(roiFix) = 3;  % fixated card is flipped AND highlighted
                DrawAllCards(xp, stateCards, []);
                xp.flip
                if any(stateCards < 2)
                    xp.sound.stop;
                    xp.sound.which     = xp.sound.data{2,3}; %flip
                    xp.sound.play;
                end
                % Feedback
                if idStim(flagCardHighlight)==idStim(nStimOnScreen) % if fixated match
                    xp.sound.which    = xp.sound.data{2,4};
                    flagTrialStep     = 'move match up';   % go to feedback REWARD
                else                                                % if fixated non-match
                    flagChance = flagChance-1;
                    if flagChance > 0                      % get a 2nd chance
                        xp.sound.which = xp.sound.data{2,5};
                        flagTrialStep  = 'Fam M1 - 2nd chance';
                        kStep3 = (1/1.5)*kStep2;           % (more movement so more steps to keep same speed)
                        K3    = [0:kStep3:1, 1:-kStep3:0];
                    elseif flagChance<=0
                        xp.sound.which = xp.sound.data{2,5};
                        flagTrialStep  = 'move match up';   % go to feedback BAD - game over after 2 chances
                    end
                end
                xp.sound.play;
                % Reset vars
                iFrameMovement = 0;
                flagBeginMatch = true;
            end

        case 'Fam M1 - 2nd chance'

            % Match card moves up and down
            if iFrameMovement == 0
                tCardGoesUp   = GetSecs;
                xp.eyelink.write('start move up and down (2nd chance) @%.3fsec',tCardGoesUp) % EEG trig
                xp.eeg.eventSave('2ndc', tCardGoesUp)
            end
            % Increment
            iFrameMovement     = iFrameMovement + 1;
            k2                 = K3(iFrameMovement);
            % Calculate positions
            rectTrajectCard    = round(xp.screen.rect(:, 1 + positionStimMatch) * (1-k2) + k2 * [xp.screen.rect(:,1 + 4*nStimOnScreen + positionStimMatch)]);
            rect               = round(xp.settings.rectCards);
            rect(:,positionStimMatch) = rectTrajectCard;
            DrawAllCards(xp, stateCards, rect);
            stimOnset          = xp.flip;
            stimOnset0         = stimOnset;
            % Exit this loop when reached the last movement frame (k = 1)
            if iFrameMovement == length(K3)
                xp.eyelink.write('card is back in place @%.3fsec',stimOnset)
                stateCards(flagCardHighlight) = 2; % reset
                flagCardHighlight = 0;
                flagTrialStep  = 'Fam M1 - match';
                flagBeginMatch = true;
                tTopCardTilts  = GetSecs;
                DrawAllCards(xp, stateCards);
                xp.flip;
            end
    end


    %% ----- THINGS TO CHECK WITH EACH TRIAL LOOP RUN REGARDLESS OF TRIALSTEP

    %%% checking fixations
    if ~strcmp(trialtype, 'FamFlip')
        [roiFix, timeFix] = xp.checkFix([1+(1:nStimOnScreen) 1], 1/30); % added some padding (1/30 * screen height) to make AOIs bigger
    else
        famRects  = (length(xp.screen.rect)-1-9*2:length(xp.screen.rect)-2-9);
        [roiFix, timeFix] = xp.checkFix([famRects 1], 0); % added some padding (1/30 * screen height) to make AOIs bigger
    end
    if roiFix == 0                    % AOI 0 = no gaze on screen
        if timeOutOfScreenStart == Inf
            timeOutOfScreenStart = timeFix;
        end
    else
        timeOutOfScreenStart = Inf;
        if roiFix == nStimOnScreen + 1 % the last AOI is the screen (to check if baby is looking away) -- turn this into 0 for ease of use
            roiFix = 0;
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%% keyboard check %%%%%%%%%%%%%%%%%%%%%%%%%%%
    [keyIsDown,keyOnset,keyCode] = PsychHID('KbCheck', xp.keyboard.index);      %reads key pressed
    if keyIsDown
        switch find(keyCode,1)
            case key.escape
                flagEndTrial = 1;
                flagResult   = 3;
                xp.eyelink.write('Pressed escape key - skip trial',keyOnset)
                xp.eeg.eventSave('kesc', keyOnset)
            case key.q
                flagEndTrial = 1;
                flagResult   = 9;
                xp.eyelink.write('Pressed q key - quit experiment',keyOnset)
                xp.eeg.eventSave('kqui', keyOnset)
            case key.c
                flagEndTrial = 1;
                flagResult   = -1;         % calibrate
                xp.eyelink.write('Pressed c key - recalibrate',keyOnset)
                xp.eeg.eventSave('kcal', keyOnset)
            case key.p
                flagEndTrial = 1;
                flagResult   = -2;
                xp.eyelink.write('Pressed p key - play the pause video then restart trial',keyOnset)
                xp.eeg.eventSave('kpau', keyOnset)
            case key.s                      % plays attention sound
                if GetSecs - timeLastSound > 0.5        % making sure it is not just key staying pressed
                    xp.sound.which = xp.sound.data{1,randi(6)};
                    timeLastSound  = xp.sound.play;
                    xp.eyelink.write('Pressed s key - play sound random attention getter',keyOnset)
                    xp.eeg.eventSave('ksou', timeLastSound)
                end
        end
    end

    if flagEndIfLookAway && GetSecs - tTrialStart > durTrialMax % This is not for FamFlip of FamMatch1 trials (see flagEndIfLookAway)
        flagEndTrial = 1;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%% end of trial %%%%%%%%%%%%%%%%%%%%%%%%%
    if flagEndTrial == 1

        tTrialEnd = GetSecs;
        xp.eyelink.write(goodbyeMessage, tTrialEnd)
        xp.eeg.eventSave('endT', tTrialEnd)
        xp.eeg.eventSend('type', xp.trial.varValue.trialtype, 'trial', xp.trial.varValue.trialno, 'diff', xp.trial.varValue.difficulty, 'accuracy', flagAccuracy, 'chosenSide', flagChosenSide, 'objL', xp.trial.varValue.objL, 'objR', xp.trial.varValue.objR, 'objT', xp.trial.varValue.objT)
        if ~strcmp(trialtype, 'FamFlip')
            xp.trial.varValue.accuracy    = flagAccuracy;
            xp.trial.varValue.chosenSide  = flagChosenSide;
            xp.trial.varValue.durFixFirst = countFirstROI;
        else
            xp.trial.varValue.accuracy    = '';
            xp.trial.varValue.chosenSide  = '';
            xp.trial.varValue.durFixFirst = NaN;
        end
        disp(goodbyeMessage)
        disp(flagCardFlipped)
        flagLoop = false;
        xp.erase

    end
end


end