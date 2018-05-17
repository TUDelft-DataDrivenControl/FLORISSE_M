classdef inspect_layouts_test < matlab.unittest.TestCase
    %INSPECTLAYOUTSTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Test)
        function testGeneric6Turb(testCase)
            %testGeneric6Turb Test some attributes of a 6 turb layout
            %   Test if there is only one unique turbine type and test that
            %   there are 6 turbines in the layout
            import matlab.unittest.fixtures.PathFixture
            
            testCase.applyFixture(PathFixture('../FLORISSE_M/layoutDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
            % Instantiate a layout object with 6 identical turbines
            generic6Turb = generic_6_turb;
            % Check if the uniqueTurbineTypes function works as expected
            testCase.assertLength(generic6Turb.uniqueTurbineTypes, 1);
            % Check if there are 6 turbines as expected
            testCase.assertEqual(generic6Turb.nTurbs, 6);
        end
    end
end
