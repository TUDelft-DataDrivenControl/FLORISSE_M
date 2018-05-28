classdef control_set_default_nans_test < matlab.unittest.TestCase
    %INSPECTLAYOUTSTEST Summary of this class goes here
    %   Detailed explanation goes here
    properties
        layout
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
            % Instantiate a layout object with 9 identical turbines
            generic6Turb = generic_6_turb;

            % Use the heigth us the first turbine type as reference heigth for theinflow profile
            refHeigth = generic6Turb.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            generic6Turb.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                                          'PowerLawRefHeight', refHeigth, ...
                                                          'windDirection', pi/2, ...
                                                          'TI0', .01);
            testCase.layout = generic6Turb;
        end
    end
    methods(Test)
        function test_axial_induction(testCase)
            %test_axial_induction Test that the control signals that are
            %not used are properly set to nan
            
            import matlab.unittest.constraints.HasNaN
            % Make a controlObject for this layout
            controlSet = control_set(testCase.layout, 'axialInduction');
            for i = 1:testCase.layout.nTurbs
                testCase.verifyThat(controlSet.turbineControls(i).pitchAngle, HasNaN)
            end
        end
        function test_pitch(testCase)
            %test_pitch Test that the control signals that are
            %not used are properly set to nan
            
            import matlab.unittest.constraints.HasNaN
            % Make a controlObject for this layout
            controlSet = control_set(testCase.layout, 'pitch');
            for i = 1:testCase.layout.nTurbs
                testCase.verifyThat(controlSet.turbineControls(i).axialInduction, HasNaN)
            end
        end
        function test_greedy(testCase)
            %test_greedy Test that the control signals that are
            %not used are properly set to nan
            
            import matlab.unittest.constraints.HasNaN
            % Make a controlObject for this layout
            controlSet = control_set(testCase.layout, 'greedy');
            for i = 1:testCase.layout.nTurbs
                testCase.verifyThat(controlSet.turbineControls(i).pitchAngle, HasNaN)
                testCase.verifyThat(controlSet.turbineControls(i).axialInduction, HasNaN)
            end
        end
    end
end

