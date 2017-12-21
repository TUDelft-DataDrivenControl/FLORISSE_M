function [inputData] = floris_loadSettings(siteType,turbType,atmoType,controlType,wakeType,wakeSum,deflType)
% Load and process the settings for the FLORIS model
inputData = settingsFile(siteType,turbType,atmoType,controlType,wakeType,wakeSum,deflType);
inputData = processSettings(inputData);
end
