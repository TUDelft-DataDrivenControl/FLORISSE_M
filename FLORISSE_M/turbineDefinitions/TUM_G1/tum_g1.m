function turbineType = tum_g1()
%TUM_G1 Summary of this function goes here
%   Detailed explanation goes here

filepath = getFileLocation();
% Available control methods
availableControl = {'pitch', 'greedy', 'axialInduction'};
% Instantiate turbine with
% obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, path, allowableControlMethods)
turbineType = turbine_type(1.1/2, 1.0, 0.825, 1.787, filepath, availableControl);
end

% This function is compatible with C-compilation
function Path = getFileLocation()
    filePath = mfilename('fullpath');
    Path = filePath(1:end-1-length(mfilename()));
end