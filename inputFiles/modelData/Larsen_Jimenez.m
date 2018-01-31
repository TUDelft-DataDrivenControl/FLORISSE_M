function [modelData] = Larsen_Jimenez()
%% PORTEAGEL_DEFAULT
%  loads the default set of model parameters for the Porte-Agel deficit and
%  wake deflection model.
%

%% General parameters
modelData.adjustInitialWakeDiamToYaw = false; % Adjust the intial swept surface overlap

% Blade-rotation-induced wake deflection
modelData.ad = -4.5;   % lateral wake displacement bias parameter (a + bx)
modelData.bd = -0.01;  % lateral wake displacement bias parameter (a + bx)
modelData.at = 0.0;    % vertical wake displacement bias parameter (a + bx)
modelData.bt = 0.0;    % vertical wake displacement bias parameter (a + bx)


%% Parameters specific for the Jimenez model
modelData.KdY = 0.17; % Wake deflection recovery factor
modelData.useWakeAngle = true; % define initial wake displacement and angle (not determined by yaw angle)
modelData.kd = deg2rad(1.5);   % initialWakeAngle in X-Y plane

%% Parameters specific for the Larsen model
inputData.IaLars = 0.1; % ambient turbulence
end