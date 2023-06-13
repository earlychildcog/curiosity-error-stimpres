function a = filesRename(foldername)

arguments
    foldername string {mustBeFolder}
end

stringRename = @(c)regexprep(c,'(_|-)(\d+)(-|_)','${sprintf("-%.3d-",str2double($2))}');
try
    arrayfun(@(x)movefile(fullfile(x.folder, x.name), fullfile(x.folder, stringRename(x.name))), dir(fullfile(foldername, "*.png")))
catch err
    warning(err.message)
    a = 0;
    return
end
a = 1;
