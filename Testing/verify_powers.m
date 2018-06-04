% function [] = verify_powers(generateData)
% cd('../FLORIS') % Return by: cd('../Testing')
% Set generateData to 'false' if nothing specified
% if nargin == 0
    generateData = false;
% end

if generateData
    % Generate an empty powerData container
    powerData = containers.Map;
else
    % Load existing power data .mat file
    sr = strsplit(mfilename('fullpath'), filesep);
    sr(end) = {'testingData'}; sr(end+1) = {'powDat'};
    load(strjoin(sr, filesep))
end
keyConverter = containers.Map;
oldKeys = keys(powerData);
newKeys = oldKeys;
for i = 1:length(oldKeys)
    newKeys(i) = strrep(oldKeys(i),'Katic','quadraticAmbientVelocity');
end
for i = 1:length(oldKeys)
    newKeys(i) = strrep(newKeys(i),'Voutsinas','quadraticRotorVelocity');
end
for i = 1:length(oldKeys)
    newKeys(i) = strrep(newKeys(i),'VelocityPorteAgel','Velocityrans');
end
for i = 1:length(oldKeys)
    newKeys(i) = strrep(newKeys(i),'Jimenez','jimenez');
end
for i = 1:length(oldKeys)
    newKeys(i) = strrep(newKeys(i),'Zones','zones');
end
for i = 1:length(oldKeys)
    newKeys(i) = strrep(newKeys(i),'JensenGaussian','jensenGauss');
end
for i = 1:length(oldKeys)
    newKeys(i) = strrep(newKeys(i),'Larsen','larsen');
end
for i = 1:length(oldKeys)
    newKeys(i) = strrep(newKeys(i),'PorteAgel','selfSimilar');
end
for i = 1:length(oldKeys)
    keyConverter(newKeys{i}) = oldKeys{i};
end


newPowers = [];
oldPowers = [];

% Test all possible combinations of options
for atmoType = {'uniform','boundary'}
    for controlType = {'pitch','greedy','axialInduction'}
        for wakeType = {'zones','jensenGauss','larsen','selfSimilar'}
            for wakeSum = {'quadraticAmbientVelocity','quadraticRotorVelocity'}
                for deflType = {'jimenez','rans'}
                    
                    layout = tester_9_turb_powers;
                    switch(atmoType{1})
                        case 'uniform'
                            layout.ambientInflow = ambient_inflow_uniform('PowerLawRefSpeed', 12, ...
                                                   'windDirection', .3, ...
                                                   'TI0', .1);
                    	case 'boundary'
                            refHeigth = layout.uniqueTurbineTypes(1).hubHeight;
                            layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 12, ...
                                                   'PowerLawRefHeight', refHeigth, ...
                                                   'windDirection',.3, ...
                                                   'TI0', .1);
                    end

                    controlSet = control_set(layout, controlType{1});
                    controlSet.tiltAngles = deg2rad([0 10 0 0 -10 0 10 0 0]);
                    controlSet.yawAngles = deg2rad([-30 10 -10 -30 -20 -15 0 10 0]);

                    % Define subModels
                    subModels = model_definition('deflectionModel',      deflType{1},...
                                                 'velocityDeficitModel', wakeType{1},...
                                                 'wakeCombinationModel', wakeSum{1},...
                                                 'addedTurbulenceModel', 'crespoHernandez');
                    florisRunner = floris(layout, controlSet, subModels);
                    florisRunner.run
%                     keyboard
                    %  display(sprintf('power difference is %d between %d and %d',abs(powerData(key) - sum(FLORIS.outputData.power)),powerData(key) , sum(FLORIS.outputData.power)));
                    key = [atmoType{1} controlType{1} wakeType{1} wakeSum{1} deflType{1}];
                    if generateData
                        powerData(keyConverter(key)) = sum(FLORIS.outputData.power);
                    else
                        % Throw an error message if the difference between
                        % new and old power values is too large.
%                         if strcmp(key, 'uniformpitchlarsenquadraticAmbientVelocityjimenez')
%                             keyboard
%                         end
                        display(key)
                        newPowers = [newPowers sum([florisRunner.turbineResults.power])];
                        oldPowers = [oldPowers powerData(keyConverter(key))];
                        sprintf('OrigPower = %d, newPower = %d', powerData(keyConverter(key)), sum([florisRunner.turbineResults.power]))
%                         assert(abs(powerData(keyConverter(key)) - sum(FLORIS.outputData.power))<1e-5,...
%                                sprintf('power data differs at %s \n power difference is %d between %d and %d', join(key, ', '),abs(powerData(key) - sum(FLORIS.outputData.power)), powerData(key) , sum(FLORIS.outputData.power)));
                    end
%                     clear FLORIS
                end
            end
        end
    end
end
[~, idxs] = sort(newPowers);
figure; plot(1:length(newPowers), newPowers, 1:length(newPowers), oldPowers)
% plot(1:length(newPowers), newPowers(idxs), 1:length(newPowers), oldPowers(idxs))
cd('../Testing')
% if generateData
%     save('newPowData', 'powerData')
% else
%     disp('Test passed succesfully.')
% end