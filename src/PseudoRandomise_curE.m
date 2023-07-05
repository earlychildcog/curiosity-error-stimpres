%% Pseudorandomise the presentation for the curiosity error (1st) task:
%
% 1/ Familiarisation Flip trials (N = 2):
%    Randomly pick 2*8 items from the test trials items; pick the items so
%    that there are 2 items per category, all of different
%    colours, and each subcategory appers once per trial; their position is
%    randomised during the trial presentation (these trials sometimes
%    repeat so it's easier that way).
%
% 2/ Familiarisation Match trials (N = 24):
%    Randomly pair up items from the familiarisation trials items; pick the
%    items so that they all appear once every 6 trials, and pairs are made
%    of items from 2 different categories (no need to control for colour
%    here, and side is chosen during the trial presentation, that way fam M
%    trials always start with correct side on side opposite to bias)
%
% 3/ Test trials - Easy (N = 64):
%    Randomly pick pairs of items from different categories, different
%    colours. Make sure all subcategories (16) appear once per 8 trials,
%    and all items appear once per 32 trials.
%    Make sure the same subcategory does not appear twice in a row.
%    (But category and colour can repeat because we have too few; colour
%    can't repeat more than two trials in a row and cat is still
%    counterbalanced to appear once very 4 trials.)
%
% 4/ Test trials - Medium (N = 64):
%    Randomly pick pairs of items from the same category, different
%    subcategory, different colour. Make sure all subcategories (16) appear
%    once per 8 trials.
%    Make sure the same category and colour do not appear twice in a row.
%        -> not doing this last one, done in stimulus presentation script.
%
% 5/ Test trials - Hard (N = 48):
%    Randomly pick pairs of items of same subcat., different colour; pick
%    1 pair per subcategory, randomise side, make sure the same colour does
%    not appear twice in a row. 4 subcategories only have 1 colour, then
%    skip these ones. Make sure all other subcategories (12) appear once
%    per 12 trials.
%
% 6/ Test trials - xHard (N = 48):
%    Randomly pick pairs of items of same category and colour; pick 1 pair
%    per subcategory, randomise side, make sure the same colour does not
%    appear twice in a row. Make sure all subcategories (16) appear once.
%
%
%
% During the trial presentation: will pick from these pre-made trials and
% skip them if categories/colours repeat from one trial to the next when
% changing level, and will loop over them once they have all been used if
% necessary.
%
% Unsure: Presentation side is decided during the test trials (easier to
% control for side then as the levels change all the time).
%
% This is done once per subject (N = 399) and per session (N = 3) i.e. 1200
% times.
%
%


%% Define the parameters

clear all

NFamFlipTrials    = 2;   % Not using this number -- loop made with both trials at once
NFamMatchTrials   = 24;  % multiple of 3
NTestEasyTrials   = 64;  % multiple of 32
NTestMediumTrials = 64;  % multiple of 32
NTestHardTrials   = 48;  % multiple of 12 -- repeating over the same 12 trials with randomised order
NTestxHardTrials  = 48;  % multiple of 16 -- repeating over the same 16 trials with randomised order
NTotTr = NFamFlipTrials+NFamMatchTrials+NTestEasyTrials+NTestMediumTrials+NTestHardTrials+NTestxHardTrials;
testCatNum = ["A","F","O","V"];
FamCatNum  = ["A","O","P"];

%% Get the info on the available pool of stimuli

% TEST TRIALS STIMULI (and FamFlip)
% Get items file names from stimulus folder
folderTest    = '../stimuli/images/05-ObjTest/*.png';
fileNamesTest = arrayfun(@(x)string(x.name),dir(folderTest));
% Make a table with stimulus info (get it from file name)
tTest = table('VariableNames',{'fileName','category','subcategory','itemNb','colour'},...
    'Size',[length(fileNamesTest),5],'VariableTypes',{'string','string','double','double','string'});
tTest.fileName = fileNamesTest;
for iItem = 1:length(fileNamesTest)
    tTest.category(iItem)    = fileNamesTest{iItem,1}(1);
    tTest.subcategory(iItem) = str2double(fileNamesTest{iItem,1}(3));
    tTest.itemNb(iItem)      = str2double(fileNamesTest{iItem,1}(7));
    tTest.colour(iItem)      = fileNamesTest{iItem,1}(5);
end
[~,tTest.categoryNum] = find(tTest.category==testCatNum);
clear fileNamesTest folderTest

% Fam TRIALS STIMULI
% Get items file names from stimulus folder
folderFam    = '../stimuli/images/04-ObjFamMatch/*.png';
fileNamesFam = arrayfun(@(x)string(x.name),dir(folderFam));
% Make a table with stimulus info (get it from file name)
tFam = table('VariableNames',{'fileName','category','subcategory','itemNb','colour'},...
    'Size',[length(fileNamesFam),5],'VariableTypes',{'string','string','double','double','string'});
tFam.fileName = fileNamesFam;
for iItem = 1:length(fileNamesFam)
    tFam.category(iItem)    = fileNamesFam{iItem,1}(1);
    tFam.subcategory(iItem) = str2double(fileNamesFam{iItem,1}(3));
    tFam.itemNb(iItem)      = str2double(fileNamesFam{iItem,1}(7));
    tFam.colour(iItem)      = fileNamesFam{iItem,1}(5);
end
[~,tFam.categoryNum] = find(tFam.category==FamCatNum);
clear fileNamesFam folderFam


%% Loop over subjects and sessions
for iSession = 1:3
    for iSubj = 1:499

        %% ---- 1/ Get the familiarisation flip trials

        iCat = 0;
        while iCat < max(tTest.categoryNum)
            iCat             = iCat +1;
            flagKeepSampling = 1;
            iLoop         = 0;
            while flagKeepSampling
                iLoop = iLoop+1;
                % TRIAL 1
                % Pick first item from this category
                subcatPool = 1:4;
                subCat = randsample(subcatPool,1);
                itemNb = randsample(1:4,1);
                stimID.FamFlip(1,(iCat-1)*2+1)  = tTest.fileName(tTest.categoryNum==iCat & tTest.subcategory==subCat & tTest.itemNb==itemNb);
                stimCol.FamFlip(1,(iCat-1)*2+1) = tTest.colour(tTest.categoryNum==iCat & tTest.subcategory==subCat & tTest.itemNb==itemNb);
                subcatPool(subCat) = []; % take out the subcategory that was already chosen once
                % Pick second item for this category
                subCat = randsample(subcatPool,1);
                itemNb = randsample(1:4,1);
                stimID.FamFlip(1,(iCat-1)*2+2)  = tTest.fileName(tTest.categoryNum==iCat & tTest.subcategory==subCat & tTest.itemNb==itemNb);
                stimCol.FamFlip(1,(iCat-1)*2+2) = tTest.colour(tTest.categoryNum==iCat & tTest.subcategory==subCat & tTest.itemNb==itemNb);
                colours1 = unique(stimCol.FamFlip(1,:));
                subcatPool(subcatPool==subCat) = []; % take out the subcategory that was already chosen last

                % TRIAL 2
                % Pick first item from this category
                subCat = randsample(subcatPool,1);
                itemNb = randsample(1:4,1);
                stimID.FamFlip(2,(iCat-1)*2+1)  = tTest.fileName(tTest.categoryNum==iCat & tTest.subcategory==subCat & tTest.itemNb==itemNb);
                stimCol.FamFlip(2,(iCat-1)*2+1) = tTest.colour(tTest.categoryNum==iCat & tTest.subcategory==subCat & tTest.itemNb==itemNb);
                subcatPool(subcatPool==subCat) = []; % take out the subcategory that was already chosen once
                % Pick second item for this category
                subCat = subcatPool;
                itemNb = randsample(1:4,1);
                stimID.FamFlip(2,(iCat-1)*2+2)  = tTest.fileName(tTest.categoryNum==iCat & tTest.subcategory==subCat & tTest.itemNb==itemNb);
                stimCol.FamFlip(2,(iCat-1)*2+2) = tTest.colour(tTest.categoryNum==iCat & tTest.subcategory==subCat & tTest.itemNb==itemNb);
                colours2 = unique(stimCol.FamFlip(2,:));

                % If colours are not repeating, then move on, else: re-do sampling
                if length(unique(colours1))==length(stimCol.FamFlip(1,:)) && length(unique(colours2))==length(stimCol.FamFlip(2,:))
                    %          if length(unique(colours1))==length(stimCol.FamFlip1)
                    flagKeepSampling = 0;
                    % If sampling has been re-done 20 times and colours keep repeating:
                    % start over from category 1
                elseif iLoop>20
                    iCat             = 1;
                    iLoop         = 0;
                    stimCol.FamFlip  = strings;
                    stimID.FamFlip   = strings;
                    colours1         = strings;
                    colours2         = strings;
                end
            end
        end

        clear colours1 colours2 flagKeepSampling iCat iItem iLoop itemNb subCat subcatPool



        %% ---- 2/ Get the familiarisation match trials
        % Initialise
        catPool    = 1:3;
        subCatPool = 1:4;
        catTrAll   = [];
        iTrBatch   = 0;

        % -- a. Find category
        % Loop over groups of 3 trials (because we have 3 Fam Match categories)
        while iTrBatch < round(NFamMatchTrials/3)
            % Increment
            iTrBatch = iTrBatch + 1;
            % Pick category for first side, 3 trials
            catTr      = Shuffle(catPool)';
            % Pick category for second side, first trial (based on previous trials + other side same trial)
            catPoolR   = catPool; catPoolR(catPoolR==catTr(1,1)) = [];
            catTr(1,2) = randsample(catPoolR,1);
            % Pick category for second side, second trial
            catPoolR   = catPool; catPoolR(catPoolR==catTr(2,1)) = []; catPoolR(catPoolR==catTr(1,2)) = [];
            if length(catPoolR)==2
                catTr(2,2) = catTr(3,1);
            else
                catTr(2,2) = catPoolR;
            end
            % pick category for second side, third trial
            catPoolR   = catPool; idx = unique([find(catPoolR==catTr(3,1)), find(catPoolR==catTr(1,2)), find(catPoolR==catTr(2,2))]);
            catPoolR(idx) = [];
            %         if length(catPoolR)>1; sprintf('Issue with trial 3 side 2'); pause; end %FOR TROUBLESHOOTING
            catTr(3,2) = catPoolR;
            % Concatenate into var for all trials at once
            catTrAll   = [catTrAll;catTr];
        end

        % -- b. Find subcategory + save the stim in stimID variable
        subCatTrAll = nan(size(catTrAll)); stimID.FamMatch = strings(size(catTrAll));
        for iCat       = 1:3
            subCat     = [Shuffle(subCatPool),Shuffle(subCatPool),Shuffle(subCatPool),Shuffle(subCatPool)]';
            subCatTrAll(catTrAll==iCat) = subCat;
            iTrCurrCat = find(catTrAll==iCat);
            for iLoop = 1:length(iTrCurrCat)
                iAllSubCats = subCat(iLoop);
                stimID.FamMatch(iTrCurrCat(iLoop)) = tFam.fileName(tFam.categoryNum==iCat & tFam.subcategory==iAllSubCats);
            end
        end

        clear catPool catPoolR catTr catTrAll iCat idx iLoop iAllSubCats iTrBatch iTrCurrCat subCat subCatPool subCatTrAll


        %% ---- 3/ Get the test - easy trials

        % Initialise
        catPool    = 1:4;
        subCatPool = 1:4;
        catTrAll   = [];
        iTrBatch   = 0;


        % -- a. Find category

        % Loop over groups of 4 trials (because we have 4 categories)
        while iTrBatch < round(NTestEasyTrials/4)

            % Increment
            iTrBatch = iTrBatch + 1;

            % Pick category for first side, 4 trials
            catTr      = Shuffle(catPool)';
            % Pick category for second side, 1st trial (based on previous trials + other side same trial)
            catPoolR   = catPool; catPoolR(catPoolR==catTr(1,1)) = []; catPoolR(catPoolR==catTr(2,1)) = [];
            catTr(1,2) = randsample(catPoolR,1);
            % Pick category for second side, 2nd trial
            catPoolR   = catPool; catPoolR(catPoolR==catTr(2,1)) = []; catPoolR(catPoolR==catTr(1,2)) = [];
            catTr(2,2) = randsample(catPoolR,1);
            % Pick category for second side, 3rd trial
            catPoolR   = catPool; idx = unique([find(catPoolR==catTr(3,1)), find(catPoolR==catTr(1,2)), find(catPoolR==catTr(2,2))]);
            catPoolR(idx) = [];
            if ismember(catTr(4,1),catPoolR)
                catTr(3,2) = catTr(4,1); %avoid being stuck at the next trial if possible
            elseif length(catPoolR)==1
                catTr(3,2) = catPoolR;
            else
                catTr(3,2) = randsample(catPoolR,1);
            end
            % pick category for second side, 4th trial
            catPoolR   = catPool; idx = unique([find(catPoolR==catTr(4,1)), find(catPoolR==catTr(1,2)), ...
                find(catPoolR==catTr(2,2)), find(catPoolR==catTr(3,2))]);
            catPoolR(idx) = [];

            if isempty(catPoolR)
                % start over if combination impossible
                iTrBatch = iTrBatch-1;
                catTr = [];
            else
                catTr(4,2) = catPoolR;
                catTrAll   = [catTrAll,catTr']; % Concatenate into var for all trials at once
                % (Var organised in 2 lines so rest in counterbalanced properly as
                % Matlab counts indices column by column)
            end
        end

        clear idx catPoolR catTr iTrBatch


        % -- b. Find subcategory + colour + save the stim in stimID variable

        subCatTrAll = nan(size(catTrAll)); itemNbTrAll = nan(size(catTrAll));
        stimID.TestEasy = strings(size(catTrAll)); stimCol.TestEasy = strings(size(catTrAll));

        iCat      = 0;
        iLoopRun2 = 0;
        while iCat < 4

            iCat       = iCat +1;
            iTrCurrCat = find(catTrAll==iCat);

            % Pick subcat (N=4) by groups of N trials of the current cat (N2 = 4)
            iLoopRun  = 0;
            subCat    = [];
            while iLoopRun < round(NTestEasyTrials/(4*2))
                iLoopRun = iLoopRun + 1;
                subCat = [subCat,Shuffle(subCatPool)];
                % Check that don't have same subcat twice in a row, else re-draw
                if length(subCat) > 4 && subCat(end-4) == subCat(end-3)
                    subCat(end-3:end) = [];
                    iLoopRun = iLoopRun-1;
                end
            end
            subCatTrAll(catTrAll==iCat) = subCat;

            % Now get the item # (1:4) and check that we don't have the same colour
            % twice per trial or twice in row

            iLoopRun  = 0;
            iAllSubCats   = 0;
            flagKeepSampling2 = true;

            while flagKeepSampling2

                iAllSubCats       = iAllSubCats +1;
                iTrCurrSubcat = find(subCatTrAll==iAllSubCats & catTrAll==iCat);
                itemNb        = [Shuffle(1:4),Shuffle(1:4)];
                itemNbTrAll(iTrCurrSubcat) = itemNb;

                iItem        = 0;

                flagKeepSampling = true;
                while flagKeepSampling

                    iItem    = iItem + 1;

                    stimID.TestEasy(iTrCurrSubcat(iItem))  = tTest.fileName(tTest.categoryNum==iCat ...
                        & tTest.subcategory==iAllSubCats & tTest.itemNb==itemNb(iItem));
                    stimCol.TestEasy(iTrCurrSubcat(iItem)) = tTest.colour(tTest.categoryNum==iCat ...
                        & tTest.subcategory==iAllSubCats & tTest.itemNb==itemNb(iItem));
                    iCol = ceil(iTrCurrSubcat(iItem)/2); %get col #

                    % Check if colour repeats within a trial
                    currTrialArray  = stimCol.TestEasy(:,iCol);
                    flagBadDraw     = length(unique(currTrialArray(~cellfun(@isempty,currTrialArray)))) ...
                        < sum(~cellfun(@isempty,currTrialArray),'all');
                    % Start over for current subcat if bad draw (colour repeats)
                    if flagBadDraw
                        iItem    = 0;
                        iAllSubCats  = iAllSubCats-1;
                        iLoopRun = iLoopRun+1;
                        itemNbTrAll(iTrCurrSubcat)      = NaN;
                        stimID.TestEasy(iTrCurrSubcat)  = strings;
                        stimCol.TestEasy(iTrCurrSubcat) = strings;
                        flagKeepSampling                = false;
                        % Start over from 1st subcat if cannot get a good draw for this subcat after 20 runs
                        if iLoopRun > 15
                            iAllSubCats   = 0;
                            iCat      = iCat - 1;
                            itemNbTrAll                  = NaN;
                            stimID.TestEasy(iTrCurrCat)  = strings;
                            stimCol.TestEasy(iTrCurrCat) = strings;
                            flagKeepSampling2            = false;
                            iLoopRun2 = iLoopRun2 +1;
                            flagKeepSampling2 = false;
                        end
                        % Exit loop if done with this
                    elseif iItem == length(itemNb)
                        iLoopRun  = 0;
                        flagKeepSampling = false;
                    end
                end

                % Start over from 1st cat if cannot get a good draw for this cat after 20 runs
                if iLoopRun2 > 20
                    iCat      = 0;
                    iAllSubCats   = 0;
                    iItem     = 0;
                    iLoopRun2 = 0;
                    itemNbTrAll      = NaN;
                    stimID.TestEasy  = strings;
                    stimCol.TestEasy = strings;
                    flagKeepSampling2 = false;
                    % Exit loop if done with this
                elseif iAllSubCats == 4 && sum(cellfun(@isempty,stimID.TestEasy(iTrCurrSubcat)))==0
                    iAllSubCats   = 0;
                    iLoopRun2 = 0;
                    flagKeepSampling2 = false;
                end

            end

        end

        stimID.TestEasy = stimID.TestEasy'; % 1 trial per line as in csv file

        if sum(cellfun(@isempty,stimID.TestEasy(iTrCurrSubcat)))
            sprintf('problem: some Easy trials are empty')
            pause;
        end

        clear catPool catTrAll currTrialArray flagBadDraw flagKeepSampling flagKeepSampling2 iCat iCol iItem ...
            iLoopRun iLoopRun2 iAllSubCats itemNb itemNbTrAll iTrCurrCat iTrCurrCat subCat subCatPool subCatTrAll



        %% 4/ Test trials - Medium (N = 64):

        % Initialise
        catPool    = 1:4;
        subCatPool = 1:4;
        catTrAll   = [];
        iTrBatch   = 0;


        % -- a. Find category

        % Loop over groups of 4 trials (because we have 4 categories)
        for iTrBatch = 1:round(NTestMediumTrials/4)

            % Increment
            iTrBatch = iTrBatch + 1;

            % Pick category for first side, 4 trials
            catTr    = Shuffle(catPool)';
            % Copy into second side
            catTr    = [catTr,catTr];
            % Save together
            catTrAll = [catTrAll,catTr']; % Concatenate into var for all trials at once
            % (Var organised in 2 lines so rest in counterbalanced properly as
            % Matlab counts indices column by column)
        end

        clear catTr iTrBatch


        % -- b. Find subcategory + colour + save the stim in stimID variable

        subCatTrAll = nan(size(catTrAll)); itemNbTrAll = nan(size(catTrAll));
        stimID.TestMedium = strings(size(catTrAll)); stimCol.TestMedium = strings(size(catTrAll));

        iCat      = 0;
        iLoopRun2 = 0;
        while iCat < 4

            iCat       = iCat +1;
            iTrCurrCat = find(catTrAll==iCat);

            % Pick subcat (N=4) by groups of N trials of the current cat (N2 = 4)
            iLoopRun  = 0;
            subCat    = [];
            for iLoopRun = 1:round(NTestMediumTrials/(4*2))
                subCat = [subCat,Shuffle(subCatPool)];
            end
            subCatTrAll(catTrAll==iCat) = subCat;

            % Now get the item # (1:4) and check that we don't have the same colour
            % twice per trial

            iLoopRun  = 0;
            iAllSubCats   = 0;
            flagKeepSampling2 = true;

            while flagKeepSampling2

                iAllSubCats       = iAllSubCats +1;
                iTrCurrSubcat = find(subCatTrAll==iAllSubCats & catTrAll==iCat);
                itemNb        = [Shuffle(1:4),Shuffle(1:4)];
                itemNbTrAll(iTrCurrSubcat) = itemNb;

                iItem        = 0;

                flagKeepSampling = true;
                while flagKeepSampling

                    iItem    = iItem + 1;

                    stimID.TestMedium(iTrCurrSubcat(iItem))  = tTest.fileName(tTest.categoryNum==iCat ...
                        & tTest.subcategory==iAllSubCats & tTest.itemNb==itemNb(iItem));
                    stimCol.TestMedium(iTrCurrSubcat(iItem)) = tTest.colour(tTest.categoryNum==iCat ...
                        & tTest.subcategory==iAllSubCats & tTest.itemNb==itemNb(iItem));
                    iCol = ceil(iTrCurrSubcat(iItem)/2); %get col #

                    % Check if colour repeats within a trial
                    currTrialArray  = stimCol.TestMedium(:,iCol);
                    flagBadDraw     = length(unique(currTrialArray(~cellfun(@isempty,currTrialArray)))) ...
                        < sum(~cellfun(@isempty,currTrialArray),'all');
                    % Start over for current subcat if bad draw (colour repeats)
                    if flagBadDraw
                        iItem    = 0;
                        iAllSubCats  = iAllSubCats-1;
                        iLoopRun = iLoopRun+1;
                        itemNbTrAll(iTrCurrSubcat)        = NaN;
                        stimID.TestMedium(iTrCurrSubcat)  = strings;
                        stimCol.TestMedium(iTrCurrSubcat) = strings;
                        flagKeepSampling                  = false;
                        % Start over from 1st subcat if cannot get a good draw for this subcat after 20 runs
                        if iLoopRun > 15
                            iAllSubCats   = 0;
                            iCat      = iCat - 1;
                            itemNbTrAll                    = NaN;
                            stimID.TestMedium(iTrCurrCat)  = strings;
                            stimCol.TestMedium(iTrCurrCat) = strings;
                            flagKeepSampling2              = false;
                            iLoopRun2 = iLoopRun2 +1;
                            flagKeepSampling2 = false;
                        end
                        % Exit loop if done with this
                    elseif iItem == length(itemNb)
                        iLoopRun  = 0;
                        flagKeepSampling = false;
                    end
                end

                % Start over from 1st cat if cannot get a good draw for this cat after 20 runs
                if iLoopRun2 > 20
                    iCat      = 0;
                    iAllSubCats   = 0;
                    iLoopRun2 = 0;
                    itemNbTrAll      = NaN;
                    stimID.TestMedium  = strings;
                    stimCol.TestMedium = strings;
                    flagKeepSampling2 = false;
                    % Exit loop if done with this
                elseif iAllSubCats == 4 && sum(cellfun(@isempty,stimID.TestMedium(iTrCurrSubcat)))==0
                    iAllSubCats  = 0;
                    iLoopRun2 = 0;
                    flagKeepSampling2 = false;
                end

            end
        end

        stimID.TestMedium = stimID.TestMedium'; % 1 trial per line as in csv file

        if sum(cellfun(@isempty,stimID.TestMedium(iTrCurrSubcat)))
            sprintf('problem: some Medium trials are empty')
            pause;
        end

        clear catPool catTrAll currTrialArray flagBadDraw flagKeepSampling flagKeepSampling2 iCat iCol iItem ...
            iLoopRun iLoopRun2 iAllSubCats itemNb itemNbTrAll iTrCurrCat iTrCurrCat subCat subCatPool subCatTrAll



        %% 5/ Test trials - Hard (N = 48):

        % Initialise
        subCatPool  = 1:4*4;
        iTemPool    = 1:4;
        subcatTrAll = [];

        % Delete the subcategories for which items are always of the same colour
        for iAllSubCats = 1:4*4
            % Initialise
            poolSame = [];
            poolDiff = [];
            % figure out current values
            iCat    = ceil(iAllSubCats/4);
            iSubCat = rem(iAllSubCats-1,4)+1;
            iTrCurrSubcat = tTest.category==testCatNum(iCat) & tTest.subcategory==iSubCat;
            currColours   = unique(tTest.colour(iTrCurrSubcat));
            flagKeepThisColour = length(currColours) > 1;
            % Delete the subcategory if needed
            if ~flagKeepThisColour
                subCatPool(subCatPool==iAllSubCats) = [];
                % If not, figure out which items are of the same colour and which aren't
            else
                colCurrSubCat = tTest.colour(iTrCurrSubcat);
                for iItem = 1:4
                    currTrItemNb = tTest.itemNb(iTrCurrSubcat);
                    if sum(tTest.colour(iTrCurrSubcat)==colCurrSubCat(iItem))>1
                        poolSame = [poolSame, currTrItemNb(iItem)];
                    else
                        poolDiff = [poolDiff, currTrItemNb(iItem)];
                    end
                end
                poolSameColItems(iAllSubCats,:) = poolSame;
                poolDiffColItems(iAllSubCats,:) = poolDiff;
            end

        end

        % Pick the subcategory
        for iLoop = 1:round(NTestHardTrials/length(subCatPool))
            subcatTr    = Shuffle(subCatPool);
            subcatTrAll = [subcatTrAll;subcatTr'];
        end
        subcatTrAll = [subcatTrAll,subcatTrAll];

        % Pick the items
        stimID.TestHard = strings(size(subcatTrAll)); stimCol.TestHard = strings(size(subcatTrAll));
        itemNbTrAll = nan(size(subcatTrAll));
        for iLoop = 1:length(subCatPool)
            iCat           = ceil(subCatPool(iLoop)/4);
            iSubCatNb      = subCatPool(iLoop);
            iSubCat        = rem(subCatPool(iLoop)-1,4)+1;
            iTrCurrSubcat  = subcatTrAll==iSubCatNb;
            itemNbBoth     = [];
            % Always pick one item of those which are the same colour, and ne of
            % those which are different colours so never get twice the same colour
            % drawn.
            for iTr = 1:ceil(sum(iTrCurrSubcat)/2)
                itemTr     = [Shuffle(poolSameColItems(iSubCatNb,:))',Shuffle(poolDiffColItems(iSubCatNb,:))'];
                itemNbBoth = [itemNbBoth;itemTr];
            end
            itemNbTrAll(iTrCurrSubcat) = itemNbBoth;
            if length(itemNbTrAll) > length(subcatTrAll)
                itemNbTrAll(end) = [];
            end
            % NOW SAVE EVERYTHING
            iTrCurrSubcat = find(iTrCurrSubcat);
            for iTr = 1:numel(iTrCurrSubcat)
                iItem = itemNbTrAll(iTrCurrSubcat(iTr));
                stimID.TestHard(iTrCurrSubcat(iTr))  = tTest.fileName(tTest.categoryNum==iCat ...
                    & tTest.subcategory==iSubCat & tTest.itemNb==iItem);
                stimCol.TestHard(iTrCurrSubcat(iTr)) = tTest.colour(tTest.categoryNum==iCat ...
                    & tTest.subcategory==iSubCat & tTest.itemNb==iItem);
            end
        end

        clear colCurrSubCat currColours flagKeepThisColour iAllSubCats iCat iItem iLoop iSubCat iSubCatNb itemNbBoth ...
            itemNbTrAll iTemPool itemTr iTr iTrCurrSubcat poolDiff poolDiffColItems poolSame subCatPool subcatTr subcatTrAll



        %% 6/ Test trials - xHard (N = 48):
        %    Randomly pick pairs of items of same category and colour; pick 1 pair
        %    per subcategory, randomise side, make sure the same colour does not
        %    appear twice in a row. Make sure all subcategories (16) appear once.

        % Initialise
        subCatPool  = 1:4*4;
        subcatTrAll = [];

        % Pick 2 items for subcat which have all 4 items of the same colour
        iSubCatAllSameCol = find(poolSameColItems(:,1)==0);
        for iCat = iSubCatAllSameCol'
            poolSameColItems(iCat,:) = randsample(1:4,2);
        end

        % Pick the subcategory
        for iLoop = 1:round(NTestxHardTrials/length(subCatPool))
            subcatTr    = Shuffle(subCatPool);
            subcatTrAll = [subcatTrAll;subcatTr'];
        end
        subcatTrAll = [subcatTrAll,subcatTrAll];

        % Pick the items (don't have a choice really)
        stimID.TestxHard = strings(size(subcatTrAll)); stimCol.TestxHard = strings(size(subcatTrAll));
        for iSubCatNb = 1:numel(subCatPool)
            iTrCurrSubcat = find(subcatTrAll(:,1)==iSubCatNb);
            iCat          = ceil(iSubCatNb/4);
            iSubCat       = rem(iSubCatNb-1,4)+1;
            iItem         = poolSameColItems(iSubCatNb,:);
            for iTr = 1:numel(iTrCurrSubcat)
                for iSide = 1:2
                    stimID.TestxHard(iTrCurrSubcat(iTr),iSide)  = tTest.fileName(tTest.categoryNum==iCat ...
                        & tTest.subcategory==iSubCat & tTest.itemNb==iItem(iSide));
                    stimCol.TestxHard(iTrCurrSubcat(iTr),iSide) = tTest.colour(tTest.categoryNum==iCat ...
                        & tTest.subcategory==iSubCat & tTest.itemNb==iItem(iSide));
                end
            end
        end



        %% Now save everything into a csv file for this subject and session

        varNames = {'TrialType', 'Difficulty', 'obj1', 'obj2', 'obj3', 'obj4', 'obj5', 'obj6', 'obj7', 'obj8'};
        varTypes = repmat({'string'},size(varNames));
        T        = table('Size',[NTotTr,10],'VariableTypes',varTypes,'VariableNames',varNames);

        % Fam Flip
        array = [1, NFamFlipTrials];
        T.TrialType(1:NFamFlipTrials)   = 'FamFlip';
        T.Difficulty(1:NFamFlipTrials)  = 'FamFlip';
        T(array(1):array(2),3:end)      = cellstr(stimID.FamFlip);
        % Fam Match
        array = [array(1)+NFamFlipTrials, array(2)+NFamMatchTrials];
        T.TrialType(array(1):array(2))  = 'FamMatch';
        T.Difficulty(array(1):array(2)) = 'FamEasy';
        T(array(1):array(2),3:4)      = cellstr(stimID.FamMatch);
        % Test Easy
        array = [array(1)+NFamMatchTrials, array(2)+NTestEasyTrials];
        T.TrialType(array(1):end)       = 'Test';
        T.Difficulty(array(1):array(2)) = 'Easy';
        T(array(1):array(2),3:4)      = cellstr(stimID.TestEasy);
        % Test Medium
        array = [array(1)+NTestEasyTrials, array(2)+NTestMediumTrials];
        T.Difficulty(array(1):array(2)) = 'Medium';
        T(array(1):array(2),3:4)      = cellstr(stimID.TestMedium);
        % Test Hard
        array = [array(1)+NTestMediumTrials, array(2)+NTestHardTrials];
        T.Difficulty(array(1):array(2)) = 'Hard';
        T(array(1):array(2),3:4)      = cellstr(stimID.TestHard);
        % Test xHard
        array = [array(1)+NTestHardTrials, array(2)+NTestxHardTrials];
        T.Difficulty(array(1):array(2)) = 'xHard';
        T(array(1):array(2),3:4)      = cellstr(stimID.TestxHard);

        filename = sprintf('../rand/StimOrder_Subj%03d_Session%d.csv',iSubj,iSession);
        writetable(T, filename);



    end
end