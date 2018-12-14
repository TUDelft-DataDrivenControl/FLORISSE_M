function xEst = estimatorGP(florisObjSet,measurementSet,lb,ub)

nIter = 50;

% grid search
Xs1 = linspace(lb(1),ub(1),25);
Xs2 = linspace(lb(2),ub(2),61);
Xs = {Xs1; Xs2};

phi = florisObjSet.layout.ambientInflow.windDirection;

xOpt = [3; 6.5];    % initial input
Xm = [];
Jset = [];

useAF = false; 
AcqFunc.value = 1;
AcqFunc.kappa = 2; 
AcqFunc.xi = 0; 
seeds = 5;  % seeds for function optimization

% tic;
for i = 1:nIter
    Xm = [Xm, xOpt];    % expand measurement point vector
    nm = size(Xm,2);

%     layout.ambientInflow = ambient_inflow_log('WS', xOpt(1),'HH', 90.0,'WD', xOpt(2),'TI0', 0.06);
%     layout.ambientInflow = ambient_inflow_log('WS', 8,'HH', 90.0,'WD', xOpt(2),'TI0', xOpt(1)/100);
    florisObjSet.layout.ambientInflow = ambient_inflow_log('WS', xOpt(2),'HH', 119.0,'WD', phi,'TI0', xOpt(1)/100);
%     florisRunner = floris(layout, controlSet, subModels);
%     florisRunner.run 
    florisObjSet.clearOutput;
    florisObjSet.run
    f = zeros(1,florisObjSet.layout.nTurbs);
    for k = 1:florisObjSet.layout.nTurbs
        f(k) = florisObjSet.turbineResults(k).power;
    end
    powerError = f - measurementSet.P.values;  
    J = -sqrt(mean((powerError ./ measurementSet.P.stdev).^2))*1e-6;
    Jset = [Jset; J]; 
    [lf,lx,sfm] = tuneHPs(Xm,Jset); 

    if useAF == 1
        [~,~,K] = estimateGP(Xm,[],Jset,lf,lx,sfm);
        Kmm = cell2mat(K);
        Smm = eye(nm)*sfm^2;
        Kinv = eye(nm)/(Kmm+Smm);
        EV.value = 0; 
        AFEV = @(x)(acquisitionFunction(x,Xm,Kinv,Jset,lf,lx,sfm,EV));
        [~,fOpt] = optimiseAF(AFEV,lb,ub,seeds);
        AcqFunc.fOpt = fOpt; 
        AF = @(x)(acquisitionFunction(x,Xm,Kinv,Jset,lf,lx,sfm,AcqFunc));
        [xOpt,fOpt] = optimiseAF(AF,lb,ub,seeds);  
    else
        nr = 10; %max(2,ceil(10 - i/10));
        np = 2e3; 
        alpha = 1/2;
%         h = [0.2; 0.02];
        h = [0.5; 0.3];
        [pMax,xOpt] = particleDistribution(np,nr,h,alpha,lb,ub,Xm,Jset,Xs,lf,lx,sfm);
%         [Xs1Mesh,Xs2Mesh] = meshgrid(Xs1,Xs2);
%         figure(3);
%         clf(3); 
%         surface(Xs1Mesh,Xs2Mesh,pMax');
    end

%         [mPost,sPost] = estimateGP(Xm,Xs,Jset,lf,lx,sfm);
%         plotGP(5,Xs,mPost,sPost);
%         scatter3(Xm(1,:),Xm(2,:),Jset,'ro','filled')
end
% disp(['Finished GP optimisation. Time passed is ',num2str(toc),' seconds.']);  

pMax_u1 = trapz(pMax,2)*(Xs2(2)-Xs2(1));
pMax_u2 = trapz(pMax,1)*(Xs1(2)-Xs1(1));
[~,ixOpt1] = max(pMax_u1);
[~,ixOpt2] = max(pMax_u2);

xEst = [Xs1(ixOpt1); Xs2(ixOpt2)];
xEst(1) = xEst(1)/100;
% visTool = visualizer(florisObjSet);
% visTool.plot2dIF;

end
