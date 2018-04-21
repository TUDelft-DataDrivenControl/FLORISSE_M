function [] = verify_powers(generateData)
cd('../FLORIS') % Return by: cd('../Testing')
% Set generateData to 'false' if nothing specified
if nargin == 0
    generateData = false;
end

if generateData
    % Generate an empty powerData container
    powerData = containers.Map;
else
    % Load existing power data .mat file
    sr = strsplit(mfilename('fullpath'), filesep);
    sr(end) = {'testingData'}; sr(end+1) = {'powDat'};
    load(strjoin(sr, filesep))
end

% Test all possible combinations of options
for atmoType = {'uniform','boundary'}
    for controlType = {'pitch','greedy','axialInduction'}
        for wakeType = {'Zones','JensenGaussian','Larsen','PorteAgel'}
            for wakeSum = {'Katic','Voutsinas'}
                for deflType = {'Jimenez','PorteAgel'}
                    
                    % Turbine-induced turbulence model
                    if strcmp(wakeType{1},'PorteAgel') || strcmp(deflType{1},'PorteAgel')
                        turbulType = {'PorteAgel'};
                    else
                        turbulType = wakeType;
                    end
                    
                    % Run simulation
                    FLORIS = floris('verifyPowers_9turb','nrel5mw',atmoType{1},controlType{1},wakeType{1},deflType{1},wakeSum{1},...
                        turbulType{1},'modelData_testing');
                    FLORIS.run();
                    key = [atmoType{1} controlType{1} wakeType{1} wakeSum{1} deflType{1}];
                    %  display(sprintf('power difference is %d between %d and %d',abs(powerData(key) - sum(FLORIS.outputData.power)),powerData(key) , sum(FLORIS.outputData.power)));
                    
                    if generateData
                        powerData(key) = sum(FLORIS.outputData.power);
                    else
                        % Throw an error message if the difference between
                        % new and old power values is too large.
                        assert(abs(powerData(key) - sum(FLORIS.outputData.power))<1e-5,...
                               sprintf('power data differs at %s \n power difference is %d between %d and %d', join(key, ', '),abs(powerData(key) - sum(FLORIS.outputData.power)), powerData(key) , sum(FLORIS.outputData.power)));
                    end
                    clear FLORIS
                end
            end
        end
    end
end
cd('../Testing')
if generateData
    save('newPowData', 'powerData')
else
    disp('Test passed succesfully.')
end