function [out] = test_dependencies(functionsPath,doRecursively)

% Setup folders to look into
if doRecursively
    dirList = strsplit(genpath(functionsPath),';'); % Find directories recursively
    dirList(strcmp(dirList,'')) = []; % Remove empty entries
else
    dirList = {functionsPath};
end

% Cycle through all folders
dependencyArray = {};
for jdir = 1:length(dirList)
    folderName = dirList{jdir};
    fileNames = dir(folderName);
    fileNames = fileNames(~[fileNames.isdir]); % Remove all directories
    if length(fileNames) <= 0 && doRecursively == 0
        error(['  ERROR: There are no files to inspect. Folder ''' folderName ''' exclusively has folders in it. Please enable doRecursively or specify a subdirectory manually.']);
    end
    for jFile = 1:length(fileNames)
        inputFile = [fileNames(jFile).folder filesep fileNames(jFile).name];
        
        % Check dependencies
        [names, ~] = dependencies.toolboxDependencyAnalysis({inputFile});
        disp(['Dependencies: ' strjoin(names,', ') '. [' folderName filesep fileNames(jFile).name ']'])
        dependencyArray={dependencyArray{:} names{:}};
    end
end

% Unique dependencies
disp(' ');
disp('Overview:')
[uniqueArray,~,ic] = unique(dependencyArray);
for i = 1:length(uniqueArray)
    disp([num2str(i) '. Dependency: ' uniqueArray{i} ' (' num2str(sum(ic == i))  'x).']);
end

% Make a compatibility report (only for newest MATLAB 2017b)
if exist('codeCompatibilityReport') ~= 0
    codeCompatibilityReport(functionsPath);
end

out = uniqueArray; % Output is the unique list of toolbox dependencies
end