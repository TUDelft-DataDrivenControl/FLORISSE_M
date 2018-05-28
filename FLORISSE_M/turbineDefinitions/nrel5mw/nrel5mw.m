function turbineType = nrel5mw()
%TUM_G1 Summary of this function goes here
%   Detailed explanation goes here

filepath = getFileLocation();
% Available control methods
availableControl = {'pitch', 'greedy', 'axialInduction'};
% Instantiate turbine with
% obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, path, allowableControlMethods)
turbineType = turbine_type(126.4/2., 0.944, 90.0, 1.88, filepath, availableControl);
end

% This function is compatible with C-compilation
function Path = getFileLocation()
    filePath = mfilename('fullpath');
    Path = filePath(1:end-1-length(mfilename()));
end
