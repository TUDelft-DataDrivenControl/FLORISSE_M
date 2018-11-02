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
            testCase.applyFixture(PathFixture('../FLORISSE_M/ambientFlowDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/controlDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/submodelDefinitions',...
                                              'IncludeSubfolders',true));
            % Instantiate a layout object with 6 identical turbines
            layout = tester_5_turb_05D;

            % Use the height from the first turbine type as reference height for theinflow profile
            refheight = layout.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                                  'PowerLawRefHeight', refheight, ...
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
%         % The next function has been ommitted from testing due to recent 
%         modifications that have increased robustness of the solver, by 
%         defining a 'nearest' extrapolation method.
%
%         function set_wind_direction_for_invalid_windspeed(testCase)
%             %testGeneric6Turb Test some attributes of a 6 turb layout
%             %   Test if there is only one unique turbine type and test that
%             %   there are 6 turbines in the layout
%             
%             % Check that yaw and tilt angles throw errors when setting
%             function runner(); testCase.florisRunner.run; end
%             testCase.assertError(@runner, 'cPcTpower:valueError')
%         end
        
        function test_all_turbines(testCase)
            import matlab.unittest.constraints.IssuesNoWarnings
            function runner();
                turbTypes{1} = nrel5mw();
                turbTypes{2} = dtu10mw();
                turbTypes{3} = mwt12();
                turbTypes{4} = tum_g1();
                
                locIf = {[300,    100.0]; [1000,   100.0]};
                
                % Define subModels
                subModels = model_definition('deflectionModel','rans',...
                    'velocityDeficitModel', 'selfSimilar',...
                    'wakeCombinationModel', 'quadraticRotorVelocity',...
                    'addedTurbulenceModel', 'crespoHernandez');
                
                for i = 1:length(turbTypes)
                    %     disp(['Running with turbTypes{' num2str(i) '}']);
                    clear turbines layout
                    
                    turbines = struct('turbineType', turbTypes{i}, 'locIf',   locIf);
                    layout = layout_class(turbines, ['testTurbineTypes_' num2str(i)]);
                    
                    % Define an inflow struct and use it in the layout, wind_tunnel_3_turb
                    layout.ambientInflow = ambient_inflow_uniform('windSpeed', 5, ...
                        'windDirection', pi/2, 'TI0', .01);
                    
                    for ji = 1:length(turbTypes{i}.allowableControlMethods);
                        clear controlSet florisRunner
                        controlSet = control_set(layout, turbTypes{i}.allowableControlMethods{ji});
                        
                        % Initialize the FLORIS object and run the simulation
                        florisRunner = floris(layout, controlSet, subModels);
                        florisRunner.run;
                    end
                end
                
            end
            testCase.verifyThat(@runner, IssuesNoWarnings)
        end
      
    end
end

