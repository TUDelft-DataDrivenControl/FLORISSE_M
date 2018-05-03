%% Run all the unittests and save the results
import matlab.unittest.TestSuite;

suite = TestSuite.fromFolder(pwd);
results = run(suite);

%% Old testing code, reintegrate after/during refactoring
% addpath('testingData')
% verify_powers(0)
% test_dependencies([pwd '\..\FLORIS\coreFunctions'])
