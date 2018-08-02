classdef load_save_test < matlab.unittest.TestCase
    %floris_test Summary of this class goes here
    %   Detailed explanation goes here
    properties
        florisRunner
    end
    methods(TestMethodSetup)
        function setFolders(testCase)
            % Add the relevant folders to the current path
            import matlab.unittest.fixtures.PathFixture
            
            testCase.applyFixture(PathFixture('../FLORISSE_M/coreFunctions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/layoutDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/ambientFlowDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/controlDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/submodelDefinitions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/visualizationTools',...
                                              'IncludeSubfolders',true));                                          
                                          
            % Instantiate a layout object with 6 identical turbines
            layout = tester_6_turb_5D;

            % Use the height from the first turbine type as reference height for theinflow profile
            refheight = layout.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                                  'PowerLawRefHeight', refheight, ...
                                                  'windDirection', 0.3, ...
                                                  'TI0', .01);

            % Make a controlObject for this layout
            controlSet = control_set(layout, 'pitch');
            
            % Define subModels
            subModels = model_definition('deflectionModel', 'jimenez',...
                                         'velocityDeficitModel', 'selfSimilar',...
                                         'wakeCombinationModel', 'quadraticRotorVelocity',...
                                         'addedTurbulenceModel', 'crespoHernandez');
            testCase.florisRunner = floris(layout, controlSet, subModels);
            
        end
    end
    methods(Test)        
        function check_save_load(testCase)
            florisRunner = testCase.florisRunner;
            florisRunner.run;
            powerTrue = [florisRunner.turbineResults.power];
            florisRunner.clearOutput();
            
            save('deleteme_florisObj.mat','florisRunner');
            clear florisRunner
            
            load('deleteme_florisObj.mat');
            delete 'deleteme_florisObj.mat'; % delete file
            
            florisRunner.run;
            powerEst = [florisRunner.turbineResults.power];
            
            % Validate
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            testCase.assertThat(powerTrue, IsEqualTo(powerEst, ...
                'Within', AbsoluteTolerance(1e-5)));
        end
    end
end

