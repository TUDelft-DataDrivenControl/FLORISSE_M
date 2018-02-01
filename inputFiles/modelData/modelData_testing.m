function [modelData] = modelData_testing()
%% modelData_testing
%  This file includes the model parameters for all available submodels in
%  the FLORIS code. DO NOT CHANGE PARAMETER VALUES. This file is used for
%  validation during development.
%

%% General parameters
modelData.adjustInitialWakeDiamToYaw = false; % Adjust the intial swept surface overlap

% Blade-rotation-induced wake deflection
modelData.ad = -4.5;   % lateral wake displacement bias parameter (a + bx)
modelData.bd = -0.01;  % lateral wake displacement bias parameter (a + bx)
modelData.at = 0.0;    % vertical wake displacement bias parameter (a + bx)
modelData.bt = 0.0;    % vertical wake displacement bias parameter (a + bx)


%% Parameters specific for the Jimenez model
modelData.KdY = 0.17; % Wake deflection recovery factor
modelData.useWakeAngle = true; % define initial wake displacement and angle (not determined by yaw angle)
modelData.kd = deg2rad(1.5);   % initialWakeAngle in X-Y plane

%% Parameters specific for the Zones model from Gebraad
modelData.useaUbU       = true; % This flags adjusts wake velocity recovery based on yaw angle:
% The equation used is: wake.mU = inputData.MU/cos(inputData.aU+inputData.bU*turbine.YawWF)
modelData.aU            = deg2rad(12.0);
modelData.bU            = 1.3;

modelData.Ke            = 0.05; % wake expansion parameters
modelData.KeCorrCT      = 0.0; % CT-correction factor
modelData.baselineCT    = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
modelData.me            = [-0.5, 0.22, 1.0]; % relative expansion of wake zones
modelData.MU            = [0.5, 1.0, 5.5]; % relative recovery of wake zones

% For a more detailed explanation of these parameters, see the
% paper with doi:10.1002/we.1993 by Gebraad et al. (2016).
% correction recovery coefficients with yaw

%% Parameters specific for the Larsen model
modelData.IaLars = 0.06; % ambient turbulence


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