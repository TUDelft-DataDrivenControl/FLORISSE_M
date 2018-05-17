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
            controlSet = control_set(clwindcon9Turb, 'axialInduction');
            % Check that yaw and tilt angles throw errors when setting
            % invalid values (deg2rad)
        end
    end
end

