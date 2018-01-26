inputData.adjustInitialWakeDiamToYaw = false; % Adjust the intial swept surface overlap

inputData.useaUbU       = true; % This flags adjusts wake velocity recovery based on yaw angle:
% The equation used is: wake.mU = inputData.MU/cos(inputData.aU+inputData.bU*turbine.YawWF)
inputData.aU            = deg2rad(12.0);
inputData.bU            = 1.3;

inputData.Ke            = 0.05; % wake expansion parameters
inputData.KeCorrCT      = 0.0; % CT-correction factor
inputData.baselineCT    = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
inputData.me            = [-0.5, 0.22, 1.0]; % relative expansion of wake zones
inputData.MU            = [0.5, 1.0, 5.5]; % relative recovery of wake zones

% For a more detailed explanation of these parameters, see the
% paper with doi:10.1002/we.1993 by Gebraad et al. (2016).