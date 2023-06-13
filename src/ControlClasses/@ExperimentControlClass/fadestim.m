function fadestim(xp, iStim, sideReveal)
if sideReveal <= 0 || sideReveal > 2
    warning('side not 1 or 2')
    return
end

if length(iStim) == 1
    iStim = [iStim iStim];
end

sideConceal = 3 - sideReveal;
% how long to fade in completely
timeMax = 1;     

% sine fade in settings
amp0 = 1;
amp1 = -1;
startPhase = pi/2;



turnaway = 0;
frequency = 1/timeMax;
angFreq = pi/2 * frequency;
ifi = Screen('GetFlipInterval', xp.screen.win);

Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
Screen('DrawTexture', xp.screen.win, xp.image.texture{iStim(sideConceal),2}, [], xp.screen.rect(:,sideConceal + 1), 0, []);
Screen('DrawTexture', xp.screen.win, xp.image.texture{3,1}, [], xp.screen.rect(:,sideConceal + 3));
Screen('DrawTexture', xp.screen.win, xp.image.texture{iStim(sideReveal),2}, [], xp.screen.rect(:,sideReveal + 1), 0, []);
stimOnset = Screen('Flip',xp.screen.win,[],1);
thisContrast = 0;
fadetime = 0;
% WaitSecs(1)
%  
while fadetime < timeMax
    roiFixated = xp.fixCount([2 3], true, true);
    if roiFixated == sideReveal
        turnaway = turnaway + 1;
    else
        turnaway = 0;
    end
    if turnaway < 10
        fadetime = GetSecs - stimOnset;
        thisContrast = amp1 * sin(angFreq * fadetime + startPhase) + amp0;
        Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
        Screen('DrawTexture', xp.screen.win, xp.image.texture{iStim(sideConceal),2}, [], xp.screen.rect(:,sideConceal + 1), 0, []);
        Screen('DrawTexture', xp.screen.win, xp.image.texture{3,1}, [], xp.screen.rect(:,sideConceal + 3));
        Screen('DrawTexture', xp.screen.win, xp.image.texture{iStim(sideReveal),2}, [], xp.screen.rect(:,sideReveal + 1), 0, []);
        Screen('DrawTexture', xp.screen.win, xp.image.texture{iStim(sideReveal),1}, [], xp.screen.rect(:,sideReveal + 1), 0, [], thisContrast);
        Screen('Flip',xp.screen.win,[],0,1);
    end
end
s0 = GetSecs;
% animation
move = 0;
mchange = 10;
timeLastIn = GetSecs;
while GetSecs - s0 < 10
    roiFixated = fixCount(xp, [2 3], true, true);
    if roiFixated == sideReveal
        timeLastIn = GetSecs;
    end
    if GetSecs - timeLastIn < 0.1
        if move > 100 || move < 0
            mchange = -mchange;
        end
        move = move + mchange;
        Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
        Screen('DrawTexture', xp.screen.win, xp.image.texture{iStim(sideConceal),2}, [], xp.screen.rect(:,sideConceal + 1), 0, []);
        Screen('DrawTexture', xp.screen.win, xp.image.texture{3,1}, [], xp.screen.rect(:,sideConceal + 3));
        Screen('DrawTexture', xp.screen.win, xp.image.texture{iStim(sideReveal),1}, [], xp.screen.rect(:,sideReveal + 1) + [0 move 0 move]', 0, []);
        Screen('Flip',xp.screen.win,[],0);
    end
end
end