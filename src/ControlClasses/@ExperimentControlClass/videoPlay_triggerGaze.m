function result = videoPlay_triggerGaze(xp, rectID, volume)

if ~exist('rectID','var') || isempty(rectID)
    rectID = 0;
end
if ~exist('volume','var') || isempty(volume)
    volume = xp.sound.volume;
end
if volume>0
    volume_old = xp.sound.volume;
    xp.sound.volume = volume;
end
framedur = xp.framedur;
offset = xp.offset;
% newrect = round([(RECT(3:4)+RECT(1:2))/2-(RECT(3:4)-RECT(1:2))/8 (RECT(3:4)+RECT(1:2))/2+(RECT(3:4)+RECT(1:2))/8]);
% disp(newrect)
% disp(RECT)

%[mov, ~, ~, Movx, Movy] = Screen('OpenMovie', EXPWIN, movfile,4,-1,1,6);
xp.trial.videoName
movieInv = xp.trial.videoList{3}{2};
[mov, ~, ~, Movx, Movy] = Screen('OpenMovie', xp.screen.win, xp.trial.videoName,4,-1,1,6);
[mov2, ~, ~, Movx, Movy] = Screen('OpenMovie', xp.screen.win, movieInv,4,-1,1,6);

keyQ        = KbName('q');
keyP        = KbName('p');
keyC        = KbName('c');
keyB        = KbName('b');
keyD        = KbName('d');
keyA        = KbName('a');
SPACE       = KbName('space');

Screen('SetMovieTimeIndex', mov, 0);
Screen('PlayMovie', mov, 1,0,0);
frameNum = 0;
% PsychPortAudio('FillBuffer', pahandle, wav)
% PsychPortAudio('Volume',pahandle,0.8)
% PsychPortAudio('Start', pahandle);

if volume>0
    xp.sound.play;
end

mov1 = mov;

thisframe = 0;
StimulusOnsetTime = GetSecs();

el = xp.eyelink.settings;
eye_used = Eyelink('EyeAvailable');
if eye_used == el.BINOCULAR % if both eyes are tracked
    eye_used = el.LEFT_EYE; % use left eye
end


while 1
    [thisframe] = Screen('GetMovieImage', xp.screen.win, mov, 1, [], [], 1);
    if thisframe== -1
        mov = mov1;
        Screen('SetMovieTimeIndex', mov, 0);
        %Screen('PlayMovie', mov, 1,0,0);
        [thisframe] = Screen('GetMovieImage', xp.screen.win, mov, 1, [], [], 1);
%         PsychPortAudio('Stop', xp.sound.pahandle,0);
        if volume>0
            xp.sound.play;
        end
        frameNum = 0;
    elseif frameNum == 510
        Screen('SetMovieTimeIndex', mov2, Screen('GetMovieTimeIndex', mov));
        outcome = [0 0];
        while true
            if Eyelink( 'NewFloatSampleAvailable') > 0
                % get the sample in the form of an event structure
                evt = Eyelink( 'NewestFloatSample');
                if eye_used ~= -1 % do we know which eye to use yet?
                    % if we do, get current gaze position from sample
                    x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                    y = evt.gy(eye_used+1);
                    % do we have valid data and is the pupil visible?
                    fprintf("%.3f: %.0f %.0f",GetSecs - StimulusOnsetTime,x,y);
                    if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                        if y < 500
                            if x < 500
                                outcome(1) = outcome(1) + 1;
                                fprintf('L')
                            elseif x > 700
                                outcome(2) = outcome(2) + 1;
                                fprintf('R')
                            end
                        end
                    end
                    fprintf('\n')
                    if max(outcome) > 100
                        [~, state] = max(outcome);
                        break
                    end
                end
            end
        end
        if state == 2
            mov1 = mov;
            mov = mov2;
        elseif state == 1
        end
    end
    
    frameNum = frameNum + 1;
%     Screen('DrawTexture', EXPWIN, thisframe, [], newrect);
    xp.drawIm(thisframe,rectID)
    StimulusOnsetTime = xp.flip(StimulusOnsetTime + framedur - offset);
%     Screen('FillRect',EXPWIN,BACKCOLOR);
%     StimulusOnsetTime = Screen('Flip', EXPWIN, StimulusOnsetTime + framedur - offset);
%     disp(frameNum)
    %conditions for presentation to stop
%     if thisframe== -1     % Valid texture returned? A negative value means end of movie reached: 
%         mov = mov0;
%         [thisframe] = Screen('GetMovieImage', EXPWIN, mov, 1, [], [], 1);
% %                 PsychPortAudio('FillBuffer', pahandle, musicbreak');
%         %PsychPortAudio('Stop', pahandle,0);
%     end
    
    [keyIsDown,~,keyCode] = PsychHID('KbCheck', xp.keyboard.index);      %reads key pressed 
        
    if keyIsDown

        switch find(keyCode,1)

% skip video when SPACE key is pressed
            case SPACE
                result = 1;
                break

%Press C to calibrate again during break


% pause after the trial ends when P key is pressed. 
% TO DO: move trial to the end, or play again after if early enough

            case keyP
                result = 2;
                break
                
            case keyB
                result = 3;
                break

            case keyC
                result = 4;
                break

% stop experiment when Q key is pressed
            case keyQ
                result = -1;
                xp.trial.result = 'quit';
                return
        end
    end
    Screen('Close', thisframe);
end
% PsychPortAudio('Stop', pahandle,0);
Screen('PlayMovie', mov, 0);            % Done. Stop playback:
Screen('CloseMovie',mov);               % Close movie object:    
if volume>0
    xp.sound.stop;
    xp.sound.volume = volume_old;
end









