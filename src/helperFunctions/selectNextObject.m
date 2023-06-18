function [tableTest, side] = selectNextObject(tableTest, difficulty)
% takes the scaling table and the difficulty, and decides which trial to play
% all information about which trials have been played lies in the scaling table

thisDiff = strcmp(tableTest.Difficulty, difficulty);     % get rows of same difficulty
minplayed = min(tableTest.playedTimes(thisDiff));        % find which is the minimum number of rounds played
maxplayed = max(tableTest.playedTimes(thisDiff));        % find which is the maximum number of rounds played
iRows = find(thisDiff & tableTest.playedTimes == minplayed); % which rows have this difficulty AND have been played the least within that difficulty (or none at all)
count = 1;
iRow = iRows(count);

assert(sum(tableTest.playedLast) <= 1, 'should be at most one row marked as "played last"')

if any(tableTest.playedLast) % if we have played a trial, we have check not to repeat category
    % now the serious check if we replay category
    % old and new categories
    categoriesLast = extractBetween(tableTest{tableTest.playedLast, ["objL" "objR"]}, 1,1);
    categoriesNow = extractBetween(tableTest{iRow, ["objL" "objR"]}, 1,1);

    colourLast = extractBetween(tableTest{tableTest.playedLast, ["objL" "objR"]}, 5,5);
    colourNow = extractBetween(tableTest{iRow, ["objL" "objR"]}, 5,5);

    while any(categoriesNow == categoriesLast', [1 2])      % we check if we detect category conflict; if so, we search for another candidate
        count = count + 1;
        if count <= length(iRows)
            iRow = iRows(count);
            categoriesNow = extractBetween(tableTest{iRow, ["objL" "objR"]}, 1,1);
        else
            if minplayed < maxplayed        % we go to the rows that have been played more
                minplayed = minplayed + 1;
                iRows = find(thisDiff & tableTest.playedTimes == minplayed);
                count = 0;
            else    % just pick a trial, but we should never get here so we put a warning
                warning('for some reason no trial that does not repeat category found, this should not have happened. Giving out some random row')
                minplayed = min(tableTest.playedTimes(thisDiff));
                iRows = find(thisDiff & tableTest.playedTimes == minplayed);
                iRow = iRows(randi(length(iRows)));
                break
            end
        end
    end
end

% we set things up for trial to play
tableTest.playedTimes(iRow) = tableTest.playedTimes(iRow) + 1;
tableTest.playedLast(tableTest.playedLast) = false;
tableTest.playedLast(iRow) = true;
end