function turbineType = mwt12()
%MWT12 This functions creates a turbine type of the miniature wind turbine
%   This minitaure wind turbine is optimized to have a good Ct and Cp such
%   that the wake deflection effect mimic those of large scale wind
%   turbines. More information can be found in :cite:`Bastankhah2017`.

filepath = getFileLocation();
% Available control methods
availableControl = {'tipSpeedRatio', 'axialInduction'};
% Instantiate turbine with
% obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, path, allowableControlMethods)
turbineType = turbine_type((12*10^-2)/2., 1, .3, 1.88, filepath, availableControl);
end

% This function is compatible with C-compilation
function Path = getFileLocation()
    filePath = mfilename('fullpath');
    Path = filePath(1:end-1-length(mfilename()));
end
