%% Wake deflection model choice
% Herein we define the wake deflection model we want to use, which can be
% either from Jimenez et al. (2009) with doi:10.1002/we.380, or from 
% Bastankah and Porte-Agel (2016) with doi:10.1017/jfm.2016.595. The
% traditional FLORIS uses Jimenez, while the new FLORIS model presented
% by Annoni uses Porte-Agel's deflection model.

%% Wake deficit model choice
% Herein we define how we want to model the shape of our wake (looking at
% the y-z slice). The traditional FLORIS model uses three discrete zones,
% 'Zones', but more recently a Gaussian wake profile 'Gauss' has seemed to 
% better capture the wake shape with less tuning parameters. This idea has
% further been explored by Bastankah and Porte-Agel (2016), which led to
% the 'PorteAgel' wake deficit model.