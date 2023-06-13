function [flagResult, stateCards, flagCorrect] = stepTrackBottom(xp, trialtype)

%% STARTUP


% initialise
flagResult    = false;
flagCorrect   = false;
timeStepStart = GetSecs;
durMax        = 10;   % abort if subject takes too long to flip

% tracking
nStimOnScreen     = xp.settings.nStimOnScreen;
idStim            = xp.settings.idStim;
durMinToFlip      = xp.settings.durMinToFlip;
durToHighlight    = xp.settings.durToHighlight;
stateCards        = [0 0 2];
positionStimMatch = find(idStim == idStim(end), 1);
cardPos           = ["left","right","top"];

DrawAllCards(xp, stateCards);
xp.flip;
%% ACTION LOOP
while true

    % checks
    [roiFix, timeFix] = xp.checkFix(1+(1:nStimOnScreen), 1/30); % added some padding (1/30 * screen height) to make AOIs bigger
    [durFixIn, flagFixIn, timeFirstIn] = xp.checkROI(roiFix, timeFix);
    flagResult = xp.checkKeyboard;
    flagResult = xp.checkEndTrial(flagResult,roiFix);
    flagResult = xp.checkEndStep(flagResult, timeStepStart, durMax);
    if flagResult, return, end



    % HIGHLIGHT
    % If fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
    if roiFix > 0 && stateCards(roiFix) == 0 && durFixIn > durToHighlight &&...
            flagFixIn && roiFix < nStimOnScreen
        stateCards(1:(nStimOnScreen-1)) = 0;
        stateCards(roiFix) = 1;              % highlight
        DrawAllCards(xp, stateCards);
        tHighlight         = xp.flip;
        timeFirstIn_       = timeFirstIn;
        % sound
        xp.sound.stop;
        xp.sound.which     = xp.sound.data{2,8}; %click
        xp.sound.play;
    end

    % REVEAL
    % if fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
    if roiFix > 0 && stateCards(roiFix) == 1 && durFixIn > durMinToFlip &&...
            flagFixIn && (GetSecs - tHighlight) > durMinToFlip
        % save which side was revelaed
        xp.trial.sideRevealed(end+1) = cardPos(roiFix);
        % flip
        stateCards(roiFix) = 2;
        DrawAllCards(xp, stateCards);
        tBottomCardReveal = xp.flip;
        xp.eyelink.write('flipped bottom card (%s) to face up @%.3fsec',cardPos(roiFix),tBottomCardReveal)
        fprintf('flipped bottom card (%s) to face up @%.3fsec\n',cardPos(roiFix),tBottomCardReveal-timeStepStart)
        % sound
        xp.sound.stop;
        flagCorrect = roiFix == positionStimMatch;
        if ~strcmp(trialtype,'Test') % for fam trials only
            if flagCorrect
                xp.sound.which = xp.sound.data{2,4}; %Yay
            else
                xp.sound.which = xp.sound.data{2,5}; %Uh-Oh
            end
            xp.sound.play;
        end
        break
    end
end

%% FINISH UP
% 2... OTHER CARDS IF flagFlipAllCards (FAM TRIALS)
if ~strcmp(trialtype, 'Test')
    % Change which card should face up or down
    stateCards(1:nStimOnScreen-1) = 2;
    DrawAllCards(xp, stateCards);
    tAllBottCardReveal = xp.flip(tBottomCardReveal + 1);

    xp.sound.stop;
    xp.sound.which = xp.sound.data{2,3}; %Flip
    xp.sound.play;
else    % TEST TRIAL, CONFUSED????????????
    DrawAllCards(xp, stateCards);
    tAllBottCardReveal = xp.flip(tBottomCardReveal + 1);
end

% events
xp.eeg.eventSave('look', timeFirstIn_)  % t looked at bottom card which triggered the flip
xp.eeg.eventSave('bcfl', tBottomCardReveal) % t bottom card flips
