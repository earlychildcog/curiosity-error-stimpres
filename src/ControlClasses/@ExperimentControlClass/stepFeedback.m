function flagResult = stepFeedback(xp, flagCorrect, stateCards, cardsPos)

%% STARTUP

% initialise
flagResult = false;

% send start event
xp.eyelink.write('start feedback @%.3fsec',GetSecs)

% tilting settings
stimOnset = 0;
durFrame   = 0.0333333333;
durOffset  = 0.009;
iFrameMovement = 0;
angleStart      = 0;
angleEnd        = 20;
durAngleParts   = [0.3 0.15 0.3];
kStepAngle      = durFrame./durAngleParts;
KAngle          = [0:kStepAngle(1):1, ones(1,round(1./kStepAngle(2))), 1:-kStepAngle(3):0];

% alpha settings
alphaStart      = 1;
alphaEnd        = 0;
durAlpha        = 2;
kStepAlpha      = durFrame/durAlpha;
KAlpha          = 0:kStepAlpha:1;

if flagCorrect
    nFrameMovement = length(KAngle);
else
    nFrameMovement = length(KAlpha);
end
% stim settings
nStimOnScreen = xp.settings.nStimOnScreen;
idStim = xp.settings.idStim;
positionStimMatch = find(idStim == idStim(end), 1);
k2 = 1;
rectTrajectCard  = round(xp.screen.rect(:, 1 + positionStimMatch) * (1-k2) + k2 * [xp.screen.rect(:,1 + 4*nStimOnScreen + positionStimMatch)]);

if startsWith(xp.trial.varValue.trialtype, 'FamMatch')
    iFolderImages = 4;
else
    iFolderImages = 5;
end
% wait for 500ms
WaitSecs(0.5)
%% ACTION LOOP
while iFrameMovement < nFrameMovement

    % check
    flagResult = xp.checkKeyboard;
    if flagResult, return, end

    % NOW PLAY REWARD & TILT
    if flagCorrect
        % movement
        if GetSecs > stimOnset + durFrame - durOffset

            % sound
            if iFrameMovement == 0
                xp.sound.stop;
                xp.sound.which = xp.sound.data{5,xp.trial.rewardToPlay};
                xp.sound.play;
            end

            % Update movement vars
            iFrameMovement  = iFrameMovement + 1;
            k               = KAngle(iFrameMovement);
            % Calculate angle
            newAngle = (k*angleEnd + (1-k)*angleStart) * (-positionStimMatch*2+3); %1=L, 2=R -> L = -1, R = 1
            rect = round(xp.settings.rectCards);
            rect(:,positionStimMatch) = rectTrajectCard;
            angle = zeros(1,nStimOnScreen);
            angle(positionStimMatch) = newAngle;
            DrawAllCards(xp, stateCards, rect, angle)
            stimOnset = xp.flip(stimOnset + durFrame - durOffset);
            if iFrameMovement == 1
                % events
                xp.eyelink.write('start reward @%.3fsec',stimOnset)
                xp.eeg.eventSave('rew0', stimOnset) % start reward
                %                 flagAccuracy   = 'Incorrect';
                %                 flagChosenSide = cardPos{flagCardHighlight};
            end
        end
        % Exit this loop when reached the last movement frame (k = 1)
        if iFrameMovement == nFrameMovement
            tRewardEnd = stimOnset;
            xp.eyelink.write('end reward @%.3fsec',tRewardEnd)
            WaitSecs(1);
        end

        % OR PLAY BAD
    else
        % Cards disintegrate
        if GetSecs > stimOnset + durFrame - durOffset
            % Draw background
            Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
            % Draw cards
            % Iniate movement vars
            % SIMPLIFY THIS SOME POINT
            % Increment
            iFrameMovement  = iFrameMovement + 1;
            k               = KAlpha(iFrameMovement);
            % Calculate alpha (transparency)
            newAlpha        = (k*alphaEnd + (1-k)*alphaStart);
            % Draw cards (moving + non-moving ones)
            for iObject = 1:nStimOnScreen
                if iObject == nStimOnScreen      % original top card
                    rectC(:,iObject) = xp.screen.rect(:,1 + iObject);
                    rectO(:,iObject) = xp.screen.rect(:,1 + nStimOnScreen + iObject);
                    tC(iObject)      = xp.image.texture{3,3};
                    tO(iObject)      = xp.image.texture{iFolderImages,idStim(iObject)};
                elseif cardsPos(iObject) == 2 && iObject == positionStimMatch % bottom card that moved up
                    rectC(:,iObject) = xp.screen.rect(:, 1 + 4*nStimOnScreen + iObject);
                    rectO(:,iObject) = xp.screen.rect(:, 1 + 4*nStimOnScreen + 2 + iObject);
                    tC(iObject)      = xp.image.texture{3,3};
                    tO(iObject)      = xp.image.texture{iFolderImages,idStim(iObject)};
                elseif cardsPos(iObject) == 1 && stateCards(iObject) > 0 % bottom, face up
                    rectC(:,iObject) = xp.screen.rect(:, 1 + iObject); %#ok<*AGROW>
                    rectO(:,iObject) = xp.screen.rect(:, 1 + nStimOnScreen + iObject);
                    tC(iObject)      = xp.image.texture{3,3};
                    tO(iObject)      = xp.image.texture{iFolderImages,idStim(iObject)};
                elseif cardsPos(iObject) == 1 && stateCards(iObject) == 0    % bottom, face down
                    rectC(:,iObject) = xp.screen.rect(:, 1 + iObject);
                    rectO(:,iObject) = xp.screen.rect(:, 1 + iObject);
                    tC(iObject)      = xp.image.texture{3,1};
                    tO(iObject)      = xp.image.texture{3,1};
                else
                    error('card type not recognised')
                end
            end
            textures  = [tC tO];
            rects     = [rectC, rectO];
            Screen('DrawTextures', xp.screen.win, textures,[],rects,[],[],newAlpha);
            stimOnset = xp.flip(stimOnset + durFrame - durOffset);
            if iFrameMovement == 1
                xp.eyelink.write('start bad @%.3fsec',stimOnset)
                xp.eeg.eventSave('bad0', stimOnset) % start bad feedback = fading
                %                 flagAccuracy   = 'Incorrect';
                %                 flagChosenSide = cardPos{flagCardHighlight};
            end
        end
        % Exit this loop when reached the last movement frame (k = 1)
        if iFrameMovement == length(KAlpha)
            xp.eyelink.write('cards disintegrated @%.3fsec',stimOnset)
            WaitSecs(1);
            break
        end
    end
end