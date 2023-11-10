function tableData = exclude_nback(tableData, history, var, nrepeat, nback)
arguments
    tableData table
    history (:,4) double
    var string {mustBeMember(var, ["cat", "sub", "col", "id" ])}
    nrepeat double = 1
    nback double = 2
end
% `var` instance should not occur more than `nrepeat` times in the last `nback` occurances in `history`
% `tableData` is a table with column names (at least): "cat", "sub", "col", "id", "idfull", "incl"
% `history` consists of pairs of occurences which correspond to the "idfull" column
if isempty(history)
    return
elseif size(history,1) < nback
    nback = size(history,1);
end
history_ = history((end-nback+1):end,1:2);
history_ = history_(:);
history_(~ismember(history_, tableData.idfull)) = [];   % in case we do not have all rows for some reason   
repeated = arrayfun(@(x)tableData.(var)(tableData.idfull == x),  history_);
repeated = repeated(:);
[counts, groups] = groupcounts(repeated);
badgroups = groups(counts >= nrepeat);
tableData.incl(ismember(tableData.(var), badgroups)) = false;
end