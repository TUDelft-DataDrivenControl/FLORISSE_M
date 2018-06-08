classdef ambient_inflow_test < matlab.unittest.TestCase
    %AMBIENT_INFLOW_TEST Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(TestMethodSetup)
        function setFolders(testCase)
            % Add the relevant folders to the current path
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture('../FLORISSE_M/ambientFlowDefinitions'));
        end
    end
    methods(Test)
        function test_ambient_inflow_uniform(testCase)
            %TEST_AMBIENT_INFLOW_UNIFORM Test some properties on the
            %uniform inflow object
            
            vRef = 4;
            ambientInflow = ambient_inflow_uniform('windSpeed', vRef, ...
                                                   'windDirection', 0, ...
                                                   'TI0', .01);
            testCase.assertEqual(ambientInflow.Vfun(0), vRef);
            testCase.assertEqual(ambientInflow.Vfun(10), vRef);
            testCase.assertEqual(ambientInflow.Vfun(100), vRef);
        end
        function test_ambient_inflow_log(testCase)
            %TEST_AMBIENT_INFLOW_UNIFORM Test some properties on the
            %uniform inflow object
            
            vRef = 8;
            ambientInflow = ambient_inflow_log('windSpeed', vRef, ...
                                               'PowerLawRefHeight', 80, ...
                                               'windDirection', 0, ...
                                               'TI0', .01);
            
            testCase.assertEqual(ambientInflow.Vfun(0), 0);
            testCase.assertEqual(ambientInflow.Vfun(10), vRef*(10/80).^0.14);
            testCase.assertEqual(ambientInflow.Vfun(80), vRef);
            testCase.assertEqual(ambientInflow.Vfun(100), vRef*(100/80).^0.14);
        end
    end
end
