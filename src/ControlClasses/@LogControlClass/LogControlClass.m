classdef LogControlClass < LogControlClassBase
% create logfiles for stimulus presentation scripts
% call: log = logfile(name, exp, header)
% where $name$ is a string
% $exp$ is a structure containing the experiment information
% and $header$ is a cell array of strings
% To write on file call $log.write(line)$
% where $line$ is also a cell array of stuff
    properties
    end
    methods
        function log = LogControlClass(pathFile, status)
            arguments
                pathFile string = string([])
                status logical = false
            end
            if ~isempty(pathFile)
                [folder, file, ext] = fileparts(pathFile);
                log.folder = folder;
                log.filename = file+ext;
            end
            if status
                log.init;
            end
        end
    end
end

