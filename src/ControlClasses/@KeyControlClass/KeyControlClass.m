classdef KeyControlClass < KeyControlClassBase
    %KEYCONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function keyboard = KeyControlClassBase(status)
            if nargin > 0 && status
                keyboard.init;
            end
        end
    end
end

