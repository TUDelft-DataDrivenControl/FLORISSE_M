function [xopt,P_bl,P_opt] = yawOptimizerGP(florisRunner,WD_std)

florisRunner.clearOutput;

nIters = 50;
nTraining = 150;
nTurbs = florisRunner.layout.nTurbs;

x0 = []; lb = []; ub = [];
yawAngleWFArray = florisRunner.controlSet.yawAngleWFArray;
x0 = [x0; yawAngleWFArray(1:nTurbs-3)];
lb = [lb; deg2rad(-30)*ones(1,nTurbs-3)]';
ub = [ub; deg2rad(+30)*ones(1,nTurbs-3)]';

WD_range = linspace(-WD_std*2,WD_std*2,5);

fx = @(x) (1/WD_std) * (1/sqrt(2*pi)) * exp( (-x.^2)/(2*WD_std^2));
WD_probability = fx(WD_range); % Values from Normal dist.
WD_probability = WD_probability/sum(WD_probability); % Normalized


% Set up GP optimization
useAF = true; 
AcqFunc.value = 1;
AcqFunc.kappa = 2; 
AcqFunc.xi = 0.00; 
seeds = 6;  % seeds for function optimization

Xm = [];
Pset = [];
xOpt = x0'; 

WD0 = florisRunner.layout.ambientInflow.windDirection;

lf_init = 1;
lx_init = 0.2*ones(nTurbs-3,1);
sfm_init = 0.01; 

for i = 1:(nIters + nTraining)
    Xm = [Xm, xOpt];    % expand measurement point vector
    nm = size(Xm,2);
       
    florisRunner.controlSet.yawAngleWFArray = [xOpt', zeros(1,3)];
    Pgauss = 0;
    for j = 1:5
        florisRunner.layout.ambientInflow.windDirection = WD0 + WD_range(j);
        florisRunner.controlSet.yawAngleIFArray = florisRunner.controlSet.yawAngleIFArray;
        florisRunner.run 
%         visTool = visualizer(florisRunner);
%         visTool.plot2dIF;
        
        P = sum([florisRunner.turbineResults.power])*1e-06;
        Pgauss = Pgauss + WD_probability(j)*P;
        florisRunner.clearOutput; 
    end  
    Pset = [Pset; Pgauss]; 
    
    % reset wind direction
    florisRunner.layout.ambientInflow.windDirection = WD0;
    
    if i < nTraining
        xOpt = lb + rand(length(lb),1).*(ub - lb);
    else 
        if i == nTraining
            [lf,lx,sfm] = tuneHPs(Xm,Pset,lf_init,lx_init,sfm_init);  
        else
            [lf,lx,sfm] = tuneHPs(Xm,Pset,lf,lx,sfm); 
        end

        lb = [deg2rad(-30)*ones(1,nTurbs-3)]';
        ub = [deg2rad(+30)*ones(1,nTurbs-3)]';

        if useAF == 1
            [~,~,K] = estimateGP(Xm,[],Pset,lf,lx,sfm);
            Kmm = cell2mat(K);
            Smm = eye(nm)*sfm^2;
            Kinv = eye(nm)/(Kmm+Smm);
%             EV.value = 0; 
%             AFEV = @(x)(acquisitionFunction(x,Xm,Kinv,Pset,lf,lx,sfm,EV));
%             [xopt,fOpt] = optimiseAF(AFEV,lb,ub,seeds);
%             AcqFunc.fOpt = fOpt;
%             if xopt(1) >= 0
%                 lb = zeros(6,1);
%             else
%                 ub = zeros(6,1);
%             end
            AF = @(x)(acquisitionFunction(x,Xm,Kinv,Pset,lf,lx,sfm,AcqFunc));
            [xOpt,fOpt] = optimiseAF(AF,lb,ub,seeds);  
        else
            nr = max(2,ceil(10 - j/10));
            np = 1e3; 
            alpha = 1/2;
            h = [0.2; 0.02];
            [~,xOpt] = particleDistribution(np,nr,h,alpha,lb,ub,Xm,Pset,Xs,lf,lx,sfm);
        end
        % Plot results
        figure(1)
        subplot(2,1,1)
        grid on;
        bar(Xm(:,i))
        xlabel('Turbine nr.')
        ylabel('Yaw misalignment [rad]')
        
        subplot(2,1,2)
        grid on; 
        hold on;
        xlim([0 nIters])
        plot(i-nTraining,Pgauss,'bd','MarkerFaceColor','b')
        xlabel('Iteration')
        ylabel('Cost function [MW]')
    end
end

P_bl = Pset(1);
[P_opt,i_opt] = max(Pset);
xopt = Xm(:,i_opt)';    

% visTool = visualizer(florisRunner);
% visTool.plot2dIF;
% Xs1 = deg2rad(-30:1:30);
% Xs = {Xs1; Xs1};
% [mPost,sPost] = estimateGP(Xm(1:2,:),Xs,Pset,lf,lx(1:2),sfm);
% plotGP(5,Xs,mPost,sPost);
% scatter3(Xm(1,:),Xm(2,:),Pset,'ro','filled')
    
end