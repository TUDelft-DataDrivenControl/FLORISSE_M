function [ wake ] = larsenWake( inputData,turbine,wake )
%LARSENWAKE Summary of this function goes here
%   Detailed explanation goes here

    D = 2*turbine.rotorRadius; % Rotor diameter
    A = pi*turbine.rotorRadius^2; % Rotor swept area [m]
    H = turbine.hub_height;       % Turbine hub height [m]

    RnbLars = D*max(1.08,1.08+21.7*(inputData.IaLars-0.05));
    R95Lars = 0.5*(RnbLars+min(H,RnbLars));
    DeffLars = D*sqrt((1+sqrt(1-turbine.Ct))/(2*sqrt(1-turbine.Ct)));

    x0 = 9.5*D/((2*R95Lars/DeffLars)^3-1);
    c1Lars = (DeffLars/2)^(5/2)*(105/(2*pi))^(-1/2)*(turbine.Ct*A*x0).^(-5/6);

    wake.boundary = @(x,y,z) hypot(y,z)<((35/(2*pi))^(1/5)*(3*(c1Lars)^2)^(1/5)*((x).*turbine.Ct*A).^(1/3));
    wake.V  = @(U,x,y,z) U-U.*((1/9)*(turbine.Ct.*A.*((x0+x).^-2)).^(1/3).*( hypot(y,z).^(3/2).*((3.*c1Lars.^2).*turbine.Ct.*A.*(x0+x)).^(-1/2) - (35/(2.*pi)).^(3/10).*(3.*c1Lars^2).^(-1/5) ).^2);

end

