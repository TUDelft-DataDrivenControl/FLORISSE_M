function [outputArg1,outputArg2] = zoned_velocity(inputArg1,inputArg2)
%ZONED_VELOCITY Summary of this function goes here
%   Detailed explanation goes here

a = turbine.axialInd;

% Calculate ke, the basic expansion coefficient
wake.Ke = modelData.Ke + modelData.KeCorrCT*(turbine.Ct-modelData.baselineCT);

% Calculate mU, the zone multiplier for different wake zones
if modelData.useaUbU
    wake.mU = modelData.MU/cos(modelData.aU+modelData.bU*turbine.YawWF);
else
    wake.mU = modelData.MU;
end

% Radius of wake zones [m]
wake.rZones = @(x,zone) max(wake.wakeRadiusInit+wake.Ke.*modelData.me(zone)*x,0*x);

% Center location of wake zones [m]
wake.cZones = @(x,zone) (wake.wakeRadiusInit./(wake.wakeRadiusInit + wake.Ke.*wake.mU(zone).*x)).^2;

% cFull is the wake intensity reduction factor
cFull = @(x,r) ((abs(r)<=wake.rZones(x,3))-(abs(r)<wake.rZones(x,2))).*wake.cZones(x,3)+...
    ((abs(r)<wake.rZones(x,2))-(abs(r)<wake.rZones(x,1))).*wake.cZones(x,2)+...
    (abs(r)<wake.rZones(x,1)).*wake.cZones(x,1);

% wake.V is an analytical function for flow speed [m/s] in a single wake
wake.V = @(U,x,y,z) U.*(1-2*a*cFull(x,hypot(y,z)));

% wake.boundary is a boolean function telling whether a point (y,z)
% lies within the wake radius of turbine(i) at distance x
wake.boundary = @(x,y,z) hypot(y,z)<(wake.rZones(x,3));

end

