function [modelData] = Zones_Jimenez()
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
end