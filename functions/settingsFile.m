function [inputData] = settingsFile(siteType,turbType,atmoType,controlType,wakeType,wakeSum,deflType)
inputData.deflType   = deflType; % Write deflection  model choice to inputData
inputData.wakeType   = wakeType; % Write single wake model choice to inputData
inputData.atmoType   = atmoType; % Write atmospheric model choice to inputData


%% Wake deflection model choice
% Herein we define the wake deflection model we want to use, which can be
% either from Jimenez et al. (2009) with doi:10.1002/we.380, or from 
% Bastankah and Porte-Agel (2016) with doi:10.1017/jfm.2016.595. The
% traditional FLORIS uses Jimenez, while the new FLORIS model presented
% by Annoni uses Porte-Agel's deflection model.
% try
%     run(['settings/deflection_models/' deflType]);        
% catch
%     error(['Deflection type with name "' deflType '" not defined']);
% end

%% Wake deficit model choice
% Herein we define how we want to model the shape of our wake (looking at
% the y-z slice). The traditional FLORIS model uses three discrete zones,
% 'Zones', but more recently a Gaussian wake profile 'Gauss' has seemed to 
% better capture the wake shape with less tuning parameters. This idea has
% further been explored by Bastankah and Porte-Agel (2016), which led to
% the 'PorteAgel' wake deficit model.
% try
%     run(['settings/deficit_models/' wakeType])
% catch
%     error(['Wake type with name: "' wakeType '" not found']);
% end


%% Wake summing methodology
% inputData.wakeSum = wakeSum; % Wake addition method ('Katic','Voutsinas')


%% Turbine axial control methodology
% Herein we define how the turbine are controlled. In the traditional
% FLORIS model, we directly control the axial induction factor of each
% turbine. However, to apply this in practise, we still need a mapping to
% the turbine generator torque and the blade pitch angles. Therefore, we
% have implemented the option to directly control and optimize the blade
% pitch angles 'pitch', under the assumption of optimal generator torque
% control. Additionally, we can also assume fully greedy control, where we
% cannot adjust the generator torque nor the blade pitch angles ('greedy').


switch controlType
    case {'pitch'}
        % Choice of how a turbine's axial control setting is determined
        % 0: use pitch angles and Cp-Ct LUTs for pitch and WS, 
        % 1: greedy control   and Cp-Ct LUT for WS,
        % 2: specify axial induction directly.
        inputData.axialControlMethod = 0;  
        inputData.pitchAngles = zeros(1,nTurbs); % Blade pitch angles, by default set to greedy
        inputData.axialInd    = nan*ones(1,nTurbs); % Axial inductions  are set to NaN to find any potential errors
        
        % Determine Cp and Ct interpolation functions as a function of WS and blade pitch
        for airfoilDataType = {'cp','ct'}
            lut       = csvread(['settings/turbines/' turbType '/' airfoilDataType{1} 'Pitch.csv']); % Load file
            lut_ws    = lut(1,2:end);          % Wind speed in LUT in m/s
            lut_pitch = deg2rad(lut(2:end,1)); % Blade pitch angle in LUT in radians
            lut_value = lut(2:end,2:end);      % Values of Cp/Ct [dimensionless]
            inputData.([airfoilDataType{1} '_interp']) = @(ws,pitch) interp2(lut_ws,lut_pitch,lut_value,ws,pitch);
        end
        
    % Greedy control: we cannot adjust gen torque nor blade pitch
    case {'greedy'} 
        inputData.axialControlMethod = 1;
        inputData.pitchAngles = nan*ones(1,nTurbs); % Blade pitch angles are set to NaN to find any potential errors
        inputData.axialInd    = nan*ones(1,nTurbs); % Axial inductions  are set to NaN to find any potential errors
        
        % Determine Cp and Ct interpolation functions as a function of WS
        lut                 = load(['settings/turbines/' turbType '/cpctgreedy.mat']);
        inputData.cp_interp = @(ws) interp1(lut.wind_speed,lut.cp,ws);
        inputData.ct_interp = @(ws) interp1(lut.wind_speed,lut.ct,ws);
     
    % Directly adjust the axial induction value of each turbine.
    case {'axialInduction'}
        inputData.axialControlMethod = 2;
        inputData.pitchAngles = nan*ones(1,nTurbs); % Blade pitch angles are set to NaN to find any potential errors
        inputData.axialInd    = 1/3*ones(1,nTurbs); % Axial induction factors, by default set to greedy
      
    otherwise
        error(['Model type with name: "' controlType '" not defined']);
end
end
