function [tableImage, idSelect] = selectNextPair(tableImage, history, difficulty, difficulty_past, opts)
arguments
    tableImage table
    history (:,4) double
    difficulty string {mustBeMember(difficulty, ["FamFlip" "FamEasy" "Easy" "Medium" "Hard" "xHard"])} = "Easy"
    difficulty_past string {mustBeMember(difficulty_past, ["FamFlip" "FamEasy" "Easy" "Medium" "Hard" "xHard"])} = "Easy"
    opts.verbose logical = false
end
loopselect = 0;
tableImage.incl = true(size(tableImage,1),1);
if difficulty ~= "FamFlip"
    idSelect = zeros(1,2);
    % do not repeat items
    if difficulty == "FamEasy" && ~isempty(history)
        history((history(:,4) ~= 0), :) = [];
    end
    if size(history,1) > 1
        tableImage.incl(ismember(tableImage.idfull, history(end-1:end,1:2))) = false;
    elseif size(history,1) == 1
        tableImage.incl(ismember(tableImage.idfull, history(end,1:2))) = false;
    end
else
    if isempty(history)
        history = zeros(2,4);
    end
end
%% Easy diff
if difficulty == "FamFlip"      % to fix
    categories = unique(tableImage.cat);
    nCat  =numel(categories);
    idSelect = zeros(2,nCat);
    for iCat = 1:nCat
        good = false;
        while ~good
            idSelect(:,iCat) = datasample(tableImage.idfull(tableImage.cat == categories(iCat)), 2, 'Replace', false);
            if diff(tableImage.sub(ismember(tableImage.idfull, idSelect(:,iCat)))) ~= 0 &&...
                    isempty(intersect(tableImage.sub(ismember(tableImage.idfull, history(:,iCat))), tableImage.sub(ismember(tableImage.idfull, idSelect(:,iCat)))))
                good = true;
            end
        end
    end
elseif difficulty == "Easy" || difficulty == "FamEasy"

    % remove colours repeated
    tableImage = exclude_nback(tableImage, history, "col", 2, 2);
    % check if some category is eliminated
    badCats = setdiff(tableImage.cat, tableImage.cat(tableImage.incl));
    % remove category repeated
    tableImage = exclude_nback(tableImage, history, "cat", 2, 2);
    % check if some category is eliminated
    badCats = [badCats; setdiff(tableImage.cat, tableImage.cat(tableImage.incl))];
    % make sure category has at least 2 different colours
    tableColCount = varfun(@(x)length(unique(x)) < 2, tableImage(tableImage.incl,:), "GroupingVariables","cat", "InputVariables","col");
    badCats = [badCats; tableColCount.cat(tableColCount.Fun_col)];
    tableImage.incl(ismember(tableImage.cat, badCats)) = false;

    % select lowest
    tableCount = varfun(@sum, tableImage(~any(tableImage.cat == badCats',2),:), InputVariables="count",GroupingVariables="cat");
    tableCount = sortrows(tableCount, "sum_count");
    minCount    = tableCount.sum_count(2)+2;
    tableCount = tableCount(tableCount.sum_count <= minCount, :);
    tableCount_ = tableCount;
    % catsGood = tableCount.cat(tableCount.sum_count <= minCount);
    while true
        % custom weights, in matlab only with replacement so we customise -- highest probability to lowest
        tableCount = tableCount_; % l4zy; for case of repeating
        catsSelect = datasample(tableCount.cat, 2, 'Replace', false, 'Weights', sum(tableCount.sum_count+1)./(tableCount.sum_count+1)');
        catsSelect = catsSelect(randperm(2)); %shuffle order so that it does not depend on frequencies
        oldColour = 0;
        % reduce table
        for iItem = 1:2
            cat_ = catsSelect(iItem);
            if isempty(cat_)
                error('no category options')
            end
            tableImage_ = tableImage(tableImage.cat == cat_ & tableImage.incl & tableImage.col ~= oldColour,:);     % look into the category only
            if isempty(tableImage_)
                tableImage_ = tableImage(tableImage.cat == cat_ & tableImage.incl,:);
                if isempty(tableImage_)
                    error('no item options')
                else
                    idSelect(2) = tableImage_.idfull(1);        % let's no pretend we make some important choice there, just repeat the drafting if deadlock, or output anything if it works
                    break
                end
            end
            tableImageTemp_ = exclude_nback(tableImage_, history, "sub", 1, 2);
            if isempty(tableImageTemp_)
                warning("subcategory repeating due to empty")
            else
                tableImage_ = tableImageTemp_;
            end
            tableCount = varfun(@sum, tableImage_, InputVariables="count",GroupingVariables="sub");
            tableCount = sortrows(tableCount, "sum_count");
            if isempty(tableCount)
                disp(1)
            end
            minCount = tableCount.sum_count(1)+2;
            tableCount(tableCount.sum_count > minCount,:) = [];     % remove frequent subcategories
            subSelect = datasample(tableCount.sub,1,'Weights', sum(tableCount.sum_count+1)./(tableCount.sum_count+1)'); % select subcategory
            tableImage_ = tableImage_(tableImage_.sub == subSelect,:);      % restrict to subcategory
            idSelect(iItem) = datasample(tableImage_.idfull,1,'Weights',1./(tableImage_.count+1)); % select item
            oldColour = tableImage_.col(tableImage_.idfull == idSelect(1));
        end
        theChosen = ismember(tableImage.idfull, idSelect);
        if diff(tableImage.col(theChosen)) ~= 0 || loopselect >= 100    % check if we have the same colour; if yes, repear; prob better than implementing it in code, in case of stalls
            % update older to original
            tableImage.last(tableImage.last > 0) = tableImage.last(tableImage.last > 0) + 1;
            tableImage.last(theChosen) = 1;
            tableImage.count(theChosen) = tableImage.count(theChosen) + 1;
            if loopselect == 50         % l0lz t00 l4zy
                disp("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
            end
            break
        else
            loopselect = loopselect + 1;
            % disp("loop")
        end
    end
    %% medium diff
elseif difficulty == "Medium"

    % remove colours repeated
    tableImage = exclude_nback(tableImage, history, "col", 2, 2);
    % remove past category, if not coming from Easy
    if difficulty_past ~= "Easy"
        tableImage = exclude_nback(tableImage, history, "cat", 1, 1);
    end
    % check if some category is eliminated
    badCats = setdiff(tableImage.cat, tableImage.cat(tableImage.incl));
    tableImage.incl(ismember(tableImage.cat, badCats)) = false;
    % make sure at least 2 subcategories exist in each category
    tableSubCount = varfun(@(x)length(unique(x)) < 2, tableImage(tableImage.incl,:), InputVariables="sub",GroupingVariables=["cat"]);
    badCats = [badCats; tableSubCount.cat(tableSubCount.Fun_sub)];
    tableImage.incl(ismember(tableImage.cat, badCats)) = false;
    % make sure category has at least 2 different colours
    tableColCount = varfun(@(x)length(unique(x)) < 2, tableImage(tableImage.incl,:), "GroupingVariables","cat", "InputVariables","col");
    badCats = [badCats; tableColCount.cat(tableColCount.Fun_col)];
    tableImage.incl(ismember(tableImage.cat, badCats)) = false;


    % select one of lowest categories
    tableCount = varfun(@sum, tableImage(~any(tableImage.cat == badCats',2),:), InputVariables="count",GroupingVariables="cat");
    tableCount = sortrows(tableCount, "sum_count");
    if size(tableCount,1) > 1
        minCount = tableCount.sum_count(2)+2;
        tableCount = tableCount(tableCount.sum_count <= minCount, :);
    end
    % catsGood = tableCount.cat(tableCount.sum_count <= minCount);

    % choose category weighting the least represented
    catSelect = datasample(tableCount.cat, 1, 'Weights', sum(tableCount.sum_count+1)./(tableCount.sum_count+1)');

    % select subcategories within the category (weighting the least represented)
    tableCountSub = varfun(@sum, tableImage(tableImage.cat == catSelect,:), InputVariables=["count" "incl"],GroupingVariables="sub");
    tableCountSub(tableCountSub.sum_incl == 0,:) = [];  % remove empty subcategories
    if size(tableCountSub,1) < 2
        disp(1)
    end
    while true
        subsSelect = datasample(tableCountSub.sub, 2, 'Replace', false, 'Weights', sum(tableCountSub.sum_count+1)./(tableCountSub.sum_count+1)');
        subsSelect = subsSelect(randperm(2)); %shuffle order so that it does not depend on frequencies
        oldColour = 0;
        % select item
        for iItem = 1:2
            % make a reduced table for item `iItem`
            cat_ = catSelect;
            sub_ = subsSelect(iItem);
            if isempty(cat_) || isempty(sub_)
                error('no (sub)category options')
            end
            tableImage_ = tableImage(tableImage.cat == cat_ & tableImage.sub == sub_ & tableImage.incl & tableImage.col ~= oldColour,:);     % look into the category only
            if isempty(tableImage_)
                tableImage_ = tableImage(tableImage.cat == cat_ & tableImage.sub == sub_ & tableImage.incl,:);
                if isempty(tableImage_)
                    error('no item options')
                else
                    idSelect(2) = tableImage_.idfull(1);        % let's no pretend we make some important choice there, just repeat the drafting if deadlock, or output anything if it works
                    break
                end
            end
            tableImage_(tableImage_.count > min(tableImage_.count)+2,:) = [];     % remove frequent items
            if isempty(tableImage_)
                disp(1)
            end
            idSelect(iItem) = datasample(tableImage_.idfull,1,'Weights',1./(tableImage_.count+1)); % select item
            oldColour = tableImage_.col(tableImage_.idfull == idSelect(1));
        end
        theChosen = ismember(tableImage.idfull, idSelect);
        if diff(tableImage.col(theChosen)) ~= 0 || loopselect >= 100    % check if we have the same colour; if yes, repear; prob better than implementing it in code, in case of stalls
            % update older to original
            tableImage.last(tableImage.last > 0) = tableImage.last(tableImage.last > 0) + 1;
            tableImage.last(theChosen) = 1;
            tableImage.count(theChosen) = tableImage.count(theChosen) + 1;
            if loopselect == 10000         % l0lz t00 l4zy
                disp("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
            end
            break
        else
            loopselect = loopselect + 1;
            % disp("loop")
        end
    end
elseif difficulty == "Hard"

    % remove colours repeated
    tableImage = exclude_nback(tableImage, history, "col", 2, 2);
    % remove past category, if not coming from Easy
    if difficulty_past ~= "Easy"
        tableImage = exclude_nback(tableImage, history, "cat", 1, 1);
    end
    % remove subcategories that have only one colour
    countColoursWithinSub = varfun(@(x)mean(x == x(1)) < 1, tableImage(tableImage.incl, :), GroupingVariables=["cat" "sub"], InputVariables="col");
    countColoursWithinSub.GroupCount = [];
    if size(outerjoin(tableImage, countColoursWithinSub, 'MergeKeys', true),1) ~= size(tableImage,1)
        warning("something wrong 1")
    end
    tableImage = outerjoin(tableImage, countColoursWithinSub, 'MergeKeys', true);
    tableImage.incl = tableImage.incl & tableImage.Fun_col;
    tableImage.Fun_col = [];
    % check if some category is eliminated
    badCats = setdiff(tableImage.cat, tableImage.cat(tableImage.incl));
    tableImage.incl(ismember(tableImage.cat, badCats)) = false;

    % select one of lowest categories
    tableCount = varfun(@sum, tableImage(~any(tableImage.cat == badCats',2),:), InputVariables="count",GroupingVariables="cat");
    tableCount = sortrows(tableCount, "sum_count");
    if size(tableCount,1) > 1
        minCount = tableCount.sum_count(2)+2;
        tableCount = tableCount(tableCount.sum_count <= minCount, :);
    elseif isempty(tableCount)
        warning("empty tableCount")
    end

    % choose category weighting the least represented
    catSelect = datasample(tableCount.cat, 1, 'Weights', sum(tableCount.sum_count+1)./(tableCount.sum_count+1)');

    % select subcategory within the category (weighting the least represented)
    tableCountSub = varfun(@sum, tableImage(tableImage.cat == catSelect,:), InputVariables=["count" "incl"],GroupingVariables="sub");
    tableCountSub(tableCountSub.sum_incl == 0,:) = [];  % remove empty subcategories
    subsSelect = datasample(tableCountSub.sub, 1, 'Replace', false, 'Weights', sum(tableCountSub.sum_count+1)./(tableCountSub.sum_count+1)');
    tableImage_ = tableImage(tableImage.cat == catSelect & tableImage.sub == subsSelect & tableImage.incl,:);     % look into the category only
    while loopselect < 100
        idSelect = datasample(tableImage_.idfull,2, 'Replace', false,'Weights',1./(tableImage_.count+1))'; % select item
        if diff(tableImage.col(ismember(tableImage.idfull, idSelect))) == 0
            loopselect = loopselect + 1;
        else
            break
        end
    end       
    theChosen = ismember(tableImage.idfull, idSelect);
    tableImage.last(tableImage.last > 0) = tableImage.last(tableImage.last > 0) + 1;
    tableImage.last(theChosen) = 1;
    tableImage.count(theChosen) = tableImage.count(theChosen) + 1;
    %% difficulty xhard
elseif difficulty == "xHard"

    % remove colours repeated: not twice in a row (unlike before)
    tableImage = exclude_nback(tableImage, history, "col", 1, 1);
    % remove past category, if not coming from Easy
    if difficulty_past ~= "Easy"
        tableImage = exclude_nback(tableImage, history, "cat", 1, 1);
    end
    % remove subcategories that do not have at least 2 items of the same colour
    countColoursWithinSub = varfun(@(x)max(groupcounts(x)) > 1, tableImage(tableImage.incl, :), GroupingVariables=["cat" "sub"], InputVariables="col");
    countColoursWithinSub.GroupCount = [];
    if size(outerjoin(tableImage, countColoursWithinSub, 'MergeKeys', true),1) ~= size(tableImage,1)
        warning("something wrong 1")
    end
    tableImage = outerjoin(tableImage, countColoursWithinSub, 'MergeKeys', true);
    tableImage.incl = tableImage.incl & tableImage.Fun_col;
    tableImage.Fun_col = [];
    % check if some category is eliminated
    badCats = setdiff(tableImage.cat, tableImage.cat(tableImage.incl));
    tableImage.incl(ismember(tableImage.cat, badCats)) = false;

    % select one of lowest categories
    tableCount = varfun(@sum, tableImage(~any(tableImage.cat == badCats',2),:), InputVariables="count",GroupingVariables="cat");
    tableCount = sortrows(tableCount, "sum_count");
    if size(tableCount,1) > 1
        minCount = tableCount.sum_count(2)+2;
        tableCount = tableCount(tableCount.sum_count <= minCount, :);
    elseif isempty(tableCount)
        warning("empty tableCount")
    end

    % choose category weighting the least represented
    catSelect = datasample(tableCount.cat, 1, 'Weights', sum(tableCount.sum_count+1)./(tableCount.sum_count+1)');

    % select subcategory within the category (weighting the least represented)
    tableCountSub = varfun(@sum, tableImage(tableImage.cat == catSelect,:), InputVariables=["count" "incl"],GroupingVariables="sub");
    tableCountSub(tableCountSub.sum_incl == 0,:) = [];  % remove empty subcategories
    subsSelect = datasample(tableCountSub.sub, 1, 'Replace', false, 'Weights', sum(tableCountSub.sum_count+1)./(tableCountSub.sum_count+1)');
    tableImage_ = tableImage(tableImage.cat == catSelect & tableImage.sub == subsSelect & tableImage.incl,:);     % look into the category only
    [a b] = groupcounts(tableImage_.col);
    b(a < 2) = [];
    tableImage_ = tableImage_(ismember(tableImage_.col, b), :);
    % ok this is a bit stupid, but what if in a subcategory there are two pairs of same colour? just making sure. Though I could also just simply pick a colour 
    while loopselect < 100
        idSelect = datasample(tableImage_.idfull,2, 'Replace', false,'Weights',1./(tableImage_.count+1))'; % select item
        if diff(tableImage.col(ismember(tableImage.idfull, idSelect))) ~= 0
            loopselect = loopselect + 1;
        else
            break
        end
    end       
    theChosen = ismember(tableImage.idfull, idSelect);
    tableImage.last(tableImage.last > 0) = tableImage.last(tableImage.last > 0) + 1;
    tableImage.last(theChosen) = 1;
    tableImage.count(theChosen) = tableImage.count(theChosen) + 1;
end
if opts.verbose
    fprintf('playing %c-%c-%c-%c.png, %c-%c-%c-%c.png @%d loops\n', tableImage{tableImage.last == 1, 1:4}', loopselect)
    if sum(tableImage.last == 1) == 1
        disp(1)
    end
end
end