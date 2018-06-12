classdef deflection_models_test < matlab.unittest.TestCase
    %floris_test Summary of this class goes here
    %   Detailed explanation goes here
    properties
        generic6Turb
        controlSet
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
            % Instantiate a layout object with 6 identical turbines
            testCase.generic6Turb = generic_6_turb;

            % Use the height from the first turbine type as reference height for theinflow profile
            refheight = testCase.generic6Turb.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            testCase.generic6Turb.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                                  'PowerLawRefHeight', refheight, ...
                                                  'windDirection', 0, ...
                                                  'TI0', .01);

            % Make a controlObject for this layout
            % controlSet = control_set(layout, 'axialInduction');
            testCase.controlSet = control_set(testCase.generic6Turb, 'pitch');
        end
    end
    methods(Test)
        function test_jimenez_run(testCase)
            import matlab.unittest.constraints.IssuesNoWarnings
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            
            subModels = model_definition('deflectionModel', 'jimenez',...
                                         'velocityDeficitModel', 'selfSimilar',...
                                         'wakeCombinationModel', 'quadraticRotorVelocity',...
                                         'addedTurbulenceModel', 'crespoHernandez');
            florisRunner = floris(testCase.generic6Turb, testCase.controlSet, subModels);
            function runner(); florisRunner.run; end
            testCase.verifyThat(@runner, IssuesNoWarnings)
            [dy, dz] = florisRunner.turbineResults(4).wake.deflection(150);
            testCase.assertThat(dy,IsEqualTo(-8.7983, 'Within', AbsoluteTolerance(1e-4)))
            testCase.assertThat(dz,IsEqualTo(0))
        end
        
        function test_rans_run(testCase)
            import matlab.unittest.constraints.IssuesNoWarnings
            import matlab.unittest.constraints.IsEqualTo
            subModels = model_definition('deflectionModel', 'rans',...
                                         'velocityDeficitModel', 'selfSimilar',...
                                         'wakeCombinationModel', 'quadraticRotorVelocity',...
                                         'addedTurbulenceModel', 'crespoHernandez');
            florisRunner = floris(testCase.generic6Turb, testCase.controlSet, subModels);
            function runner(); florisRunner.run; end
            testCase.verifyThat(@runner, IssuesNoWarnings)
            [dy, dz] = florisRunner.turbineResults(4).wake.deflection(150);
            testCase.verifyThat(dy,IsEqualTo(-6))
            testCase.verifyThat(dz,IsEqualTo(0))
        end
    end
end

