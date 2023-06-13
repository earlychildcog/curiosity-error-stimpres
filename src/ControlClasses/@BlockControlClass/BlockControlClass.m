classdef BlockControlClass < handle
    %TRIALCONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        status                      logical = false
        no                                  = 0;
        type                                = '';
        condition                           = '';
        stimtype                            = '';
        stimname                            = '';
        stimdur                             = [];
        isi                                 = 0;
        fullpath                            = '';
        attget;
        videoList
        videoName
        sequence                            = [];
        currstim
        blockTrial                          = 0;
        blockTrialN
        new = true;

%         trial               TrialControlClass       = TrialControlClass   % trial settings
    end
    
    methods
        function block = BlockControlClass
        end
        
        function next(block)
            block.blockTrial = 1;  
            block.no = block.no + 1;
            block.currstim = block.sequence{block.no};
        end

        function delete(block)
        end
    end
end

