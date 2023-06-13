classdef ExperimentControlClass < ExperimentControlClassBase
    % Some description
    properties
    end
    
    methods
        function xp = ExperimentControlClass(status)
            
            xp.image    = ImageControlClass;
            xp.screen   = ScreenControlClass;
            xp.eyelink  = EyelinkControlClass;
            xp.eeg      = EegControlClass;
            xp.sound    = SoundControlClass;
            xp.keyboard = KeyControlClass;
            xp.trial    = TrialControlClass;
            xp.log      = LogControlClass;
            if nargin == 0 || ~status
                return
            else
                xp.init
            end
        end
    end
end