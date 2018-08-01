function [uProbe] = compute_probes(florisObj,x,y,z,fixYaw);
%
% This function computes the flow velocity at a (vector of) location(s)
% (x,y,z) in the wind farm. For a rectangular grid, one should use the
% compute_flow_field.m function. For a small number or an arbitrary
% selection of flow measurements (e.g., probes), one can use this function.
%
% By: Bart Doekemeijer
%

    % Set-up the FLORIS object, exporting the variables of interest
    layout               = florisObj.layout;
    turbineResults       = florisObj.turbineResults;
    yawAngles            = florisObj.controlSet.yawAngles;
    avgWs                = [florisObj.turbineConditions.avgWS];
    wakeCombinationModel = florisObj.model.wakeCombinationModel;
    
    if nargin < 5
        fixYaw = false;
    end
    
    % Calculate velocity for a 1x1x1 "flow field" for every probe location
    Uin    = layout.ambientInflow.Vfun(z);
    uProbe = zeros(size(x));
    for i = 1:length(x)
        flowField = struct('X',x(i),'Y',y(i),'Z',z(i),'U',Uin(i));
        flowField = compute_flow_field(flowField, layout, turbineResults, ...
                                           yawAngles, avgWs, fixYaw, wakeCombinationModel);
        uProbe(i) = flowField.U;
    end
end