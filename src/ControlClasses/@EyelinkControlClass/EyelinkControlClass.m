classdef EyelinkControlClass < EyelinkControlClassBase
    %EYELINKCONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function eyelink = EyelinkControlClass(status)
            if nargin > 0 && status
                eyelink.init;
            end
        end
    end
end

