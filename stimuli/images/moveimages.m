% get image files from folder $original_folder and put them in designated
% folders with new file names
ext = '.png';
original_folder = 'sefo';
files = arrayfun(@(x)x.name, dir([original_folder '/*' ext]),'UniformOutput',false);

T = readtable('../../config/corresponds.csv');

N = length(T.obj1);

for k = 1:N
    thisone = [T.obj2{k} ext];
    ind = strcmpi(thisone,files);
    if any(ind)
        copyfile([original_folder '/' thisone],sprintf('test2/%.2d_%s',k, thisone))
    end
end
% files = arrayfun(@(x)x.name, dir(['test1\*' ext]),'UniformOutput',false);

for k = 1:N
    thisone = [T.obj1{k} ext];
    ind = strcmpi(thisone,files);
    if any(ind)
        copyfile([original_folder '/' thisone], sprintf('test1/%.2d_%s',k, thisone))
    end
end



