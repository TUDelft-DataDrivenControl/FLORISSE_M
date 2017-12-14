function [ wake ] = naiveGaussianWake( inputData,turbine,wake )
%NAIVEGAUSSIANWAKE Summary of this function goes here
%   Detailed explanation goes here

    a = turbine.axialInd;

    % Calculate ke, the basic expansion coefficient
    wake.Ke = inputData.Ke + inputData.KeCorrCT*(turbine.Ct-inputData.baselineCT);

    r0Jens = turbine.rotorRadius;       % Initial wake radius [m]
    rJens = @(x) wake.Ke*x+r0Jens;      % Wake radius as a function of x [m]
    cJens = @(x) (r0Jens./rJens(x)).^2; % Wake intensity reduction factor according to Jensen

    gv = .65; % Gaussian variable
    sd = 2;   % Number of std. devs to which the gaussian wake extends
    P_normcdf_lb = 0.022750131948179; % This is the evaluation of normcdf(-sd,0,1) for sd = 2
    P_normcdf_ub = 0.977249868051821; % This is the evaluation of normcdf(+sd,0,1) for sd = 2
    varWake = @(x) rJens(x).*gv;


    % cFull is the wake intensity reduction factor
    % cFull = @(x,r) (pi*rJens(x).^2).*(normpdf(r,0,varWake(x))./((normcdf(sd,0,1)-normcdf(-sd,0,1))*varWake(x)*sqrt(2*pi))).*cJens(x);
    % The above function is the true equation. The lower one is evaluated for std = 2,  to avoid dependencies on the Statistics Toolbox.
    floris_normpdf = @(x,mu,sigma) (1/(sigma*sqrt(2*pi)))*exp(-(x-mu).^2/(2*sigma.^2)); % to avoid dependencies on the Statistics Toolbox
    cFull = @(x,r) (pi*rJens(x).^2).*(floris_normpdf(r,0,varWake(x))./((P_normcdf_ub-P_normcdf_lb)*varWake(x)*sqrt(2*pi))).*cJens(x);

    % wake.V is an analytical function for flow speed [m/s] in a single wake
    wake.V = @(U,x,y,z) U.*(1-2*a*cFull(x,hypot(y,z)));

    % wake.boundary is a boolean function telling whether a point (y,z) 
    % lies within the wake radius of turbine(i) at distance x        
    wake.boundary = @(x,y,z) hypot(y,z)<( sd*varWake(x));

end

