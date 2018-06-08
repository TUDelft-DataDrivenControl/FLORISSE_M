function [modelData] = self_similar_gaussian_rans_params(modelData)
%SELFSIMILARGAUSSIANPARAMS Summary of this function goes here
%   Detailed explanation goes here

% Parameters specific for the Porte-Agel model
modelData.alpha = 2.32;     % near wake parameter
modelData.beta  = .154;     % near wake parameter
modelData.ka	= .3837;    % wake expansion parameter (ka*TI + kb)
modelData.kb 	= .0037;    % wake expansion parameter (ka*TI + kb)

end

