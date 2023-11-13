
function [tableStimTest, tableStimFam, history] = setupTableStim()
imagefolder_fam = "stimuli/images/04-ObjFamMatch";
imagefolder_test = "stimuli/images/05-ObjTest";

tableStimTest = gettable(imagefolder_test);
tableStimFam = gettable(imagefolder_fam);


history = zeros(1000,4);
    function tableStim = gettable(imagefolder)
        image_metadata = cat(1,dir(fullfile(imagefolder,"*.png")).name);
        image_metadata = image_metadata(:,[1 3 5 7]);
        nImage = size(image_metadata,1);
        cats = unique(image_metadata(:,1))';
        nCat = numel(cats);
        nSub = 4;
        % image_count = zeros(nImage,1);
        tableStim = array2table(image_metadata,VariableNames=["cat" "sub" "col" "id"]);
        tableStim.idfull = (1:nImage)';
        tableStim.count = zeros(nImage,1);
        tableStim.last = zeros(nImage,1);
    end
end