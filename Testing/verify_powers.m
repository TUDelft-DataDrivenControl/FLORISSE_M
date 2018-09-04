function [] = verify_powers(testCase)
% Set generateData to 'false' if nothing specified

generateData = false;
if generateData
    % Generate an empty powerData container
    powerData = containers.Map;
else
    % Import testing functions
    import matlab.unittest.constraints.IsEqualTo;
    import matlab.unittest.constraints.AbsoluteTolerance;
    % Load existing power data .mat file
    sr = strsplit(mfilename('fullpath'), filesep);
    sr(end) = {'testingData'}; sr(end+1) = {'powDat'};
    load(strjoin(sr, filesep))
end

% Test all possible combinations of options
for atmoType = {'uniform','boundary'}
    for controlType = {'pitch','greedy','axialInduction'}
        for wakeType = {'zones','jensenGauss','selfSimilar','larsen'}
            for wakeSum = {'quadraticAmbientVelocity','quadraticRotorVelocity'}
                for deflType = {'jimenez','rans'}
                    
                    layout = tester_9_turb_powers;
                    switch(atmoType{1})
                        case 'uniform'
                            layout.ambientInflow = ambient_inflow_uniform('PowerLawRefSpeed', 12, ...
                                                   'windDirection', .3, ...
                                                   'TI0', .1);
                    	case 'boundary'
                            refheight = layout.uniqueTurbineTypes(1).hubHeight;
                            layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 12, ...
                                                   'PowerLawRefHeight', refheight, ...
                                                   'windDirection',.3, ...
                                                   'TI0', .1);
                    end

                    controlSet = control_set(layout, controlType{1});
                    controlSet.tiltAngleArray = deg2rad([0 10 0 0 -10 0 10 0 0]);
                    controlSet.yawAngleArray = deg2rad([-30 10 -10 -30 -20 -15 0 10 0]);

                    % Define subModels
                    subModels = model_definition('deflectionModel',      deflType{1},...
                                                 'velocityDeficitModel', wakeType{1},...
                                                 'wakeCombinationModel', wakeSum{1},...
                                                 'addedTurbulenceModel', 'crespoHernandez');
                    florisRunner = floris(layout, controlSet, subModels);
                    florisRunner.run
                    %  display(sprintf('power difference is %d between %d and %d',abs(powerData(key) - sum(FLORIS.outputData.power)),powerData(key) , sum(FLORIS.outputData.power)));
                    key = [atmoType{1} controlType{1} wakeType{1} wakeSum{1} deflType{1}];
                    florisTotalPower = florisRunner.turbineResults.power;
                    
                    if generateData
                        powerData(key) = florisTotalPower;
                    else
                        % Throw an error message if the difference between
                        % new and old power values is too large.
                        testCase.assertThat(powerData(key), IsEqualTo(florisTotalPower, ...
                            'Within', AbsoluteTolerance(1e-5)));
                        sprintf('power data differs at %s \n power difference is %d between %d and %d', join(key, ', '),abs(powerData(key) - florisTotalPower), powerData(key) , florisTotalPower);
                    end
                end
            end
        end
    end
end

if generateData
    save('powDatNew', 'powerData')
else
    disp('Test passed succesfully.')
end