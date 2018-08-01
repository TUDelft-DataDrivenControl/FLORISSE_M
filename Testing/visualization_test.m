classdef visualization_test < matlab.unittest.TestCase
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
            testCase.applyFixture(PathFixture('../FLORISSE_M/ambientFlowDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/controlDefinitions'));
            testCase.applyFixture(PathFixture('../FLORISSE_M/turbineDefinitions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/submodelDefinitions',...
                                              'IncludeSubfolders',true));
            testCase.applyFixture(PathFixture('../FLORISSE_M/visualizationTools',...
                                              'IncludeSubfolders',true));                                          
                                          
            % Instantiate a layout object with 6 identical turbines
            layout = tester_6_turb_5D;

            % Use the height from the first turbine type as reference height for theinflow profile
            refheight = layout.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                                  'PowerLawRefHeight', refheight, ...
                                                  'windDirection', 0.3, ...
                                                  'TI0', .01);

            % Make a controlObject for this layout
            controlSet = control_set(layout, 'pitch');
            
            % Define subModels
            subModels = model_definition('deflectionModel', 'jimenez',...
                                         'velocityDeficitModel', 'selfSimilar',...
                                         'wakeCombinationModel', 'quadraticRotorVelocity',...
                                         'addedTurbulenceModel', 'crespoHernandez');
            testCase.florisRunner = floris(layout, controlSet, subModels);
            testCase.florisRunner.run;
        end
    end
    methods(Test)        
        function validate_computeProbes3D(testCase)
            visTool = visualizer(testCase.florisRunner);
            visTool.plot3dIF(false);
            
            Nprecision = 1999;
            xIF = visTool.flowFieldIF.X(10:Nprecision:end);
            yIF = visTool.flowFieldIF.Y(10:Nprecision:end);
            z = visTool.flowFieldIF.Z(10:Nprecision:end);
            
            u3D    = visTool.flowFieldIF.U(10:Nprecision:end);
            uProbe = compute_probes(testCase.florisRunner,xIF,yIF,z,true);
            
            % Remove isNaN entries
            uProbe = uProbe(~isnan(u3D));
            u3D    = u3D(~isnan(u3D));
            
            % Validate
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            testCase.assertThat(u3D, IsEqualTo(uProbe, ...
                'Within', AbsoluteTolerance(1.0))); % Large tolerance due to interp effects
        end
    end
end

