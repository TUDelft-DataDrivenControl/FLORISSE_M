function [lf,lx,sfm,mb,prevJ] = tuneHPs(Xm,fm,lf,lx,sfm)
% This function tunes the hyperparameters of the GP based on the given
% measurement data. The parameters are optimized with a multivariate
% gradient-ascent algorithm that tries to optimize the log-likelihood of
% the shared distribution.
%   Inputs: 
%   - Xm: input values for measurements.
%   - fm: (noisy) measurement values.
%   Outputs: 
%   - lf: measurement length scale for covariance function.
%   - lx: input length scale for covariance function.
%   - sfm: assumed measurement noise standard deviation. 
%   - mb: constant mean value.
%   - prevJ: log-likelihood cost function for every iteration.

% Tuning settings
steps = 100;         % number of iterations in the gradient ascent algorithm.
gamma = 1;          % initial stepsize of gradient ascent algorithm, it will be updated along the way.
beta = 0.3;         % factor to reduce the stepsize. 
gammaDecrease = 50; % maximum number of times that the stepsize can be decreased.

% Check if the dimensions between inputs and outputs agree.
if size(Xm,2) ~= size(fm,1)
    error('The dimensions of the input do not agree with the number of measurements.')
end

% Extract dimensions
nx = size(Xm,1); % dimension of inputs.
nm = size(Xm,2); % number of measurement points.

if nargin < 3
    % Initial hyperparameter values
    lf = 1;             % output length scale. 
    lx = ones(nx,1);    % input length scale. 
    sfm = 0.1;          % standard deviation of measurement noise.
end

diff = repmat(permute(Xm,[2,3,1]),[1,nm]) - repmat(permute(Xm,[3,2,1]),[nm,1]); % difference matrix for covariance matrix.

prevTheta = [sfm^2; lf^2; lx.^2]; % initial hyperparameter vector.
prevJ = zeros(steps,1);         % empty storage vector for cost function
dJdTheta = zeros(2+nx,1);       % empty storage vector for derivative of cost function.

% Start gradient-ascent algorithm
for i = 1:steps
	for j = 1:gammaDecrease
		if i == 1 
            % The derivative of J is not known yet so we take the initial values for Theta.
			Theta = prevTheta;
        else
            % Update the parameters based on their gradients, scaling is applied on each hyperparameter.
			Theta = prevTheta + gamma*prevdJdTheta.*prevTheta.^2; 
		end
		% Check if hyperparameters are positive
        if min(Theta > 0) 
            % extract hyperparameters
			sfm = Theta(1);
			lf = Theta(2);
			lx = Theta(3:end);
			
            % Setup measurement covariance matrix.
            Kmm = lf*exp(-1/2*sum(diff.^2./repmat(permute(lx,[2,3,1]),[nm,nm,1]),3));
            P = Kmm + sfm*eye(nm);
 		    mb = (ones(nm,1)'/P*fm)/(ones(nm,1)'/P*ones(nm,1));                 % constant mean function.
			J = -nm/2*log(2*pi) - 1/2*logdet(P) - 1/2*(fm - mb)'/P*(fm - mb); % log-likelihood cost function
			if i == 1 || J >= prevJ(i-1)
				% calculate derivative of the cost function
				alpha = P\(fm - mb);
				R = alpha*alpha' - inv(P);
				dJdTheta(1) = 1/2*trace(R);
				dJdTheta(2) = 1/(2*lf)*trace(R*Kmm);
				for k = 1:nx
					dJdTheta(2+k) = 1/(4*lx(k)^2)*trace(R*(Kmm.*(diff(:,:,k).^2)));
				end
				if i > 1
                    % If gradient-ascent algorithm is still moving in the
                    % right direction, increase step size. If moving in
                    % wrong direction, decrease step size. If orthogonal to
                    % right direction, keep same stepsize. 
					gradientChange = (prevdJdTheta'*dJdTheta)/norm(prevdJdTheta)/norm(dJdTheta);
					gamma = 1/(beta^gradientChange)*gamma;
				end
				break; 
			end
        end
        % Stepsize was too big, reduce it.
        gamma = beta*gamma;
	end
	% Store parameters
	prevTheta = Theta;
	prevdJdTheta = dJdTheta;
	prevJ(i) = J;
    Thetaplot(:,i) = Theta; 
end

% figure; 
% plot(1:steps,sqrt(Thetaplot))
% legend('sfm','lf','lx1','lx2')
% 
% figure;
% plot(1:steps,prevJ);

% Extract the tuned hyperparameters.
sfm = sqrt(prevTheta(1));
lf = sqrt(prevTheta(2));
lx = sqrt(prevTheta(3:end));

end