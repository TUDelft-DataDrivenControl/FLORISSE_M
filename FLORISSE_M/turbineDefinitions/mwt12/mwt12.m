function turbineType = mwt12()
%MWT12 This functions creates a turbine type of a miniature wind turbine
%   This minitaure wind turbine is optimized to have a good Ct and Cp such
%   that the wake deflection effect mimic those of large scale wind
%   turbines. More information can be found in :cite:`Bastankhah2017`.

% Available control methods
availableControl = {'tipSpeedRatio', 'axialInduction'};

% Function definitions for the calculation of Cp and Ct                       
cpctMapFunc   = @mwt12_cpct;

% Instantiate turbine with the correct dimensions and characteristics
% obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, ...
turbineType = turbine_type((12*10^-2)/2., 1, .2, 1.88, ...
                           cpctMapFunc, availableControl, 'Miniature wind turbine 12 cm');
end

% % This function is compatible with C-compilation
% function Path = getFileLocation()
%     filePath = mfilename('fullpath');
%     Path = filePath(1:end-1-length(mfilename()));
% end
