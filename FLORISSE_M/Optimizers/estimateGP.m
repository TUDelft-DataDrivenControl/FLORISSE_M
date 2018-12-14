function [mPost,sPost,K] = estimateGP(Xm,Xs,fm,lf,lx,sfm)
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

% Check if the dimensions between inputs and outputs agree.
if size(Xm,2) ~= size(fm,1)
    error('The dimensions of the input do not agree with the number of measurements.')
end
nm = size(Xm,2);    % number of measurement points

% Check whether the trial points are provided in a cell format
if ~iscell(Xs)
    nx = size(Xs,1);                % dimension of input
    nsDim = ones(1,nx)*size(Xs,2);  % number of trial points per dimension
    if ~isempty(nsDim)
        ns = prod(nsDim);
    else
        ns = 0; 
    end    
    if nx == 2
        [Xmesh1,Xmesh2] = ndgrid(Xs(1,:),Xs(2,:));
        Xs = [reshape(Xmesh1,1,ns); reshape(Xmesh2,1,ns)];
    elseif nx == 3
        [Xmesh1,Xmesh2,Xmesh3] = ndgrid(Xs(1,:),Xs(2,:),Xs(3,:));
        Xs = [reshape(Xmesh1,1,ns); reshape(Xmesh2,1,ns); reshape(Xmesh3,1,ns)];
    end
else
    nx = size(Xs,1);
    nsDim = zeros(1,nx);
    for i = 1:nx
        nsDim(i) = length(Xs{i});
    end
    ns = prod(nsDim);
    if nx == 2
        [Xmesh1,Xmesh2] = ndgrid(Xs{1,:},Xs{2,:});
        Xs = [reshape(Xmesh1,1,ns); reshape(Xmesh2,1,ns)];
    elseif nx == 3
        [Xmesh1,Xmesh2,Xmesh3] = ndgrid(Xs{1,:},Xs{2,:},Xs{3,:});
        Xs = [reshape(Xmesh1,1,ns); reshape(Xmesh2,1,ns); reshape(Xmesh3,1,ns)];
    end
end

X = [Xm,Xs];    % input values
n = nm + ns;    % total number of inputs

% Create the squared-error covariance matrix
diff = repmat(permute(X,[2,3,1]),[1,n])-repmat(permute(X,[3,2,1]),[n,1]);   % differences between input points
K = lf^2*exp(-1/2*sum(diff.^2./repmat(permute(lx.^2,[3,2,1]),[n,n]),3));    % SE covariance matrix
K = mat2cell(K,[nm ns],[nm ns]);                                            % put in cell format
Kmm = K{1,1};                     
Kms = K{1,2};
Ksm = K{2,1};
Kss = K{2,2}; 

Sfm = eye(nm)*sfm^2;    % measurement noise matrix
mm = zeros(nm,1);       % mean values of measurements
ms = zeros(ns,1);       % mean values of trial points

% Compute posterior distribution
mPost = ms + Ksm/(Kmm+Sfm)*(fm-mm); % posterior mean of trial points
SPost = (Kss-Ksm/(Kmm+Sfm)*Kms);    % posterior variance of trial points   
sPost = sqrt(diag(SPost));          % posterior std's of trial points

if nx > 1
    mPost = reshape(mPost,nsDim);
    sPost = reshape(sPost,nsDim);
end

end