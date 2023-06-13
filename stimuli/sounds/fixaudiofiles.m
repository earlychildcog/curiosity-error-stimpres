% script to fix audio files
% Fixes included:
% converts to mono in a proper way:
%   a. if both channels contain sound data, it merges them (averaging)
%   b. if one channel is essentiall empty, it deletes it
% it fixes the frequency to $fs_default

fs_default = 48000;
amplthress = 0.01;

folder = '.';
subfolders = dir(folder);
subfolders = {subfolders(~contains({subfolders.name},'.')).name};


for f = 1:size(subfolders,2)
    relpath = ['./' folder '/' subfolders{f}];
    wfiles = dir([relpath '/*.wav']);
    wfiles = {wfiles.name};
    for sf = 1:size(wfiles,2)
        [audio, fs] = audioread([relpath '/' wfiles{sf}]);
        fprintf('audio file %s has %d channels and %d frequency with max channel aplitude',wfiles{sf}, min(size(audio)), fs);
        fprintf(' %.3f', max(audio))
        fprintf('\n')
        changed = false;
        if min(size(audio)) == 2
            changed = true;
            if max(abs(audio(:,2))) < amplthress
                audio(:,2) = [];
            elseif max(abs(audio(:,1))) < amplthress
                audio(:,1) = [];
            else
                audio = mean(audio,2);
            end
        end
        if fs ~= fs_default
            changed = true;
            [P, Q] = rat(fs_default/fs);
            abs(P/Q*fs/fs_default);
            audio = resample(audio,P,Q);
            fs = fs_default;
        end
        if changed
            audiowrite([relpath '/' wfiles{sf}], audio, fs)
        end
%         word_array{f,sf} = mean(audio,2)';
    end
end