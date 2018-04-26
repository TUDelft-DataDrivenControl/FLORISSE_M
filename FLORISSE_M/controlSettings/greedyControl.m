classdef greedyControl < control_prototype
    %greedyControl Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = greedyControl(layout)
            %greedyControl Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@control_prototype(length(layout.turbines));
            obj.set_default_controls('greedy');
        end
    end
end

