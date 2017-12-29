function Qdef = bvcdf_wake(deltax, y, z, bladeR, varWake, FW_scalar)
%bvcdf_wake uses the bvcdf function to compute the velocity deficit at the
%swept area of a turbine

SIGMA = varWake(deltax);

[v, e] = eig(SIGMA);
mux = sqrt(e(1));

r = sqrt(e(4))/mux;
lab = bladeR/mux;
u = norm([y z]*v)/mux;
Qdef = FW_scalar(deltax)*(bvcdf(r, lab, u, 4)*2*pi*sqrt(det(SIGMA)));
