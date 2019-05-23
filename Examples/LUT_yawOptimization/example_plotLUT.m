% Example with raw LUT
databaseLUT = importYawLUT('LUTs/LUT_6turb_yaw.csv');
plotLUTYawWD(databaseLUT,1);

% Example with evaluated LUT
load('LUTs/LUT_6turb_yawFiltered.deter.mat');
plotLUTYawWD(databaseLUTout,1);