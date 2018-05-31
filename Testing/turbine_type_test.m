classdef turbine_type_test < matlab.unittest.TestCase
    %turbine_type_test Summary of this class goes here
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
            layout = tester_5_turb_05D;

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
                                         'wakeCombinationModel', 'quadratic',...
                                         'addedTurbulenceModel', 'crespoHernandez');
            testCase.florisRunner = floris(layout, controlSet, subModels);
        end
    end
    methods(Test)
        function set_wind_direction_for_invalid_windspeed(testCase)
            %testGeneric6Turb Test some attributes of a 6 turb layout
            %   Test if there is only one unique turbine type and test that
            %   there are 6 turbines in the layout
            
            % Check that yaw and tilt angles throw errors when setting
            function runner(); testCase.florisRunner.run; end
            testCase.assertError(@runner, 'cPcTpower:valueError')
        end
    end
end

