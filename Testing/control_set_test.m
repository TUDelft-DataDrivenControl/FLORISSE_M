classdef control_set_test < matlab.unittest.TestCase
    %INSPECTLAYOUTSTEST Summary of this class goes here
    %   Detailed explanation goes here
    properties
        controlSet
    end
    methods(TestMethodSetup)
        function setFolders(testCase)
            % Add the relevant folders to the current path
            import matlab.unittest.fixtures.PathFixture
            
            testCase.applyFixture(PathFixture('../FLORISSE_M/coreFunctions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/layoutDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/helperObjects'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
            % Instantiate a layout object with 9 identical turbines
            clwindcon9Turb = clwindcon_9_turb;

            % Use the heigth us the first turbine type as reference heigth for theinflow profile
            refHeigth = clwindcon9Turb.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            clwindcon9Turb.ambientInflow = ambient_inflow('PowerLawRefSpeed', 8, ...
                                                          'PowerLawRefHeight', refHeigth, ...
                                                          'windDirection', pi/2, ...
                                                          'TI0', .01);

            % Make a controlObject for this layout
            testCase.controlSet = control_set(clwindcon9Turb, 'axialInduction');
        end
    end
    methods(Test)
        function set_invalid_yaw_angle(testCase)
            %testGeneric6Turb Test some attributes of a 6 turb layout
            %   Test if there is only one unique turbine type and test that
            %   there are 6 turbines in the layout
            
            % Check that yaw and tilt angles throw errors when setting
            function set_yaw_angle_wrong(); testCase.controlSet.yawAngles(6) = 10; end
            testCase.assertError(@set_yaw_angle_wrong, 'check_angles_in_rad:valueError')
            function set_yaw_angle_correct(); testCase.controlSet.yawAngles(6) = deg2rad(10); end
            testCase.assertWarningFree(@set_yaw_angle_correct)
        end
        function set_value_invalid_turbine(testCase)
            %testGeneric6Turb Test some attributes of a 6 turb layout
            %   Test if there is only one unique turbine type and test that
            %   there are 6 turbines in the layout

            % Check that yaw and tilt angles throw errors when setting
            function set_yaw_angle_turb_10(); testCase.controlSet.yawAngles(10) = deg2rad(5); end
            testCase.assertError(@set_yaw_angle_turb_10, 'check_doubles_array:valueError')
        end
        function test_control_struct(testCase)
            %testGeneric6Turb Test some attributes of a 6 turb layout
            %   Test if there is only one unique turbine type and test that
            %   there are 6 turbines in the layout

            % The turbineControls struct should automatically mirror the
            % values set in the arrays holding control settings
            i = 5;
            testCase.controlSet.yawAngles(i) = deg2rad(5);
            testCase.assertEqual(testCase.controlSet.turbineControls(i).yawAngle, deg2rad(5))
            
            testCase.controlSet.tiltAngles(i) = deg2rad(15);
            testCase.assertEqual(testCase.controlSet.turbineControls(i).tiltAngle, deg2rad(15))
            
            testCase.controlSet.pitchAngles(i) = .1;
            testCase.assertEqual(testCase.controlSet.turbineControls(i).pitchAngle, .1)
            
            testCase.controlSet.axialInductions(i) = .3;
            testCase.assertEqual(testCase.controlSet.turbineControls(i).axialInduction, .3)
        end
    end
end

