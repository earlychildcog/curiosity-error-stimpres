imagefolder = "curiosity-error-stimpres/stimuli/images/05-ObjTest";
image_metadata = cat(1,dir(fullfile(imagefolder,"*.png")).name);
image_metadata = image_metadata(:,[1 3 5 7]);

nImage = size(image_metadata,1);

cats = unique(image_metadata(:,1))';
nCat = numel(cats);

nSub = 4;
% image_count = zeros(nImage,1);
tableImage = array2table(image_metadata,VariableNames=["cat" "sub" "col" "id"]);
tableImage.idfull = (1:nImage)';
tableImage.count = zeros(nImage,1);
tableImage.last = zeros(nImage,1);

image_history = zeros(1000,4);
iTrial = 0;

%%
nTrial = 100;
verbose = true;
history = zeros(nTrial,3);
skill = 0.6;
scaling = 3;
kDiff = 1;
listDiff = ["easy", "medium", "hard", "xhard"];
success = zeros(1,3);
tic
for k=1:nTrial
    % pause(0.01)
    oldDiff = listDiff(kDiff);
    if all(success == 1) && kDiff < 4
        kDiff = kDiff + 1;
        success = zeros(1,3);
    elseif all(success == -1) && kDiff > 1
        kDiff = kDiff - 1;
        success = zeros(1,3);
    end
    if verbose
        fprintf("%3d:%s,\t",k,listDiff(kDiff))
    end
    tableImage = selectNextPair(tableImage, history(1:(k-1),:), listDiff(kDiff), oldDiff, verbose=verbose);
    success(1:2) = success(2:3);
    if rand() > (1-skill+skill*(((kDiff-1)/4)^scaling))
        success(3) = 1;
    else
        success(3) = -1;
    end
    history(k, :) = [tableImage.idfull(tableImage.last == 1)', kDiff];
end
toc
varfun(@sum, tableImage, InputVariables="count", GroupingVariables="cat")
disp(tableImage(tableImage.count == 0,:))

%%

flagplot = true;
if flagplot
    tl = tiledlayout(2,2)
    for k=1:4
        nexttile
        h = history(history(:,3) == k, 1:2);
        g = arrayfun(@(x)tableImage.cat(tableImage.idfull == x), h);
        histogram(uint8(g))
    end
end