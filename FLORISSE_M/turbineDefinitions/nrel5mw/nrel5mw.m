function turbineType = nrel5mw()
%DTU10MW This functions creates a turbine type of the NREL5MW reference turbine
%    More information can be found in :cite:`Jonkman2009`.

% Available control methods
availableControl = {'pitch', 'greedy', 'axialInduction'};

% Function definitions for the calculation of Cp and Ct                       
cpctMapFunc   = @nrel5mw_cpct;

% Instantiate turbine with the correct dimensions and characteristics
% obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, ...
turbineType = turbine_type(126.4/2., 0.944, 90.0, 1.88, ...
                           cpctMapFunc, availableControl, 'NREL5MW reference turbine');
end

% % This function is compatible with C-compilation
% function Path = getFileLocation()
%     filePath = mfilename('fullpath');
%     Path = filePath(1:end-1-length(mfilename()));
% end
