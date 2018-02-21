function [modelData] = PorteAgel_default()
%% PORTEAGEL_DEFAULT
%  loads the default set of model parameters for the Porte-Agel deficit and
%  wake deflection model.
%

%% General parameters
modelData.adjustInitialWakeDiamToYaw = false; % Adjust the intial swept surface overlap

% Blade-rotation-induced wake deflection
modelData.ad = -4.5/126.4; % lateral wake displacement bias parameter (a*Drotor + bx)
modelData.bd = -0.01;      % lateral wake displacement bias parameter (a*Drotor + bx)
modelData.at = 0.0;        % vertical wake displacement bias parameter (a*Drotor + bx)
modelData.bt = 0.0;        % vertical wake displacement bias parameter (a*Drotor + bx)


%% Parameters specific for the Porte-Agel model
modelData.alpha = 2.32;     % near wake parameter
modelData.beta  = .154;     % near wake parameter
modelData.veer  = 0;        % veer of atmosphere
modelData.ad    = -4.5;     % lateral wake displacement bias parameter (a + bx)
modelData.bd    = -.01;     % lateral wake displacement bias parameter (a + bx)

modelData.TIthresholdMult = 30; % threshold distance of turbines to include in \"added turbulence\"
modelData.TIa   = .73;      % magnitude of turbulence added
modelData.TIb   = .8325;    % contribution of turbine operation
modelData.TIc   = .0325;    % contribution of ambient turbulence intensity
modelData.TId   = -.32;     % contribution of downstream distance from turbine

modelData.ka	= .3837;    % wake expansion parameter (ka*TI + kb)
modelData.kb 	= .0037;    % wake expansion parameter (ka*TI + kb)

% For more information, see the publication from Bastankah and
% Porte-Agel (2016) with doi:10.1017/jfm.2016.595.
end