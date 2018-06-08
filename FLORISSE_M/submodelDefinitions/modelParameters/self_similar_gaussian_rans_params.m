function [modelData] = self_similar_gaussian_rans_params(modelData)
%SELFSIMILARGAUSSIANPARAMS Summary of this function goes here
%   Detailed explanation goes here

% Parameters specific for the Porte-Agel model
modelData.alpha = 2.32;     % near wake parameter
modelData.beta  = .154;     % near wake parameter
% modelData.veer  = 0;        % veer of atmosphere
% 
% modelData.TIthresholdMult = 30; % threshold distance of turbines to include in \"added turbulence\"
% modelData.TIa   = .73;      % magnitude of turbulence added
% modelData.TIb   = .8325;    % contribution of turbine operation
% modelData.TIc   = .0325;    % contribution of ambient turbulence intensity
% modelData.TId   = -.32;     % contribution of downstream distance from turbine

modelData.ka	= .3837;    % wake expansion parameter (ka*TI + kb)
modelData.kb 	= .0037;    % wake expansion parameter (ka*TI + kb)

end

