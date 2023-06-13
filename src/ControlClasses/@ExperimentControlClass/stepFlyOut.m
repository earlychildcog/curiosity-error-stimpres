function flagResult = stepFlyOut(xp, flagCorrect, stateCards, cardsPos)

%% STARTUP

% initialise
flagResult = false;

% settings movement
iFrameMovement = 0;
durFrame   = 0.0333333333;
durOffset  = 0.009;
durMove    = 1;          % in s; careful so that durMove/durFrame is approx an integer for best result
nFrameMovement = round(durMove/durFrame);

nStimOnScreen = xp.settings.nStimOnScreen;
stimOnset = GetSecs;
timeFlyOut = GetSecs;
% events
xp.eyelink.write('cards start flying out @%.3fsec',timeFlyOut)
xp.eeg.eventSave('cfly', timeFlyOut) % cards (start) flying out
xp.sound.stop;
xp.sound.which = xp.sound.data{2,7};
xp.sound.play;

%% ACTION LOOP
while iFrameMovement < nFrameMovement
    % check
    flagResult = xp.checkKeyboard;
    if flagResult, return, end

    if flagCorrect
        % FLY OUT
        if GetSecs > stimOnset + durFrame - durOffset
            iFrameMovement  = iFrameMovement + 1;
            k               = iFrameMovement/nFrameMovement;
            for iObject = 1:nStimOnScreen
                % Calculate positions & Draw cards (moving + non-moving ones)
                if iObject == nStimOnScreen   % top middle card (always face up)
                    rects(:,iObject) = round(xp.screen.rect(:, 1 + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 2)]);
                elseif cardsPos(iObject) == 2 % any other card at the top (always face up)
                    rects(:,iObject) = round(xp.screen.rect(:, 1 + 4*nStimOnScreen + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 2)]);
                else                          % any bottom card
                    rects(:,iObject) = round(xp.screen.rect(:, 1 + iObject) * (1-k) + k * [xp.screen.rect(:,1 + 4*nStimOnScreen + 2*2 + 1)]);
                end
            end
            DrawAllCards(xp, stateCards, rects);
            stimOnset = xp.flip(stimOnset + durFrame - durOffset);
        end
    end
end

%% FINISH UP
xp.eyelink.write('cards flied out @%.3fsec',stimOnset)
WaitSecs(.2);