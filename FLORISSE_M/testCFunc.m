function [outputArg1] = testCFunc()
%TESTCFUNC Summary of this function goes here
%   Detailed explanation goes here
sit = strong_wind_6_turb;
con1 = greedyControl(sit);
lay2 = generic_6_turb;
con2 = greedyControl(lay2);
% lay3 = two_heigths_6_turb;
% con3 = greedyControl(lay3);
outputArg1 = sit.locIf
end

