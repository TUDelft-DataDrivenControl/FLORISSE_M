% Define rotor blade induced wake displacement
inputData.ad = -4.5;   % lateral wake displacement bias parameter (a + bx)
inputData.bd = -0.01;  % lateral wake displacement bias parameter (a + bx)
inputData.at = 0.0;    % vertical wake displacement bias parameter (a + bx)
inputData.bt = 0.0;    % vertical wake displacement bias parameter (a + bx)

run('../deficit_models/porteagel.m'); % Identical to deflection model