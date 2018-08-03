function turbineType = tum_g1()
%TUM_G1 This functions creates a turbine type of a small scale wind turbine
%as used in TUM

% Available control methods
availableControl = {'pitch', 'greedy', 'axialInduction'};

% Function definitions for the calculation of Cp and Ct                       
cpctMapFunc   = @tum_g1_cpct;

% Instantiate turbine with the correct dimensions and characteristics
% obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, ...
turbineType = turbine_type(1.1/2, 1.0, 0.825, 1.787, ...
                           cpctMapFunc, availableControl, 'Small scale turbine TUM');
end

% % This function is compatible with C-compilation
% function Path = getFileLocation()
%     filePath = mfilename('fullpath');
%     Path = filePath(1:end-1-length(mfilename()));
% end