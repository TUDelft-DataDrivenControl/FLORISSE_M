function [ wake ] = floris_wakeCenterLinePosition( inputData,turbine,wake )
%Compute the wake centerline position using the method explained by Jimenez
%or PorteAgel.

    % Displacement between location 'x' and current turbine
    deltaxs = wake.centerLine(1,:)-turbine.LocWF(1);
    [wake] = inputData.wakeModel.centerline(deltaxs,turbine,inputData);
end