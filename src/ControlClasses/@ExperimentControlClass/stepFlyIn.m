function flagResult = stepFlyIn(xp)

%% STARTUP

% initialise
flagResult = false;

% settings movement
iFrameMovement = 0;
durFrame   = 0.0333333333;
durOffset  = 0.009;
durMove    = 0.6666666666;          % in s; careful so that durMove/durFrame is approx an integer for best result
nFrameMovement = round(durMove/durFrame);

% settings other
stateCards     = [2 2 0];                        % 3 cards
nStimOnScreen = xp.settings.nStimOnScreen;
tTrialStart  = GetSecs;
stimOnset = 0;

% events
xp.eyelink.write('trial start @%.3fsec',tTrialStart)
xp.eeg.eventSave('strt' ,tTrialStart)            % start

% sound
xp.sound.stop;
xp.sound.which = xp.sound.data{2,2}; %whoop in
xp.sound.play;

%% ACTION LOOP
while iFrameMovement < nFrameMovement    
    
    % checks
    flagResult = xp.checkKeyboard;
    flagResult = xp.checkEndTrial(flagResult);
    if flagResult, return, end

    % screen flips
    if GetSecs > stimOnset + durFrame - durOffset
        iFrameMovement = iFrameMovement + 1;
        k              = iFrameMovement/nFrameMovement;
        rectTraject    = round(xp.screen.rect(:, 1 + 2*nStimOnScreen + (1:nStimOnScreen)) * (1-k) + k * [xp.screen.rect(:,1 + (1:nStimOnScreen))]);
        DrawAllCards(xp, stateCards, rectTraject);
        stimOnset = xp.flip(stimOnset + durFrame - durOffset);
    end

end

%% END STEP

% events send end
timeStepEnd        = stimOnset;
xp.eyelink.write('cards in place face down @%.3fsec',timeStepEnd)
xp.eyelink.write('bottom cards face up @%.3fsec',timeStepEnd)
xp.eeg.eventSave('bcfu', timeStepEnd)          % bottom cards face up

