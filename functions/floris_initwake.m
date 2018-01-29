function [ wake ] = floris_initwake( inputData,turbine,wake )
% This function computes the coefficients that determine wake behaviour.
% The initial deflection and diameter of the wake are also computed.

    % Calculate initial wake diameter
    if inputData.wakeModel.adjustInitialWakeDiamToYaw
        wake.wakeRadiusInit = turbine.rotorRadius*cos(turbine.ThrustAngle);
    else
        wake.wakeRadiusInit = turbine.rotorRadius;
    end
    
    %% Determine the velocity deficit and location for a single wake
    % This can be according to a number of choices, namely the standard
    % FLORIS model with 3 discrete wake zones. Also a Gaussian wake shape
    % can be assumed, among others.    
    wake = inputData.wakeModel.deficit( inputData,turbine,wake );
end