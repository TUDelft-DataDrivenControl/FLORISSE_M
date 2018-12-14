function y = acquisitionFunction(x,Xm,Kinv,fm,lf,lx,sfm,AF)
% This function computes the value of an acquisition function for a GP
% given an input value x. The type of acquisition function can be selected
% by the user.
%   Inputs: 
%   - x: input value for evaluation of the acquisition function.
%   - Xm: input values for measurements.
%   - Xs: trial points for the GP regression.
%   - fm: (noisy) measurement values.
%   - lf: measurement length scale for covariance function.
%   - lx: input length scale for covariance function.
%   - sfm: assumed measurement noise standard deviation. 
%   - AF: acquisition function type; 0 -> expected value (EV), 1 -> upper
%       confidence bound (UCB), 2 -> expected improvement (EI), 3 -> 
%       probability of improvement (PI).
%   Outputs:
%   - y: value of the acquisition function for input x.

% Check whether we have the required input arguments.
if nargin < 7
    error('Not enough input arguments.')
end

% If no acquisition function has been selected, the UCB is used. 
if  nargin < 8
    AF.value = 1;
end

% Check which acquisition function has been selected. 
if AF.value == 0  % EV
    [mu,~] = predictGP(x,Xm,Kinv,fm,lf,lx,sfm);
    y = mu;
elseif AF.value == 1  % UCB
    [mu,sigma] = predictGP(x,Xm,Kinv,fm,lf,lx,sfm);
%     [mu,sigma] = estimateGP(Xm,x,fm,lf,lx,sfm);
    y = mu + AF.kappa*sigma;
elseif AF.value == 2  % PI
    [mu,sigma] = predictGP(x,Xm,Kinv,fm,lf,lx,sfm);
    z = ((mu - AF.fOpt - AF.xi)/sqrt(sigma));
	Phi = 1/2 + 1/2*erf(z/sqrt(2));
	if Phi > 0
		y = log(Phi); % Usually the output is Phi, but we take the logarithm because otherwise the values are just too small.
	else
		y = -1e200; % Sometimes y becomes zero for numerical reasons. This basically means that it's extremely small. Still, it'll crash the algorithm. So we just set a default very small value here.
	end
elseif AF.value == 3  % EI
    [mu,sigma] = predictGP(x,Xm,Kinv,fm,lf,lx,sfm);
    z = ((mu - AF.fOpt - AF.xi)/sqrt(sigma));
	Phi = 1/2 + 1/2*erf(z/sqrt(2));
    phi = 1/sqrt(det(2*pi))*exp(-1/2*z^2);
    EI = sqrt(sigma)*(z*Phi + phi);
    if EI > 0
		y = log(EI); % Usually the output is the equation within the logarithm, but we take the logarithm because otherwise the result is too small.
	else
		y = -1e200; % Sometimes y becomes zero for numerical reasons. This basically means that it's extremely small. Still, it'll crash the algorithm. So we just set a default very small value here.
	end
end

end
