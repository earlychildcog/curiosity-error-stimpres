%check audio files

wordfolder = '.';
wordsubfs = dir(wordfolder);
wordsubfs = {wordsubfs(~contains({wordsubfs.name},'.')).name};

toplot = true;

for f = 1:size(wordsubfs,2)
    relpath = ['./' wordfolder '/' wordsubfs{f}];
    wfiles = dir([relpath '/*.wav']);
    wfiles = {wfiles.name};
    for sf = 1:size(wfiles,2)
        [audio, fs] = audioread([relpath '/' wfiles{sf}]);
        fprintf('audio file %s has %d channels and %d frequency with max channel aplitude',wfiles{sf}, min(size(audio)), fs);
        fprintf(' %.3f', max(audio))
        fprintf('\n')
        if toplot
            figure
            plot([1:length(audio)]/fs*1000, mean(audio,2));
            title(wfiles{sf})
            ylim([-1 1])
            xlabel('ms')
        end
%         word_array{f,sf} = mean(audio,2)';
    end
end