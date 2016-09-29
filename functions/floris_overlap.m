function [ Aol ] = floris_overlap( R_a, R_b, d )
%floris_overlap 
%   Calculates the overlap area between two circles on the same line,
%   displaced with distance d and with radii R and r

    d = abs(d);
    if d >= R_a+R_b  % if not contained at all
        Aol = 0;   
    elseif d <= abs(R_a-R_b) % if one is contained completely in the other circle
        Aol = pi*min(abs([R_b, R_a]))^2;
    else
        dy = (1/d)*sqrt((-d+R_a+R_b)*(d-R_a+R_b)*(d+R_a-R_b)*(d+R_a+R_b));
        s_a = 0.5*dy+R_a; s_b = 0.5*dy+R_b;
        Aol = R_a^2*asin(dy/(2*R_a)) - sqrt(s_a*(s_a-dy)*(s_a-R_a)^2) + ...
               R_b^2*asin(dy/(2*R_b)) - sqrt(s_b*(s_b-dy)*(s_b-R_b)^2);
    end;
end

