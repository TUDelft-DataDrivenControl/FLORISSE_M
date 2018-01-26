% Define rotor blade induced wake displacement
inputData.ad = -4.5;   % lateral wake displacement bias parameter (a + bx)
inputData.bd = -0.01;  % lateral wake displacement bias parameter (a + bx)
inputData.at = 0.0;    % vertical wake displacement bias parameter (a + bx)
inputData.bt = 0.0;    % vertical wake displacement bias parameter (a + bx)

% For a more detailed explanation of these parameters, see the
% paper with doi:10.1002/we.1993 by Gebraad et al. (2016).
% correction recovery coefficients with yaw
inputData.KdY = 0.17; % Wake deflection recovery factor
% define initial wake displacement and angle (not determined by yaw angle)
inputData.useWakeAngle = true;
inputData.kd = deg2rad(1.5);  % initialWakeAngle in X-Y plane