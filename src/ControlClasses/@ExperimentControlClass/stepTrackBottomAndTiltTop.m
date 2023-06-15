function [flagResult, stateCards, flagCorrect] = stepTrackBottomAndTiltTop(xp, stateCards)
% SAY SEE AND TILT TOP CARD
% + track gaze on bottom cards, highlight & flip
% After top card fixated for long enough: flips and tilts


%% STARTUP
nStimOnScreen  = xp.settings.nStimOnScreen;
idStim         = xp.settings.idStim;
durToHighlight = xp.settings.durToHighlight;
durMinToFlip   = xp.settings.durMinToFlip;
% initialise
flagKeyFlip    = false;
flagCorrect  = false; % if fixated non-match
flagResult   = 0 ;
cardPos      = ["left","right","top"];
% movement
iFrameMovement  = 0;
durFrame        = 0.0333333333;
durOffset       = 0.009;
angleStart      = 0;
angleEnd        = 20;
durAngleParts   = [0.3 0.15 0.3];
kStepAngle      = durFrame./durAngleParts;
KAngle          = [0:kStepAngle(1):1, 1:-kStepAngle(3):-1, -1:kStepAngle(1):0];
nFrameMovement  = length(KAngle);
stimOnset       = GetSecs;

% sound (see)
xp.sound.stop;
xp.sound.which  = xp.sound.data{2,9};
xp.sound.play;


timeStepStart  = GetSecs;
timeHighlight   = 0;

%% ACTION LOOP
while true

    % checks
    [roiFix, timeFix, flagKeyFlip] = xp.checkFix(1+(1:nStimOnScreen), 1/30); % added some padding (1/30 * screen height) to make AOIs bigger
    [durFixIn, flagFixIn, timeFirstIn] = xp.checkROI(roiFix, timeFix);
    flagResult = xp.checkKeyboard;
    flagResult = xp.checkEndTrial(flagResult, roiFix);
    if flagResult, return, end

    % movement (tilting)
    if iFrameMovement < nFrameMovement
        iFrameMovement  = iFrameMovement + 1;
        k               = KAngle(iFrameMovement);
        % Calculate angle
        angle = (k*angleEnd + (1-k)*angleStart); %1=L, 2=R -> L = -1, R = 1
        DrawAllCards(xp, stateCards, [], [0 0 angle]);
        stimOnset = xp.flip(stimOnset + durFrame - durOffset);
    end


    % HIGHLIGHT
    if roiFix > 0 && (stateCards(roiFix) == 0 || stateCards(roiFix) == 2) &&...
            durFixIn > durToHighlight && flagFixIn &&...
            roiFix < nStimOnScreen && (GetSecs - timeStepStart) > .7
        if stateCards(roiFix) == 0
            stateCards(1:end-1) = 0;
            stateCards(roiFix) = 1;   % fixated card is highlighted
        elseif stateCards(roiFix) == 2
            stateCards(1:end-1) = 2;
            stateCards(roiFix) = 3;   % fixated card is flipped AND highlighted
        end
        DrawAllCards(xp, stateCards, []);
        xp.flip
        % sound (click)
        xp.sound.stop;
        xp.sound.which    = xp.sound.data{2,8}; %click
        xp.sound.play;
        timeHighlight     = GetSecs;
        timeFirstIn_       = timeFirstIn;
    end
    
    % Flip & send to feedback if fixated one of the bottom cards for long enough
    if  roiFix > 0 && (stateCards(roiFix) == 1 || stateCards(roiFix) == 3) ...
            && durFixIn > durMinToFlip && (GetSecs - timeHighlight) > durMinToFlip && flagFixIn
        % save which side was revelaed
        xp.trial.sideRevealed(end+1) = cardPos(roiFix);
        % Flip
        stateCards(:)  = 2;  % non fixated card is flipped
        stateCards(roiFix) = 3;  % fixated card is flipped AND highlighted
        DrawAllCards(xp, stateCards, []);
        tBottomCardReveal = xp.flip;
        if any(stateCards < 2)
            xp.sound.stop;
            xp.sound.which     = xp.sound.data{2,3}; %flip
            xp.sound.play;
        end
        % FINISH UP
        if idStim(roiFix)==idStim(nStimOnScreen) % if fixated match
            xp.sound.which  = xp.sound.data{2,4};
            flagCorrect     = true;   % go to feedback REWARD
        else      
            flagCorrect = false; % if fixated non-match
            xp.sound.which = xp.sound.data{2,5};
        end
        % sound
        xp.sound.play;
        break
    end
end

% events
xp.trial.varValue.keyFlip = xp.trial.varValue.keyFlip || flagKeyFlip;
xp.trial.varValue.delayFirstFixB = timeFirstIn_ - timeStepStart;
xp.eeg.eventSave('fixB', timeFirstIn_)  % t looked at bottom card which triggered the flip
xp.eeg.eventSave('bcfl', tBottomCardReveal) % t bottom card flips