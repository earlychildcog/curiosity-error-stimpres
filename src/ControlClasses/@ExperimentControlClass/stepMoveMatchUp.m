function [flagResult, stateCards, cardsPos] = stepMoveMatchUp(xp, stateCards)
% If Fam trial / test trial correct

%% STARTUP

% initialise
flagResult = 0;
cardsPos = [1 1 2];

% settings movement
iFrameMovement = 0;
durFrame   = 0.0333333333;
durOffset  = 0.009;
durMove    =  0.7;          % in s; careful so that durMove/durFrame is approx an integer for best result
nFrameMovement = round(durMove/durFrame);

stimOnset = 0;
nStimOnScreen = xp.settings.nStimOnScreen;
idStim = xp.settings.idStim;
positionStimMatch = find(idStim == idStim(end), 1);



%% ACTION LOOP
while iFrameMovement < nFrameMovement    


    % checks
    flagResult = xp.checkKeyboard;
    if flagResult, return, end

    % movement
    if GetSecs > stimOnset + durFrame - durOffset
        iFrameMovement = iFrameMovement + 1;
        k              = iFrameMovement/nFrameMovement;
        rectTrajectCard  = round(xp.screen.rect(:, 1 + positionStimMatch) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + positionStimMatch)]);
        rect = round(xp.settings.rectCards);
        rect(:,positionStimMatch) = rectTrajectCard;
        DrawAllCards(xp, stateCards, rect);
        stimOnset = xp.flip(stimOnset + durFrame - durOffset);
    end
    
    % events at beginning
    if iFrameMovement == 1
        xp.eyelink.write('start move up @%.3fsec',stimOnset)
        xp.eeg.eventSave('movu', stimOnset) % bottom card moves up
    end
end

%% END STEP
xp.eyelink.write('card is next to top @%.3fsec',stimOnset)
cardsPos(positionStimMatch) = 2;
end