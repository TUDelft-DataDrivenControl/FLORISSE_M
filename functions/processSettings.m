function [inputData] = processSettings(inputData)
%CONFIGSETTINGS Calculate variables derived from the raw inputData

% Compute windDirection in the inertial frame, and the wind-aligned flow speed (uInfWf)
inputData.windDirection = atan(inputData.vInfIf/inputData.uInfIf); % Wind dir in radians (inertial frame)
inputData.uInfWf        = hypot(inputData.uInfIf,inputData.vInfIf); % axial flow speed in wind frame

% Atmosphere characteristics
switch inputData.atmoType
    case 'boundary'
        % initialize the flow field used in the 3D model based on shear using the power log law
        inputData.Ufun = @(z) inputData.uInfWf.*(z./inputData.hub_height(1)).^inputData.shear;
    case 'uniform'
        inputData.Ufun = @(z) inputData.uInfWf;
    otherwise
        error(['Atmosphere type with name "' atmoType '" not defined']);
end

% Wake deflection characteristics
if strcmp(inputData.deflType,'PorteAgel')
    inputData.ky    = @(I) inputData.ka*I + inputData.kb;
    inputData.kz    = @(I) inputData.ka*I + inputData.kb;
end

