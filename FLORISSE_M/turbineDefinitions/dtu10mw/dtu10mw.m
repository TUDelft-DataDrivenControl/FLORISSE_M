function turbineType = dtu10mw()
%DTU10MW This functions creates a turbine type of the DTU10MW reference turbine
%    More information can be found in :cite:`Christian2013`.

% Available control methods
availableControl = {'axialInduction','yaw','yawAndRelPowerSetpoint'};

% Function definitions for the calculation of Cp and Ct                       
cpctMapFunc   = @dtu10mw_cpct;

% Instantiate turbine with the correct dimensions and characteristics
% obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, ...
turbineType = turbine_type(178.3/2., 1.08, 119.0, 1.50, ...
                           cpctMapFunc, availableControl, 'DTU 10 MW Turbine (WE 2019)');   
end

% % This function is compatible with C-compilation
% function Path = getFileLocation()
%     filePath = mfilename('fullpath');
%     Path = filePath(1:end-1-length(mfilename()));
% end
