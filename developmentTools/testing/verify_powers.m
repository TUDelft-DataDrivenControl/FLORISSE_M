function [] = verify_powers(generateData)
cd('../..') % Return by: cd('developmentTools/testing')
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
        for wakeType = {'Zones','NaiveGaussian','Larsen','PorteAgel'}
            for wakeSum = {'Katic','Voutsinas'}
                for deflType = {'Jimenez','PorteAgel'}
                    
                    % Turbine-induced turbulence model
                    if strcmp(wakeType{1},'PorteAgel') || strcmp(deflType{1},'PorteAgel')
                        turbType = {'PorteAgel'};
                    else
                        turbType = wakeType;
                    end
                    
                    % Run simulation
                    FLORIS = floris('generic_9turb','nrel5mw',atmoType{1},controlType{1},wakeType{1},deflType{1},wakeSum{1},...
                        turbType{1},'modelData_testing');
                    FLORIS.run();
                    
                    % Correct naming
                    if strcmp(wakeType{1},'NaiveGaussian')
                        wakeTypeName = {'Gauss'}; % Fix formatting
                    else
                        wakeTypeName = wakeType;
                    end
                    
                    key = [atmoType{1} controlType{1} wakeTypeName{1} wakeSum{1} deflType{1}];
                    if generateData
                        powerData(key) = sum(FLORIS.outputData.power);
                    else
                        % Throw an error message if the difference between
                        % new and old power values is too large.
                        assert(abs(powerData(key) - sum(FLORIS.outputData.power))<1e-5,...
                               sprintf('power data differs at %s', join(key, ', ')));
                    end
                    clear FLORIS
                end
            end
        end
    end
end
cd('developmentTools/testing')
if generateData
    save('newPowData', 'powerData')
else
    disp('Test passed succesfully.')
end