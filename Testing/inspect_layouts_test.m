classdef inspect_layouts_test < matlab.unittest.TestCase
    %inspect_layouts_test Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(TestMethodSetup)
        function setFolders(testCase)
            % Add the relevant folders to the current path
            import matlab.unittest.fixtures.PathFixture
            
            testCase.applyFixture(PathFixture('../FLORISSE_M/layoutDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
        end
    end
    methods(Test)
        function test_generic_6_turb(testCase)
            %testGeneric6Turb Test some attributes of a 6 turb layout
            %   Test if there is only one unique turbine type and test that
            %   there are 6 turbines in the layout
            
            % Instantiate a layout object with 6 identical turbines
            generic6Turb = generic_6_turb;
            % Check if the uniqueTurbineTypes function works as expected
            testCase.assertLength(generic6Turb.uniqueTurbineTypes, 1);
            % Check if there are 6 turbines as expected
            testCase.assertEqual(generic6Turb.nTurbs, 6);
        end
        function test_clwindcon_9_turb(testCase)
            % Check the clwindcon_9 layout
            clwindcon9Turb = clwindcon_9_turb;
            testCase.assertLength(clwindcon9Turb.uniqueTurbineTypes, 1);
            testCase.assertEqual(clwindcon9Turb.nTurbs, 9);
        end
        function test_dtu_nrel_6_turb(testCase)
            % Check the dtu_nrel_6_turb layout
            dtuNrel6Turb = dtu_nrel_6_turb;
            testCase.assertLength(dtuNrel6Turb.uniqueTurbineTypes, 2);
            testCase.assertEqual(dtuNrel6Turb.nTurbs, 6);
        end
        function test_scaled_2_turb(testCase)
            % Check the scaled_2_turb layout
            scaled2Turb = scaled_2_turb;
            testCase.assertLength(scaled2Turb.uniqueTurbineTypes, 1);
            testCase.assertEqual(scaled2Turb.nTurbs, 2);
        end
        function test_two_heigths_6_turb(testCase)
            % Check the two_heigths_6_turb layout
            twoHeigths6Turb = two_heigths_6_turb;
            testCase.assertLength(twoHeigths6Turb.uniqueTurbineTypes, 2);
            testCase.assertEqual(twoHeigths6Turb.nTurbs, 6);
        end
    end
end
