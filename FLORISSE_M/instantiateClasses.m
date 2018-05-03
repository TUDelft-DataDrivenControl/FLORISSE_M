function [outputArg1] = instantiateClasses()
%instantiateClasses This function instantiates a few classes
%   Try to generate c-code from this function to see if the current code is
%   compatible with the matlab coder, use: > codegen instantiateClasses

sit = strong_wind_6_turb;
con0 = control_prototype(sit, 'pitch');
% lay = scaled_2_turb;
% con1 = control_prototype(lay, 'pitch');
% lay2 = generic_6_turb;
% con2 = control_prototype(lay2, 'greedy');
lay3 = two_heigths_6_turb;
con3 = pitch_control_yaw_first(lay3);
% lay3 = dtu_nrel_6_turb;
% con3 = control_prototype(lay3, 'axialInduction');

% sit.uniqueTurbineTypes{1}.cp(12,4.2*pi/180)
% sit.uniqueTurbineTypes{1}.cp(4.1,4.3)
% sit.uniqueTurbineTypes{1}.cp(4,3.5)

% dtu_nrel_6_turb
outputArg1 = lay3.locIf
end