function [wtLocationsWf] = frame_IF2WF(windDirection_IF,Turb_LocIF)
%frame_IF2WF Rotate and translate to from inertial to wind-aligned frame
%   If you only specify two inputs, out_newFrame will be the turbine loc-
%   ations in the wind-aligned frame. If you specify the third and fourth 
%   input argument, then out_newFrame will be the coordinates of 
%   xyz_oldFrame, mapped from the old frame (specified by oldFrame, where
%   oldFrame == 'if' means a mapping from IF -> WF. Similarly, oldFrame ==
%   'wf' means a mapping from WF -> IF.

    % Rotational matrix
    Rz = @(a) [cos(a) -sin(a) 0;sin(a) cos(a) 0;0 0 1]; 
    
    % Wind frame turbine locations in wind frame
    wtLocationsWf = Turb_LocIF*Rz(windDirection_IF);
end

