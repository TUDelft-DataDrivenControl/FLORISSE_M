function [modelData] = jensen_params(modelData)
%JENSENPARAMS Summary of this function goes here
%   Detailed explanation goes here

modelData.Ke            = 0.05; % wake expansion parameters
modelData.KeCorrCT      = 0.0; % CT-correction factor
modelData.baselineCT    = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
end
