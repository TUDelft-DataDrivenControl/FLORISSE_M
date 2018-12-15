classdef handles_and_objectcopy_test < matlab.unittest.TestCase
    %floris_test Summary of this class goes here
    %   Detailed explanation goes here
    properties
        layout
        controlSet
        subModels
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
            layout = generic_9_turb;

            % Use the height from the first turbine type as reference height for theinflow profile
            refheight = layout.uniqueTurbineTypes(1).hubHeight;
            % Define an inflow struct and use it in the layout, clwindcon9Turb
            layout.ambientInflow = ambient_inflow_log('PowerLawRefSpeed', 8, ...
                                                  'PowerLawRefHeight', refheight, ...
                                                  'windDirection', 0.3, ...
                                                  'TI0', .01);

            % Make a controlObject for this layout
            controlSet = control_set(layout, 'axialInduction');
            
            % Define subModels
            subModels = model_definition('deflectionModel', 'jimenez',...
                                         'velocityDeficitModel', 'selfSimilar',...
                                         'wakeCombinationModel', 'quadraticRotorVelocity',...
                                         'addedTurbulenceModel', 'crespoHernandez');
                                     
            testCase.layout = layout;
            testCase.controlSet = controlSet;
            testCase.subModels = subModels;
            testCase.florisRunner = floris(layout, controlSet, subModels);
        end
    end
    methods(Test)        
        function checkHandles(testCase)
            layout = testCase.layout;
            controlSet = testCase.controlSet;
            subModels = testCase.subModels;
            florisRunner = testCase.florisRunner;
            
            % Test handles
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            
            % Layout
            randomWD = -0.1091;
            layout.ambientInflow.windDirection = randomWD;
            testCase.assertThat(florisRunner.layout.ambientInflow.windDirection, ...
                IsEqualTo(randomWD, 'Within', AbsoluteTolerance(1e-6)));
            
            % ControlSet
            randomYawAngle = 0.0716;
            controlSet.yawAngleWFArray(1) = randomYawAngle;
            testCase.assertThat(florisRunner.controlSet.yawAngleWFArray(1), ...
                IsEqualTo(randomYawAngle, 'Within', AbsoluteTolerance(1e-6)));            
            
            % SubModels
            randomModelParameter = 0.112;
            subModels.modelData.ad = randomModelParameter;
            testCase.assertThat(florisRunner.model.modelData.ad, ...
                IsEqualTo(randomModelParameter, 'Within', AbsoluteTolerance(1e-6)));      
        end
        
        function checkCopyIndependence(testCase)
            florisRunner = testCase.florisRunner;
            
            % Initial object
            florisRunner.layout.ambientInflow.windDirection = 0.01; 
            florisRunner.controlSet.yawAngleWFArray(1) = -0.10;
            florisRunner.model.modelData.ad = 0.20;
            
            % Create a copy and modify entries
            florisRunnerClone = copy(florisRunner);
            florisRunnerClone.layout.ambientInflow.windDirection = 0.33; 
            florisRunnerClone.controlSet.yawAngleWFArray(1) = 0.05;
            florisRunnerClone.model.modelData.ad = 0.13;
            
            % Check whether values of original object are unchanged
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            testCase.assertThat(florisRunner.layout.ambientInflow.windDirection, ...
                IsEqualTo(0.01, 'Within', AbsoluteTolerance(1e-6)));
            testCase.assertThat(florisRunner.controlSet.yawAngleWFArray(1), ...
                IsEqualTo(-0.10, 'Within', AbsoluteTolerance(1e-6))); 
            testCase.assertThat(florisRunner.model.modelData.ad, ...
                IsEqualTo(0.20, 'Within', AbsoluteTolerance(1e-6)));                 
        end
    end
end

