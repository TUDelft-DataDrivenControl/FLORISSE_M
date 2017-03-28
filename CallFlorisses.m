clear all; clc;

FFres = 5;

LocIF =[300,    100.0,  90.0; ...
                   300,    300.0,  90.0; ...
                   300,    500.0,  90.0; ...
                   1000,   100.0,  90.0; ...
                   1000,   300.0,  90.0; ...
                   1000,   500.0,  90.0; ...
                   1600,   100.0,  90.0; ...
                   1600,   300.0,  90.0; ...
                   1600,   500.0,  90.0];
% LocIF =[300,    100.0,  90.0]; 
yawAngles_wf = [-27. 10. -30. 10. 10. -15. 0.0 0.0 0.0];
siteU = 4;
siteV = 12;
p = [1 1];

[ flowField, windspeeds ] = florisMASTAsFunc( FFres, LocIF, yawAngles_wf, siteU, siteV, p );
[ flowFieldnew, windspeedsnew ] = florisTILTAsFunc( FFres, LocIF, yawAngles_wf, siteU, siteV, p );
windspeeds
windspeedsnew

if p(2)
    figure
    contourf((flowField-flowFieldnew).','Linecolor','none');
    xlabel('x-direction (m)'); ylabel('y-direction (m)');
    colormap(parula(30)); colorbar;
end