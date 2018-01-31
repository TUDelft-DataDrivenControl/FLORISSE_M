function Qdef = bvcdf_wake(deltax, y, z, bladeR, varWake, FW_scalar)
%bvcdf_wake uses the bvcdf function to compute the velocity deficit at the
%swept area of a turbine

SIGMA = varWake(deltax); % covariance matrix of wake deficit in y-z axes

[v, e] = eig(SIGMA);  % Linear transformation to make sigma_y and sigma_z uncorrelated
sigma_y = sqrt(e(1)); % This is the standard deviation in y'-dir
sigma_z = sqrt(e(4)); % This is the standard deviation in z'-dir

Sigma_zn = sigma_z/sigma_y; % Non-dimensionalized sigma_z
bladeRn  = bladeR/sigma_y;  % Non-dimensionalized circle radius
dC       = norm([y z]*v)/sigma_y; % Non-dim. distance between circle and biv. dist. mean

Qdef = FW_scalar(deltax)*(bvcdf(Sigma_zn, bladeRn, dC, 4)*2*pi*sqrt(det(SIGMA)));
