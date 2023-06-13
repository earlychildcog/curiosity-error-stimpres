function [flagResult, stateCards] = stepMoveUpDown(xp, stateCards)
% second chance


%% STARTUP

% initialise
flagResult = 0;

% movement
iFrameMovement = 0;
durFrame   = 0.0333333333;
durOffset  = 0.009;
durMove    = 1.4;          % in s; careful so that durMove/durFrame is approx an integer for best result
K = [0:durFrame:durMove/2, durMove/2:-durFrame:0]/durMove*2;
nFrameMovement = length(K);
stimOnset = 0;
nStimOnScreen = xp.settings.nStimOnScreen;
idStim = xp.settings.idStim;
positionStimMatch = find(idStim == idStim(end), 1);

cardsPos = [1 1 2];
tCardGoesUp   = GetSecs;
xp.eyelink.write('start move up and down (2nd chance) @%.3fsec',tCardGoesUp) % EEG trig
xp.eeg.eventSave('2ndc', tCardGoesUp)

%% ACTION LOOP
while iFrameMovement < nFrameMovement

    % checks
    roiFix = xp.checkFix(1, 1/30);
    flagResult = xp.checkKeyboard;
    flagResult = xp.checkEndTrial(flagResult, roiFix);
    if flagResult, return, end

    % Increment
    iFrameMovement     = iFrameMovement + 1;
    k                 = K(iFrameMovement);
    % Calculate positions
    rectTrajectCard    = round(xp.screen.rect(:, 1 + positionStimMatch) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + positionStimMatch)]);
    rect               = round(xp.settings.rectCards);
    rect(:,positionStimMatch) = rectTrajectCard;
    DrawAllCards(xp, stateCards, rect);
    stimOnset          = xp.flip(stimOnset+durFrame-durOffset);
end

%% FINISH UP
xp.eyelink.write('card is back in place @%.3fsec',stimOnset)
stateCards(stateCards==3) = 2; % reset
DrawAllCards(xp, stateCards);
xp.flip;

end