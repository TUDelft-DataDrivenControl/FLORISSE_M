function [pMax,xMax] = particleDistribution(np,nr,h,alpha,xMin,xMax,Xm,fm,Xs,lf,lx,sfm)

% Check if the dimensions between inputs and outputs agree.
if size(Xm,2) ~= size(fm,1)
    error('The dimensions of the input do not agree with the number of measurements.')
end
nm = size(Xm,2);    % number of measurement points

% Check whether the trial points are provided in a cell format
if ~iscell(Xs)   
    dx = size(Xs,1);                % dimension of input
    nsDim = ones(1,nx)*size(Xs,2);  % number of trial points per dimension
    if ~isempty(nsDim)
        ns = prod(nsDim);
    else
        ns = 0; 
    end    
    if dx == 2
        [Xmesh1,Xmesh2] = ndgrid(Xs(1,:),Xs(2,:));
        Xs = [reshape(Xmesh1,1,ns); reshape(Xmesh2,1,ns)];
    elseif dx == 3
        [Xmesh1,Xmesh2,Xmesh3] = ndgrid(Xs(1,:),Xs(2,:),Xs(3,:));
        Xs = [reshape(Xmesh1,1,ns); reshape(Xmesh2,1,ns); reshape(Xmesh3,1,ns)];
    end
else
    dx = size(Xs,1);
    nsDim = zeros(1,dx);
    for i = 1:dx
        nsDim(i) = length(Xs{i});
    end
    ns = prod(nsDim);
    if dx == 2
        [Xmesh1,Xmesh2] = ndgrid(Xs{1,:},Xs{2,:});
        Xs = [reshape(Xmesh1,1,ns); reshape(Xmesh2,1,ns)];
    elseif dx == 3
        [Xmesh1,Xmesh2,Xmesh3] = ndgrid(Xs{1,:},Xs{2,:},Xs{3,:});
        Xs = [reshape(Xmesh1,1,ns); reshape(Xmesh2,1,ns); reshape(Xmesh3,1,ns)];
    end
end
       
% We initialize the particles.
particles = xMin + (xMax - xMin).*rand(dx,np); % We set up particles in random locations.
weights = ones(np,1); % We initialize the weights.

% Next, we generate the victory function values. We initialize them according to the distribution of the function value at the particle input points.
diff = repmat(permute(Xm,[2,3,1]),[1,nm])-repmat(permute(Xm,[3,2,1]),[nm,1]);
Kmm = lf^2*exp(-1/2*sum(diff.^2./repmat(permute(lx.^2,[3,2,1]),[nm,nm]),3));

diff = repmat(permute(particles,[3,2,1]),[nm,1])-repmat(permute(Xm,[2,3,1]),[1,np]);   % differences between input points
Kmp = lf^2*exp(-1/2*sum(diff.^2./repmat(permute(lx.^2,[3,2,1]),[nm,np]),3));

Kpm = Kmp';
Kpp = lf^2*ones(np,1); % Usually this matrix is diagonal, but given that we have a lot of particles, that would be a too large matrix.

Sfm = eye(nm)*sfm^2;
KpmDivKmm = Kpm/(Kmm + Sfm);
mm = zeros(nm,1);
mup = KpmDivKmm*(fm - mm);              % These are the mean values of the Gaussian process at all the particle points.
Sigma = Kpp - sum(KpmDivKmm.*Kpm,2);    % These are the variances of the Gaussian process at the particle points. We have calculated only the diagonal elements of the covariance matrix here, because we do not need the other elements.
sigma = sqrt(Sigma);
values = mup + sigma.*(randn(np,1));    % We take a random sample from the resulting distribution.

% % We set up a storage parameter for the maximum distributions, and we set up the PDF for the first one.
% pMax = zeros(nr+1, ns);
% for i = 1:np
% 	pMax(1,:) = pMax(1,:) + weights(i)*1/prod(sqrt(2*pi)*h)*exp(-1/2*sum((Xs - repmat(particles(:,i),1,ns)).^2./repmat(h.^2,1,ns),1));
% end
% pMax(1,:) = pMax(1,:)/sum(weights);
% pMaxPlot = reshape(pMax(1,:),nsDim);
% figure(3);
% clf(3); 
% surface(Xmesh1,Xmesh2,pMaxPlot);
    
% We iterate over the number of challenge rounds.
for round = 1:nr
	% We start by applying systematic resampling. (Yes, this is quite useless in the first round, but we ignore that tiny detail and do it anyway.)
	oldParticles = particles; % We store the old particles, so we can override the particles matrix during the process of resampling.
	oldValues = values;
	oldWeights = weights;
	wCum = cumsum(oldWeights); % These are the cumulative weights.
	wSum = wCum(end); % This is the sum of all the weights.
	stepSize = wSum/np; % We calculate the step size based on the sum of all the weights.
	val = rand(1,1)*stepSize; % We pick a random number for the algorithm.
	oldPCounter = 1; % We use two counters in the process. This first one keeps track of which old particle we are at.
	newPCounter = 1; % This second counter keeps track of which new particle index we are at.
	while newPCounter <= np % We iterate until we have added np new particles.
		while wCum(oldPCounter) < val + (newPCounter-1)*stepSize % We iterate through the particles until we find the one which we should be adding particles of.
			oldPCounter = oldPCounter + 1;
		end
		while wCum(oldPCounter) >= val + (newPCounter-1)*stepSize % We keep adding this particle to the new set of particles until we have added enough.
			particles(:,newPCounter) = oldParticles(:,oldPCounter);
			weights(newPCounter) = 1;
			values(newPCounter) = oldValues(oldPCounter);
			newPCounter = newPCounter + 1;
		end
	end
	
	% We now create challengers according to the specified rules.
	sampleFromMaxDist = (rand(1,np) < alpha); % We determine which challengers we will pick from the current belief of the maximum distribution, and which challengers we pick randomly.
	randomPoints = rand(dx,np).*(xMax-xMin)+xMin; % We select random challengers. (We do this for all particles and then discard the ones which we do not need.)
	indices = ceil(rand(np,1)*np); % We pick the indices of the champion particles we will use to generate challengers from. This line only works if all the particles have a weight of one, which is the case since we have just resampled. Otherwise, we should use randsample(np,np,true,weights);
	deviations = randn(dx,np).*h; % To apply the Gaussian kernel to the selected champions, we need to add a Gaussian parameter to the champion particles. We set that one up here.
	challengers = (1-sampleFromMaxDist).*randomPoints + sampleFromMaxDist.*(particles(:,indices) + deviations); % We finalize the challenger points, picking random ones where applicable and sampled from the maximum distribution in other cases.

	% We now set up the covariance matrices and calculate some preliminary parameters.
	diff = repmat(permute([particles,challengers],[3,2,1]),[nm,1]) - repmat(permute(Xm,[2,3,1]),[1,2*np]); % This is the matrix containing differences between input points.
	Kmp = lf^2*exp(-1/2*sum(diff.^2./repmat(permute(lx.^2,[3,2,1]),[nm,2*np]),3));
	Kpm = Kmp';
	KpmDivKmm = Kpm/(Kmm + Sfm);
	mup = KpmDivKmm*(fm - mm); % These are the mean values of the Gaussian process at all the particle points.

	% We calculate the mean and covariance for each combination of challenger and challenged point. Then we sample \hat{f} and look at the result.
	oldParticles = particles;
	for i = 1:np
		mupc = mup([i,i+np]); % This is the current mean vector.
		diff = repmat(permute([particles(:,i),challengers(:,i)],[3,2,1]),2,1) - repmat(permute([particles(:,i),challengers(:,i)],[2,3,1]),1,2);
		Kppc = lf^2*exp(-1/2*sum(diff.^2./repmat(permute(lx.^2,[3,2,1]),2,2),3));
		Sigmac = Kppc - KpmDivKmm([i,i+np],:)*Kmp(:,[i,i+np]); % This is the current covariance matrix.
		try % We use a try-catch-block here because sometimes numerical errors may occur.
			fHat = mupc + chol(Sigmac)'*randn(2,1);
			if fHat(2) > fHat(1) % Has the challenger won?
				particles(:,i) = challengers(:,i);
				values(i) = fHat(2);
				q = 1/(xMax-xMin); % This is the probability density function value of q(x).
				qp = (1-alpha)*q + alpha*1/prod(sqrt(2*pi)*h)*exp(-1/2*sum((challengers(:,i) - oldParticles(:,indices(i))).^2./h.^2)); % This is the sampling probability density function given that we have selected the champion particle from the indices vector in the sampling process.
				weights(i) = q/qp;
			end
		catch
			% Apparently challengerPoints(i) and points(i) are so close together that we have numerical problems. Since they're so close, we can just ignore this case anyway, except possibly
			% display that numerical issues may have occurred.
			disp(['There may be numerical issues in the challenging process at particle ',num2str(i),'.']);
		end
	end
	
	% Finally we set up the maximum distribution, given all the particles.
% 	for i = 1:np
% 		pMax(round+1,:) = pMax(round+1,:) + weights(i)*1/prod(sqrt(2*pi)*h)*exp(-1/2*sum((Xs - repmat(particles(:,i),1,ns)).^2./repmat(h.^2,1,ns),1));
% 	end
% 	pMax(round+1,:) = pMax(round+1,:)/sum(weights);
    
%     pMaxPlot = reshape(pMax(round+1,:),nsDim);
%     figure(3);
%     clf(3); 
%     surface(Xmesh1,Xmesh2,pMaxPlot);
    
end

pMax = zeros(1,ns);
for i = 1:np
    pMax = pMax + weights(i)*1/prod(sqrt(2*pi)*h)*exp(-1/2*sum((Xs - repmat(particles(:,i),1,ns)).^2./repmat(h.^2,1,ns),1));
end
pMax = pMax/sum(weights);
    
ixMax = randsample(ns,1,true,pMax); 
xMax = Xs(:,ixMax) + randn(dx,1).*h;
pMax = reshape(pMax,nsDim);

end
