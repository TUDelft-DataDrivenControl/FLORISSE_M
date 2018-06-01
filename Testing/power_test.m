classdef power_test < matlab.unittest.TestCase
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
            testCase.applyFixture(PathFixture('../FLORISSE_M/helperObjects'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/submodelDefinitions',...
                                              'IncludeSubfolders',true));
            % Instantiate a layout object with 6 identical turbines
            layout = tester_6_turb_5D;

            % Use the heigth from the first turbine type as reference heigth for theinflow profile
            refHeigth = layout.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                                  'PowerLawRefHeight', refHeigth, ...
                                                  'windDirection', 0, ...
                                                  'TI0', .01);

            % Make a controlObject for this layout
            % controlSet = control_set(layout, 'axialInduction');
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
        function test_standard_run(testCase)
            testCase.florisRunner.run
            actpowers = [testCase.florisRunner.turbineResults.power];
            expectedPowers = [1705362.030372323   1705362.030372323   1705362.030372323   0350069.973068104   0350069.973068104   0350069.973068104];

            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            testCase.assertThat(expectedPowers, IsEqualTo(actpowers, ...
                'Within', AbsoluteTolerance(1e-5)));
        end
    end
end

