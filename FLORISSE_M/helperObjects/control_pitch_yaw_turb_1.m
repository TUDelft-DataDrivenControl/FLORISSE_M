function [pitchControlSet] = control_pitch_yaw_turb_1(layout)
%control_pitch_yaw_turb_1 Summary of this function goes here
%   Detailed explanation goes here
pitchControlSet = control_set(layout, 'pitch');
pitchControlSet.yawAngles(1) = deg2rad(10);
end

