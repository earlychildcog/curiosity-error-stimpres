function startrec(eyelink)
% start recording eyetracking data in the beginning of trial
if eyelink.status

    NtestTrials = eyelink.trial.varValue.trialno-(eyelink.trial.nTrial-49);
    if NtestTrials < 0
        NtestTrials = 0;
    end

    Eyelink('Message', 'TRIALID %d', eyelink.trial.varValue.trialID);
    % Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Simple Drawing
    %Eyelink('Message', '!V CLEAR %d %d %d', round(el.backgroundcolour(1)*255), round(el.backgroundcolour(1)*255), round(el.backgroundcolour(1)*255));        
    % Supply the trial number as a line of text on Host PC screen
    if strcmp(eyelink.trial.varValue.trialtype,'Test')
        Eyelink('Command', 'record_status_message "TRIAL %d/%d (%s trial; ID: %d; difficulty: %s) -- completed %d test trials"',...
            eyelink.trial.varValue.trialno, eyelink.trial.nTrial,...
            eyelink.trial.varValue.trialtype, eyelink.trial.varValue.trialID, eyelink.trial.varValue.difficulty, ...
            NtestTrials);
    else
        Eyelink('Command', 'record_status_message "TRIAL %d/%d (%s trial) -- completed %d test trials"',...
            eyelink.trial.varValue.trialno, eyelink.trial.nTrial,...
            eyelink.trial.varValue.trialtype, NtestTrials);
    end
    Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before drawing Host PC graphics and before recording        
    Eyelink('Command', 'clear_screen 0'); % Clear Host PC display from any previus drawing
    
    % right after attgetter priority
    Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before recording
    Eyelink('StartRecording'); % Start tracker recording
end