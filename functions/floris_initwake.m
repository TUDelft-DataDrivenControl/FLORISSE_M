function [ wake ] = floris_initwake( inputData,turbine,wake )
% This function computes the coefficients that determine wake behaviour.
% The initial deflection and diameter of the wake are also computed.

    % Calculate initial wake diameter
    if inputData.adjustInitialWakeDiamToYaw
        wake.wakeRadiusInit = turbine.rotorRadius*cos(turbine.ThrustAngle);
    else
        wake.wakeRadiusInit = turbine.rotorRadius;
    end
    
    %% Determine the velocity deficit and location for a single wake
    % This can be according to a number of choices, namely the standard
    % FLORIS model with 3 discrete wake zones. Also a Gaussian wake shape
    % can be assumed, among others.
    switch inputData.wakeType
    case 'floris_zones' % FLORIS wake zones model with 3 discrete deficit profiles
        wake = zonedWake( inputData,turbine,wake );

    case 'jensen_gauss' % Gaussian wake profile shape
        wake = naiveGaussianWake( inputData,turbine,wake );

    case 'larsen' % Larsen (2006) wake profile
        wake = larsenWake( inputData,turbine,wake );

    case 'porteagel' % Wake shape from Porte-Agel
        wake = porteAgelWake( inputData,turbine,wake );

    otherwise
        error(['Wake type with name: "' inputData.wakeType '" not defined']);
    end

end