%% Run all the unittests and save the results
import matlab.unittest.TestSuite;

suite = TestSuite.fromFolder(pwd);
results = run(suite);
