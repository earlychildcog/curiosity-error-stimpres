function tableTest = selectNextObject(tableTest, difficulty)
% takes the scaling table and the difficulty, and decides which trial to play
% all information about which trials have been played lies in the scaling table
% Needed table variables:
% played last: 0 not played in previous trial, 1 played, objL top, 2 played and objR top
% thisDiff = strcmp(tableTest.Difficulty, difficulty);     % get rows of same difficulty
% minplayed = min(tableTest.playedTimes(thisDiff));        % find which is the minimum number of rounds played
% maxplayed = max(tableTest.playedTimes(thisDiff));        % find which is the maximum number of rounds played
% iRows = find(thisDiff & tableTest.playedTimes == minplayed); % which rows have this difficulty AND have been played the least within that difficulty (or none at all)
% count = 1;
% iRow = iRows(count);

assert(sum(tableTest.playing>0) <= 1, 'should be at most one row marked as "played last"')

tableTest.catL = extractBetween(tableTest.objL, 1,1);
tableTest.catR = extractBetween(tableTest.objR, 1,1);
tableTest.subcatL = extractBetween(tableTest.objL, 1,3);
tableTest.subcatR = extractBetween(tableTest.objR, 1,3);
% if any(tableTest.playing>0)
% rowsIn = tableTest.catL == extractBetween(tableTest{tableTest.playing>0, 2+tableTest.playing(tableTest.playing>0)},1,1);

if endsWith(difficulty, "Hard")     % if hard do not repeat general category
    nCharCategory = 1;
else                                % if not hard, do not repeat specific subcategory
    nCharCategory = 3;
end

if any(tableTest.playing>0) % if we have played a trial, we have check not to repeat category
    % now the serious check if we replay category
    % old and new categories
    categoriesLast = extractBetween(tableTest{tableTest.playing>0, ["objL" "objR"]}, 1,nCharCategory);
    % categoriesNow = extractBetween(tableTest{iRow, ["objL" "objR"]}, 1,nCharCategory);
    colourLast = extractBetween(tableTest{tableTest.playing>0, ["objL" "objR"]}, 5,5);
    % colourNow = extractBetween(tableTest{iRow, ["objL" "objR"]}, 5,5);

    rowsIn = tableTest.Difficulty == difficulty & ~(startsWith(tableTest.objL, categoriesLast) | startsWith(tableTest.objR, categoriesLast)...
        | any(extractBetween(tableTest.objL, 5,5) == colourLast,2) | any(extractBetween(tableTest.objR, 5,5) == colourLast,2));
    tableShort = tableTest(rowsIn, :);
    % choose category
    c1 = varfun(@(x)sum(x(:,1)), tableTest, GroupingVariables="catL", InputVariables="playedTimes");
    c2 = varfun(@(x)sum(x(:,2)), tableTest, GroupingVariables="catR", InputVariables="playedTimes");
    c = outerjoin(c1,c2, 'LeftKeys','catL','RightKeys','catR');
    tableCat = table;
    tableCat.cat = c.catL;
    tableCat.cat(ismissing(tableCat.cat)) = c.catR(ismissing(tableCat.cat));
    tableCat.playedTimes = sum([c.Fun_playedTimes_c1 c.Fun_playedTimes_c2],2,'omitnan');


    catCandidates = tableCat.cat(tableCat.playedTimes <= min(tableCat.playedTimes)+1)';
    catCandidates = catCandidates(randperm(length(catCandidates)));         % ADD THE REST
    catRest = setdiff(tableCat.cat', catCandidates);
    catRest = catRest(randperm(length(catRest)));
    catCandidates = [catCandidates, catRest];
    % subcat
    c1 = varfun(@(x)sum(x(:,1)), tableTest, GroupingVariables="subcatL", InputVariables="playedTimes");
    c2 = varfun(@(x)sum(x(:,2)), tableTest, GroupingVariables="subcatR", InputVariables="playedTimes");
    c = outerjoin(c1,c2, 'LeftKeys','subcatL','RightKeys','subcatR');
    tableSubat = table;
    tableSubat.cat = c.subcatL;
    tableSubat.cat(ismissing(tableSubat.cat)) = c.subcatR(ismissing(tableSubat.cat));
    tableSubat.playedTimes = sum([c.Fun_playedTimes_c1 c.Fun_playedTimes_c2],2,'omitnan');

    flagChosen = false;
    % go through categories
    % pick a category (one of the least represented)
    % within each category, go through eligible subcategories, starting from the one(s) playes less
    % if nothing found, repeat
    for thisCat = catCandidates
        tableSelection = tableSubat(startsWith(tableSubat.cat, thisCat), :);        % randomise the order of rows??
        while ~isempty(tableSelection)
            [~, I] = min(tableSelection.playedTimes);
            pick = tableSelection.cat(I);
            pick_valid = startsWith(tableShort.objL,pick) | startsWith(tableShort.objR,pick);
            if any(pick_valid)
                this_pick = find(pick_valid);
                this_pick = this_pick(randperm(length(this_pick)));
                this_pick = this_pick(1);
                ID = tableShort.trialID(this_pick);
                flagChosen = true;
                break
            end
            tableSelection(I,:) = [];
        end
        if flagChosen
            break
        end
    end

    if flagChosen
        iRow = find(tableTest.trialID == ID,1);
        sideTop = startsWith(tableTest.objL(iRow), pick) + 2*startsWith(tableTest.objR(iRow), pick);       % EXPAnD -- 1 or 2
        if sideTop > 2  % if extra hard???
            sideTop = randi(2);
        elseif sideTop == 0
            warning("Something wrong in randomisation, side not found; set to random")
            sideTop = randi(2);
        end
    else
        warning("trial not selected, picking random")
        ID = tableShort.trialID(randi(size(tableShort,1)));
        iRow = find(tableTest.trialID == ID,1);
        sideTop = randi(2);
    end
else
    iRow = find(tableTest.Difficulty == difficulty,1);
    sideTop = randi(2);
end

sides = ["L" "R"];
% we set things up for trial to play
tableTest.playedTimes(iRow,sideTop) = tableTest.playedTimes(iRow,sideTop) + 1;
tableTest.playing(tableTest.playing>0) = 0;     % reset the previous trial
tableTest.playing(iRow) = sideTop;              % set new trial
tableTest.objT(iRow) = tableTest.("obj" + sides(sideTop))(iRow);
end