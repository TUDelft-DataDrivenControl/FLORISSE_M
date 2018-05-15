function [modelData] = linear_wake_deflection(modelData)
%LINEARWAKEDEFLECTION Summary of this function goes here
%   Detailed explanation goes here

% Blade-rotation-induced wake deflection
modelData.ad = -4.5/126.4; % lateral wake displacement bias parameter (a*Drotor + bx)
modelData.bd = -0.01;      % lateral wake displacement bias parameter (a*Drotor + bx)
modelData.at = 0.0;        % vertical wake displacement bias parameter (a*Drotor + bx)
modelData.bt = 0.0;        % vertical wake displacement bias parameter (a*Drotor + bx)

end

