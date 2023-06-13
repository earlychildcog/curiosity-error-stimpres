function tableScaling = getScaledObjects(tableScaling, difficulty)
% takes the scaling table and the difficulty, and decides which trial to play
% all information about which trials have been played lies in the scaling table

thisDiff = strcmp(tableScaling.Difficulty, difficulty);     % get rows of same difficulty
minplayed = min(tableScaling.playedTimes(thisDiff));        % find which is the minimum number of rounds played
maxplayed = max(tableScaling.playedTimes(thisDiff));        % find which is the maximum number of rounds played
iRows = find(thisDiff & tableScaling.playedTimes == minplayed); % which rows have this difficulty AND have been played the least within that difficulty (or none at all)
count = 1;
iRow = iRows(count);

if sum(tableScaling.playedLast) == 1 % if we have played a trial, we have check not to repeat category
    % now the serious check if we replay category
    % old and new categories
    categoriesLast = extractAfter(tableScaling{tableScaling.playedLast, {'objL' 'objR'}}, '_');
    categoriesNow = extractAfter(tableScaling{iRow, {'objL' 'objR'}},'_');
    % matlab was doing weird thing making these string arrays sometimes (?)
    % so we make sure they are cell arrays
    if ~iscell(categoriesLast)
        categoriesLast = arrayfun(@(x)char(x), categoriesLast, 'UniformOutput', false);
    end
    if ~iscell(categoriesNow)
        categoriesNow = arrayfun(@(x)char(x), categoriesNow, 'UniformOutput', false);
    end
    categoriesLast = cellfun(@(x)x(1:end-1), categoriesLast, 'UniformOutput',false);
    categoriesNow = cellfun(@(x)x(1:end-1), categoriesNow, 'UniformOutput',false);
    while ~isempty(intersect(categoriesNow,categoriesLast))
        count = count + 1;
        if count <= length(iRows)
            iRow = iRows(count);
            categoriesNow = extractAfter(tableScaling{iRow, {'objL' 'objR'}},'_');
            if ~iscell(categoriesNow)
                categoriesNow = arrayfun(@(x)char(x), categoriesNow, 'UniformOutput', false);
            end
            categoriesNow = cellfun(@(x)x(1:end-1), categoriesNow, 'UniformOutput',false);
        else
            if minplayed < maxplayed        % we go to the rows that have been played more
                minplayed = minplayed + 1;
                iRows = find(thisDiff & tableScaling.playedTimes == minplayed);
                count = 0;
            else    % just pick a trial, but we should never get here so we put a warning
                warning('for some reason no trial that does not repeat category found, this should not have happened. Giving out some random row')
                minplayed = min(tableScaling.playedTimes(thisDiff));
                iRows = find(thisDiff & tableScaling.playedTimes == minplayed);
                iRow = iRows(randi(length(iRows)));
                break
            end
        end
    end
elseif sum(tableScaling.playedLast) > 1 % error, should be at most one row played last
    error('should be only one row marked as "played last"')
end

% we set things up for trial to play
tableScaling.playedTimes(iRow) = tableScaling.playedTimes(iRow) + 1;
tableScaling.playedLast(tableScaling.playedLast) = false;
tableScaling.playedLast(iRow) = true;
end