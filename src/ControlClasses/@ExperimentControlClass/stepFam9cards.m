function flagResult = stepFam9cards(xp)
% FAM TRIAL 1: 9 cards to flip, flip back when flip a new card
% Terminate when time >45s and no flip for >10s:
%    - if flipped at least 6 cards -> move on to next trial type
%    - if not                      -> repeat the same trial
% If t < 45s: keep going and check again later.


%% SETTINGS


% initialise
flagResult = 0;
flagKeyFlip = false;

nCards = 8;
durMaxFamFTrial      = 30;      % when to end trial if no cards are being flipped
durMaxNoFlipEndTrial = 7;      %for how long there should be no flip to end the trial

tTurnUp = GetSecs;
tComplete = NaN;
stateCards = zeros(1,nCards);
flippedCards = stateCards;
% nStimOnScreen = xp.settings.nStimOnScreen;
nStimOnScreen = nCards;
durToHighlight = xp.settings.durToHighlight;
durMinToFlip = xp.settings.durMinToFlip;
famRects  = (length(xp.screen.rect)-1-nCards*2:length(xp.screen.rect)-2-nCards);
tTrialStart = GetSecs;
cardPos              = {'Tleft','Tmiddle','Tright',...
    'Mleft','Mright',...
    'Bleft','Bmiddle','Bright'};
DrawAllCards(xp, stateCards);
tHighlight         = xp.flip;


% events
xp.eyelink.write('trial start @%.3fsec',tTrialStart)
xp.eeg.eventSave('strt' ,tTrialStart)            % start

%% ACTION LOOP
% CHECK WHICH CARD IS FLIPPED AND KEEP TRACK OF IT (and the timings)
% Get how long fixation has been going and whether to switch to a new AOI
% if fixation is lost, then timer resets to new roi after $timeOut seconds
while true
    % checks
    [roiFix, timeFix, flagKeyFlip] = xp.checkFix(famRects, -1/50); % took away some padding (1/50 * screen height) to make AOIs SMALLER
    [durFixIn, flagFixIn, timeFirstIn] = xp.checkROI(roiFix, timeFix);
    flagResult = xp.checkKeyboard;
    flagResult = xp.checkEndTrial9cards(flagResult,roiFix);
    if flagResult, return, end

    % Highlight the current AOI card if fixate for long enough
    % if fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
    if (roiFix>0) && stateCards(roiFix)==0 && (durFixIn > durToHighlight) && flagFixIn
        stateCards(stateCards == 1) = 0;
        stateCards(roiFix) = 1;
        DrawAllCards(xp, stateCards);
        tHighlight         = xp.flip;
        % sound
        xp.sound.stop;
        xp.sound.which     = xp.sound.data{2,8};
        xp.sound.play;
    end

    % Flip the current AOI card if fixate for long enough
    % if fixation has been for long enoung, and we have fixation right now on some object, and that object is stably fixated
    if (roiFix>0)  && stateCards(roiFix)==1 && (durFixIn > durMinToFlip) && (GetSecs - tHighlight > durMinToFlip)
        stateCards(:)        = 0;              % flip the other card back when a new card is flipped
        stateCards(roiFix)   = 2;
        flippedCards(roiFix) = 1;              % keep track of which card was flipped here
        DrawAllCards(xp, stateCards);
        tTurnUp              = xp.flip;
        % events
        xp.eyelink.write('flipped card (%s) to face up @%.3fsec',cardPos{roiFix},tTurnUp) % EEG trig
        xp.eeg.eventSave('f1lo', timeFirstIn)  % t looked at card which triggered the flip
        xp.eeg.eventSave('f1fl', tTurnUp)      % t card flips
        % sound
        xp.sound.stop;
        xp.sound.which = xp.sound.data{2,3};
        xp.sound.play;
    end

    if sum(flippedCards) == nCards && isnan(tComplete)
        tComplete = tTurnUp;
    end

    % Terminate when:
    % trial duration >30s and there has been no new flip for >7s: move to next one if flipped >= 3 cards, else repeat
    % OR flipped all cards > 3s ago: move one (NEVER SEEMS TO HAPPEN)
    if (GetSecs >= tTrialStart + durMaxFamFTrial && GetSecs >= tTurnUp + durMaxNoFlipEndTrial) || (sum(flippedCards) == nCards && GetSecs >= tComplete + 3)
        if sum(flippedCards) < 3
            flagResult   = 6;
        end
        break
    end
end
xp.trial.varValue.keyboardFlip = xp.trial.varValue.keyboardFlip || flagKeyFlip;