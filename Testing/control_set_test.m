classdef control_set_test < matlab.unittest.TestCase
    %INSPECTLAYOUTSTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Test)
        function testControlSet(testCase)
            %testGeneric6Turb Test some attributes of a 6 turb layout
            %   Test if there is only one unique turbine type and test that
            %   there are 6 turbines in the layout
            import matlab.unittest.fixtures.PathFixture
            
            testCase.applyFixture(PathFixture('../FLORISSE_M/layoutDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
            % Instantiate a layout object with 6 identical turbines
            strongWind6Turb = strong_wind_6_turb;
            controlSet = control_prototype(strongWind6Turb, 'pitch');
%             controlSet
            % Check if the uniqueTurbineTypes function works as expected
%             testCase.assertLength(generic6Turb.uniqueTurbineTypes, 1);
            % Check if there are 6 turbines as expected
%             testCase.assertLength(generic6Turb.turbines, 6);
        end
    end
end

