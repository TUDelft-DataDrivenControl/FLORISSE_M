clear all; close all; clc;

addpath functions
addpath NREL5MW

inputData  = floris_loadSettings('default','NREL5MW','9turb');
outputData = floris_core(inputData);
powerTotal = sum(outputData.power)