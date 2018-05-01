classdef compileCTest < matlab.unittest.TestCase
    %COMPILECTEST This class tests the compilation of the code to C
    %   This class uses function from the matlab coder, in this case
    %   codegen is used to compile a function to C that instantiates
    %   classes of FLORIS, and extracts some data from them.

    methods(Test)
        function testCodeGen(testCase)
            %TESTCODEGEN This function tests the generation of C code
            %   This functions uses codegen to compile the function
            %   instantiateClasses which is located in  ../FLORISSE_M that
            %   path is added using the matlab testing PathFixture, the
            %   fixture adds the path for the test and than restores the
            %   path to its original state
            import matlab.unittest.fixtures.PathFixture
            
            addFolder = '../FLORISSE_M';
            testCase.applyFixture(PathFixture(addFolder,'IncludeSubfolders',true));
            codegen instantiateClasses
        end
    end
end