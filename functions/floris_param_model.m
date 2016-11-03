function [ model ] = floris_parameters( name )
    switch lower(name)
        case 'default' %% original tuning parameters
        model.pP              = 1.88; % yaw power correction parameter
        model.ke              = 0.05; % wake expansion parameters
        % model.keCorrArray     = 0.0; % array-correction factor: NOT YET IMPLEMENTED!
        model.keCorrCT        = 0.0; % CT-correction factor
        model.baselineCT      = 4.0*(1.0/3.0)*(1.0-(1.0/3.0)); % Baseline CT for ke-correction
        model.me              = [-0.5, 0.22, 1.0]; % relative expansion of wake zones
        model.kd              = 0.17; % wake deflection recovery factor

        % define initial wake displacement and angle (not determined by yaw angle)
        model.useWakeAngle            = true;
        model.initialWakeDisplacement = -4.5;
        model.initialWakeAngle        = 1.5;
        model.bd                      = -0.01;

        % correction recovery coefficients with yaw
        model.useaUbU = true;
        model.aU      = 12.0; % units: degrees
        model.bU      = 1.3;

        model.MU               = [0.5, 1.0, 5.5];
        model.CTcorrected      = false;  % CT factor already corrected by CCBlade calculation (approximately factor cos(yaw)^2)
        model.CPcorrected      = false;  % CP factor already corrected by CCBlade calculation (assumed with approximately factor cos(yaw)^3)
        model.axialIndProvided = false;

        % adjust initial wake diameter to yaw
        model.adjustInitialWakeDiamToYaw = false;

        % shear layer (only influences visualization)
        % model.shearCoefficientAlpha   = 0.10805;
        % model.shearZh                 = 90;
        otherwise
            error(['Model parameters with name "' model.name '" not defined']);
    end;
end

