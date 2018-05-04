% function [outputArg1] = instantiateClasses()
% %instantiateClasses This function instantiates a few classes
% %   Try to generate c-code from this function to see if the current code is
% %   compatible with the matlab coder, use: > codegen instantiateClasses

% Instantiate a layout without ambietInflow conditions
clwindcon9Turb = clwindcon_9_turb(nan);
% Use the heigth us the first turbine type as reference heigth for the
% inflow profile
refHeigth = clwindcon9Turb.uniqueTurbineTypes(1).hubHeight;
% Define an inflow struct and use it in the layout, clwindcon9Turb
ambientInflow = struct('PowerLawRefSpeed',8,'PowerLawRefHeight',refHeigth,...
                       'PowerLawExp',0.3,'windDirection',205,'TI_0',.01);
clwindcon9Turb.ambientInflow = ambientInflow;

% Make a controlObject for this layout
controlSet = control_set(clwindcon9Turb, 'axialInduction');

% Define subModels
subModels = model_definition('deflection', 'jimenez',...
                             'velocityProfile', 'Jensen',...
                             'wakeCombining', 'quadratic',...
                             'other1', 'otherDef');
florisRunner = floris(clwindcon9Turb, controlSet, subModels);


                         


con0 = control_set(clwindcon9Turb, 'axialInduction');

sit = strong_wind_6_turb;
con0 = control_set(clwindcon9Turb, 'pitch');
lay = scaled_2_turb;
con1 = control_set(lay, 'pitch');
lay2 = generic_6_turb;
con2 = control_set(lay2, 'greedy');
lay3 = two_heigths_6_turb;
con3 = control_pitch_turb_1(lay3);


lay3 = dtu_nrel_6_turb;
con3 = control_set(lay3, 'axialInduction');
% subModels


sit.turbines(1).turbineType.cPcTpower(12,4.2*pi/180)

dtu_nrel_6_turb
outputArg1 = lay3.locIf
% end
