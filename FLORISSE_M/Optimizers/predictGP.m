function [mPost,sPost] = predictGP(x,Xm,Kinv,fm,lf,lx,sfm)
% This function uses GP regression to estimate the posterior mean and
% standard deviation of a function at the given trial points Xs, based on
% (noisy) measurements. 
%   Inputs:
%   - Xm: input values for measurements.
%   - Xs: trial points for the GP regression.
%   - fm: (noisy) measurement values.
%   - lf: measurement length scale for covariance function.
%   - lx: input length scale for covariance function.
%    - sfm: assumed measurement noise standard deviation. 
%   Outputs:
%   - mPost: posterior mean of the GP.
%   - sPost: standard deviations of the GP.
%   - K: squared error covariance matrix. 

nm = size(Xm,2);    % number of measurement points

Ksm = lf^2*exp(-1/2*sum((permute(Xm,[3,2,1]) - repmat(permute(x,[2,3,1]),1,nm)).^2./repmat(permute(lx.^2,[3,2,1]),1,nm),3));
Kss = lf^2;

mPost = Ksm*Kinv*fm;
SPost = Kss-Ksm*Kinv*Ksm';
sPost = sqrt(diag(SPost));

end