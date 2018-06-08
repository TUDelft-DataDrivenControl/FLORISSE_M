function [modelData] = zoned_params(modelData)
%ZONEDPARAMS Summary of this function goes here
%   Detailed explanation goes here

% Parameters specific for the Zones model from Gebraad
modelData.useaUbU       = true; % This flags adjusts wake velocity recovery based on yaw angle:
% The equation used is: wake.mU = inputData.MU/cos(inputData.aU+inputData.bU*turbine.YawWF)
modelData.aU            = deg2rad(12.0);
modelData.bU            = 1.3;

modelData.Ke            = 0.05; % wake expansion parameters
modelData.KeCorrCT      = 0.0; % CT-correction factor
modelData.baselineCT    = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
modelData.me            = [-0.5, 0.22, 1.0]; % relative expansion of wake zones
modelData.MU            = [0.5, 1.0, 5.5]; % relative recovery of wake zones

end
