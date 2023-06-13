classdef EegControlClass < EegControlClassBase
    properties
    end
    methods
        function  eeg = eegControlClass(status)

            if nargin == 0 || ~status
                return
            else
                eeg.init;
            end
        end
    end
end