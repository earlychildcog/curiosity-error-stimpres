classdef SoundControlClass < SoundControlClassBase
    %SOUNDCONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods

        function sound = SoundControlClass(status)
            if nargin > 0 && status
                sound.init;
            end
        end
    end
end

