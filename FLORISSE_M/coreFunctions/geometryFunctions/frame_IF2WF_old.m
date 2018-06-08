function [out_newFrame] = frame_IF2WF_old(windDirection_IF,Turb_LocIF,oldFrame,xyz_oldFrame)
%frame_IF2WF Rotate and translate to from inertial to wind-aligned frame
%   If you only specify two inputs, out_newFrame will be the turbine loc-
%   ations in the wind-aligned frame. If you specify the third and fourth 
%   input argument, then out_newFrame will be the coordinates of 
%   xyz_oldFrame, mapped from the old frame (specified by oldFrame, where
%   oldFrame == 'if' means a mapping from IF -> WF. Similarly, oldFrame ==
%   'wf' means a mapping from WF -> IF.


    if nargin == 3
        error(['The variable ''oldFrame'' only applies when xyz_oldFrame is '
               'also specified. Please specify both or neither.']);
    end
    
    % Rotational matrix
    Rz = @(a) [cos(a) -sin(a) 0;sin(a) cos(a) 0;0 0 1]; 
    
    % Wind frame turbine locations in wind frame
    wtLocationsWf = Turb_LocIF*Rz(-windDirection_IF).';

    % Determine shift values in x- and y-direction
    dX = min(wtLocationsWf(:,1));
    dY = min(wtLocationsWf(:,2));
    
    if nargin == 2 % Rotate and translate turbine locations
        wtLocationsWf(:,1) = wtLocationsWf(:,1)-dX; % shift horizontally (sideways)
        wtLocationsWf(:,2) = wtLocationsWf(:,2)-dY; % shift vertically (up-down)
        out_newFrame = wtLocationsWf;
        
    elseif nargin == 4 % Rotate and translate xyz_oldFrame
        if strcmp(lower(oldFrame),'if') % Mapping from IF to WF
            xyz_WF = xyz_oldFrame*Rz(-windDirection_IF).';
            xyz_WF = [xyz_WF(:,1)-dX, xyz_WF(:,2)-dY, xyz_WF(:,3)];
            out_newFrame = xyz_WF;

        elseif strcmp(lower(oldFrame),'wf') % Mapping from WF to IF
            xyz_WF = [xyz_oldFrame(:,1)+dX, xyz_oldFrame(:,2)+dY, xyz_oldFrame(:,3)];
            xyz_IF = xyz_WF*Rz(windDirection_IF).';
            out_newFrame = xyz_IF;
        else
            error('The variable ''oldFrame'' must be one of two strings: ''if'' or ''wf''.');
        end
        
    else
        error('The function frame_IF2WF requires two or three inputs.');
    end
end

