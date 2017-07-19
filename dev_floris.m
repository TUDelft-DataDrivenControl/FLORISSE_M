clear all; close all; clc;

addpath functions
addpath NREL5MW

inputData  = floris_loadSettings('default','NREL5MW','9turb');

for i = 0:0.1:5
    inputData.pitchAngles = deg2rad(i)*ones(1,9);
    outputData = floris_core(inputData);
    powerTotal = sum(outputData.power)
end;