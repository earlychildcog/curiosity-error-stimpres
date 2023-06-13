classdef ScreenControlClass < ScreenControlClassBase
    % some description to come
    properties
    end
    methods

        function screen = ScreenControlClass(status)
            if nargin > 0 && status
                screen.init;
            end
        end
    end
end