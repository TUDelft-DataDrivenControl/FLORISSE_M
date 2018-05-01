function [outputArg1] = instantiateClasses()
%instantiateClasses This function instantiates a few classes
%   Try to generate c-code from this function to see if the current code is
%   compatible with the matlab coder, use: > codegen instantiateClasses
sit = strong_wind_6_turb;
con1 = greedyControl(sit);
lay2 = generic_6_turb;
con2 = greedyControl(lay2);
lay3 = two_heigths_6_turb;
con3 = greedyControl(lay3);

outputArg1 = lay3.locIf
end
