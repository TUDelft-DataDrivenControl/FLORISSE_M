% function [outputArg1] = instantiateClasses()
% %instantiateClasses This function instantiates a few classes
% %   Try to generate c-code from this function to see if the current code is
% %   compatible with the matlab coder, use: > codegen instantiateClasses

sit = strong_wind_6_turb;
con0 = control_set(sit, 'pitch');
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
