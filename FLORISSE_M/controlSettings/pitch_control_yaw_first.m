classdef pitch_control_yaw_first < control_prototype
    %pitch_control_yaw_first Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = pitch_control_yaw_first(layout)
            %pitch_control_yaw_first Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@control_prototype(layout, 'pitch');
            obj.yawAngles(1) = 10;
        end
    end
end

