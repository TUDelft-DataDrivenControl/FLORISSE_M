function [florisRunner] = generateFlorisRunner(layout)

% Generate temporary ambient conditions
layout.ambientInflow = ambient_inflow_uniform('windSpeed', 8.0, ...
    'windDirection', 0, 'TI0', 0.06);

% Make a controlObject for this layout
if any(strcmp(layout.uniqueTurbineTypes.allowableControlMethods,'yawAndRelPowerSetpoint'))
    controlSet  = control_set(layout , 'yawAndRelPowerSetpoint');
else
    controlSet  = control_set(layout , 'greedy');
end

% Define subModels
subModels  = model_definition('deflectionModel','rans',...
    'velocityDeficitModel', 'selfSimilar',...
    'wakeCombinationModel', 'quadraticRotorVelocity',...
    'addedTurbulenceModel', 'crespoHernandez');

subModels .modelData.TIa = 7.841152377297512;
subModels .modelData.TIb = 4.573750238535804;
subModels .modelData.TIc = 0.431969955023207;
subModels .modelData.TId = -0.246470535856333;
subModels .modelData.ad = 0.001117233213458;
subModels .modelData.alpha = 1.087617055657293;
subModels .modelData.bd = -0.007716521497980;
subModels .modelData.beta = 0.221944783863084;
subModels .modelData.ka = 0.536850894208880;
subModels .modelData.kb = -0.000847912134732;

% Initialize the FLORIS object and run the simulation
florisRunner  = floris(layout, controlSet, subModels);
end

