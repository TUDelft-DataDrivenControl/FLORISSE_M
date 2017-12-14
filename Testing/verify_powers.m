function [] = verify_powers(generateData)
% Set generateData to zero for testing
if generateData
    powerData = containers.Map;
else
    sr = strsplit(mfilename('fullpath'), filesep);
    sr(end) = {'testingData'}; sr(end+1) = {'powDat'};
    load(strjoin(sr, filesep))
end

% Test all possible combinations of options
for atmoType = {'uniform','boundary'}
    for controlType = {'pitch','greedy','axialInduction'}
        for wakeType = {'Zones','Gauss','Larsen','PorteAgel'}
            for wakeSum = {'Katic','Voutsinas'}
                for deflType = {'Jimenez','PorteAgel'}
                    FLORIS = floris('9turb','NREL5MW',atmoType{1},controlType{1},wakeType{1},wakeSum{1},deflType{1});
                    FLORIS.run();
                    key = [atmoType{1} controlType{1} wakeType{1} wakeSum{1} deflType{1}];
                    if generateData
                        powerData(key) = sum(FLORIS.outputData.power);
                    else
                        assert(powerData(key) == sum(FLORIS.outputData.power),...
                               sprintf('power data incorrect at %s', join(key, ', ')));
                    end
                    clear FLORIS
                end
            end
        end
    end
end
if generateData
    save('newPowData', 'powerData')
end