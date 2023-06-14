function flagResult = stepTrackTop(xp, stateCards)

if nargin < 2
    stateCards = [2 2 0];
end
%% STARTUP

% initialise
flagResult = 0;
flagKeyFlip = false;
nStimOnScreen  = xp.settings.nStimOnScreen;
durToHighlight = xp.settings.durToHighlight; 
durToFlip      = xp.settings.durMinToFlip; 
timeStepStart  = GetSecs;
durMinVisible  = 2;
durMax         = 20;        % abort if subject takes too long to flip

%% ACTION LOOP
while true
    % checks
    [roiFix, timeFix, flagKeyFlip] = xp.checkFix(1+(1:nStimOnScreen), 1/30); % added some padding (1/30 * screen height) to make AOIs bigger
    [durFixIn, flagFixIn, timeFirstIn] = xp.checkROI(roiFix, timeFix);
    flagResult = xp.checkKeyboard;
    flagResult = xp.checkEndTrial(flagResult, roiFix);
    flagResult = xp.checkEndStep(flagResult, timeStepStart, durMax);
    if flagResult, return, end


    % HIGHLIGHT
    % If fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
    if roiFix == nStimOnScreen && flagFixIn && stateCards(roiFix) == 0 &&...
            (GetSecs - timeStepStart > durMinVisible) && (durFixIn > durToHighlight)
        % set state to highlight
        stateCards(roiFix) = 1;
        % draw card
        DrawAllCards(xp, stateCards);
        tHighlight = xp.flip;
        timeFirstIn_       = timeFirstIn;
        % sound
        xp.sound.stop;
        xp.sound.which = xp.sound.data{2,8}; %click
        xp.sound.play;
    end

    % FLIP
    % if fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
    if roiFix == nStimOnScreen && flagFixIn && stateCards(roiFix) == 1 &&...
            (GetSecs - tHighlight > durToFlip) && (durFixIn > durToFlip)
        % Up revealed, down cards hidden
        stateCards(1:nStimOnScreen-1) = 0;
        stateCards(nStimOnScreen)     = 2;
        % Draw cards
        DrawAllCards(xp, stateCards);
        tTopCardUp = xp.flip;
        % events send
        xp.eyelink.write('top card faces up @%.3fsec',tTopCardUp)
        % sound
        xp.sound.stop;
        xp.sound.which = xp.sound.data{2,3}; %flip
        xp.sound.play;
        break
    end
end

%% events

xp.trial.varValue.keyFlip = xp.trial.varValue.keyFlip || flagKeyFlip;
xp.trial.varValue.delayFirstFixT = timeFirstIn_ - timeStepStart;
xp.eeg.eventSave('fixT', timeFirstIn_)  % t looked at bottom card which triggered the flip
xp.eeg.eventSave('tcfl', tTopCardUp) % top card faces up