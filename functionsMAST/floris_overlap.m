function [ Aol ] = floris_overlap( R, r, d )
%floris_overlap 
%   Calculates the overlap area between two circles on the same line,
%   displaced with distance d and with radii R and r
    d = abs(d);
    if d >= R+r  % if not contained at all
        Aol = 0;   
    elseif d <= abs(R-r) % if one is contained completely in the other circle
        Aol = pi*min(abs([r, R]))^2;
    else
        Aol = r^2*acos((d^2+r^2-R^2)/(2*d*r)) + R^2*acos((d^2+R^2-r^2)/(2*d*R)) - ...
              0.5*sqrt((-d+r+R)*(d+r-R)*(d-r+R)*(d+r+R));
    end;
end

