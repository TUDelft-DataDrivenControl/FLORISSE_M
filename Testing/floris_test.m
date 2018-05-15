classdef floris_test
    %FLORIS_TEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = floris_test(inputArg1,inputArg2)
            %FLORIS_TEST Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
            
            % Check if this actually works for each layout
            
            % Exclude unlikely/impossible
            % trace rotor outlines of possible turbines
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

