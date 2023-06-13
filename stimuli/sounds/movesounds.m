% move images
ext = '.wav';


T = readtable('../../config/corresponds.csv');
oldfold = 'Label/';
files = arrayfun(@(x)x.name, dir([oldfold '/*' ext]),'UniformOutput',false);
newfold = { '2_Labels_1/' '3_Labels_2/' };
cellfun(@mkdir,newfold)
N = length(T.obj1);
c = 1;
for k = 1:N
    thisone = [T.lab1{k} ext];
    ind = strcmpi(thisone,files);
    thatone = sprintf('%s%.2d_%s',newfold{1},k, thisone);
    if any(ind)
        copyfile([oldfold thisone],thatone)
    end
end

for k = 1:N
    thisone = [T.lab2{k} ext];
    ind = strcmpi(thisone,files);
    if any(ind)
        copyfile([oldfold thisone], sprintf('%s%.2d_%s',newfold{2},k, thisone))
    end
end



