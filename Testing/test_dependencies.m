function [] = test_dependencies(functionsPath,doRecursively)

% Setup folders to look into
if doRecursively
    dirList = strsplit(genpath(functionsPath),';'); % Find directories recursively
    dirList(strcmp(dirList,'')) = []; % Remove empty entries
else
    dirList = {functionsPath};
end

% Cycle through all folders
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
        disp(['Filename: ' folderName filesep fileNames(jFile).name '. Dependencies: ' strjoin(names,', ')])
    end
end

% Make a compatibility report (only for newest MATLAB 2017b)
if exist('codeCompatibilityReport') ~= 0
    codeCompatibilityReport(functionsPath);
end
