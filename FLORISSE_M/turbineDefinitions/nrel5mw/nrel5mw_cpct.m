classdef nrel5mw_cpct < handle
    
    properties
        controlMethod % The controlMethod that is being used in this turbine
        structLUT % Struct() containing all the preloaded LUT info
    end
    
    methods
        function obj = nrel5mw_cpct(controlMethod)
            %TURBINE_TYPE Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.controlMethod = controlMethod;
            
            % Initialize LUTs
            switch controlMethod
                % use pitch angles and Cp-Ct LUTs for pitch and WS,
                case {'pitch'}
                    % Load the lookup tables for cp and ct as a function of windspeed and pitch
                    structLUT.pitchRange = [0.0:0.5:5.0];
                    structLUT.wsRange    = [3.0:1.0:15.0];
                    structLUT.lutCp      = ...
                        [0.497300000000000 0.482500000000000 0.480200000000000 0.479900000000000 0.479900000000000 0.480000000000000 0.480200000000000 0.480200000000000 0.472300000000000 0.480000000000000 0.475500000000000 0.456000000000000 0.432400000000000;
                        0.493700000000000 0.477500000000000 0.474800000000000 0.474400000000000 0.474500000000000 0.474600000000000 0.474700000000000 0.474800000000000 0.466000000000000 0.473500000000000 0.476000000000000 0.460700000000000 0.438200000000000;
                        0.487600000000000 0.470100000000000 0.467100000000000 0.466700000000000 0.466700000000000 0.466800000000000 0.466900000000000 0.467000000000000 0.458200000000000 0.463600000000000 0.472600000000000 0.461800000000000 0.442000000000000;
                        0.479100000000000 0.460600000000000 0.456700000000000 0.456800000000000 0.456900000000000 0.456900000000000 0.457100000000000 0.457200000000000 0.448800000000000 0.450700000000000 0.465500000000000 0.458700000000000 0.441600000000000;
                        0.468400000000000 0.449300000000000 0.445800000000000 0.445300000000000 0.445300000000000 0.445300000000000 0.445400000000000 0.445500000000000 0.438100000000000 0.435000000000000 0.454500000000000 0.451100000000000 0.436400000000000;
                        0.455600000000000 0.436400000000000 0.432800000000000 0.432100000000000 0.432100000000000 0.432200000000000 0.432300000000000 0.432400000000000 0.426100000000000 0.417300000000000 0.440300000000000 0.439400000000000 0.426600000000000;
                        0.441000000000000 0.422000000000000 0.418400000000000 0.417700000000000 0.417700000000000 0.417700000000000 0.417800000000000 0.417900000000000 0.413200000000000 0.403800000000000 0.423600000000000 0.424300000000000 0.413100000000000;
                        0.424900000000000 0.406300000000000 0.402700000000000 0.402100000000000 0.402000000000000 0.402100000000000 0.402200000000000 0.402200000000000 0.399300000000000 0.390900000000000 0.405400000000000 0.406900000000000 0.396800000000000;
                        0.407600000000000 0.389700000000000 0.386200000000000 0.385500000000000 0.385500000000000 0.385500000000000 0.385600000000000 0.385700000000000 0.384300000000000 0.377400000000000 0.386400000000000 0.388400000000000 0.378800000000000;
                        0.389500000000000 0.372500000000000 0.369100000000000 0.368500000000000 0.368400000000000 0.368500000000000 0.368500000000000 0.368600000000000 0.368300000000000 0.363200000000000 0.367200000000000 0.369400000000000 0.360200000000000;
                        0.370700000000000 0.354800000000000 0.35160000000000 0.351100000000000 0.351000000000000 0.351000000000000 0.351100000000000 0.351200000000000 0.351200000000000 0.348200000000000 0.348400000000000 0.350600000000000 0.341800000000000];
                    
                    structLUT.lutCt = ...
                        [0.820707171778000 0.813335284125000 0.811414581840000 0.811926792945000 0.811680909102000 0.811583821031000 0.811567463531000 0.810653645460000 0.768326153273000 0.808381698236000 0.890632334592000 0.941170227276000 0.973268286871000;
                        0.789707171778000 0.781335284125000 0.780414581840000 0.779926792945000 0.779680909102000 0.779883821031000 0.779967463531000 0.780053645460000 0.741026153273000 0.771881698236000 0.856332334592000 0.907470227276000 0.941868286871000;
                        0.756707171778000 0.749335284125000 0.747414581840000 0.746926792945000 0.747280909102000 0.747283821031000 0.747367463531000 0.747353645460000 0.713526153273000 0.732481698236000 0.816432334592000 0.866670227276000 0.901268286871000;
                        0.723707171778000 0.716335284125000 0.714414581840000 0.713926792945000 0.713880909102000 0.713983821031000 0.714067463531000 0.714153645460000 0.685526153273000 0.691381698236000 0.772232334592000 0.819770227276000 0.851668286871000;
                        0.689707171778000 0.682335284125000 0.680414581840000 0.679926792945000 0.680280909102000 0.680283821031000 0.680267463531000 0.680453645460000 0.657326153273000 0.649381698236000 0.725632334592000 0.768470227276000 0.795668286871000;
                        0.655707171778000 0.648335284125000 0.647414581840000 0.646726792945000 0.646680909102000 0.646583821031000 0.646667463531000 0.646653645460000 0.629026153273000 0.607981698236000 0.678432334592000 0.715370227276000 0.736768286871000;
                        0.621707171778000 0.615335284125000 0.613414581840000 0.613026792945000 0.612880909102000 0.612883821031000 0.612867463531000 0.612953645460000 0.600526153273000 0.579181698236000 0.632532334592000 0.662970227276000 0.678368286871000;
                        0.586707171778000 0.581335284125000 0.579414581840000 0.579526792945000 0.579480909102000 0.579483821031000 0.579467463531000 0.579353645460000 0.572026153273000 0.553481698236000 0.588732334592000 0.613170227276000 0.622768286871000;
                        0.552707171778000 0.548335284125000 0.546414581840000 0.546526792945000 0.546280909102000 0.546383821031000 0.546367463531000 0.546453645460000 0.542726153273000 0.528081698236000 0.548132334592000 0.567070227276000 0.571768286871000;
                        0.519707171778000 0.515335284125000 0.514414581840000 0.514226792945000 0.514180909102000 0.514083821031000 0.514067463531000 0.514053645460000 0.513126153273000 0.502381698236000 0.510832334592000 0.525170227276000 0.525968286871000;
                        0.487707171778000 0.484335284125000 0.483214581840000 0.483126792945000 0.482880909102000 0.482883821031000 0.482967463531000 0.482953645460000 0.482826153273000 0.476181698236000 0.476632334592000 0.487670227276000 0.485368286871000];
                    
                case {'greedy'}
                    % Load the lookup table for cp and ct as a function of windspeed
                    structLUT.wsRange = [2.99,3,3.1308,3.2617,3.3925,3.5234,3.6542,3.7851,3.9159,4.0468,4.1776,4.3085,4.4393,4.5702,4.701,4.8319,4.9627,5.0935,5.2244,5.3552,5.4861,5.6169,5.7478,5.8786,6.0095,6.1403,6.2712,6.402,6.5329,6.6637,6.7946,6.9254,7.0562,7.1871,7.3179,7.4488,7.5796,7.7105,7.8413,7.9722,8.103,8.2339,8.3647,8.4956,8.6264,8.7573,8.8881,9.0189,9.1498,9.2806,9.4115,9.5423,9.6732,9.804,9.9349,10.066,10.197,10.327,10.458,10.589,10.72,10.851,10.982,11.112,11.243,11.374,11.505,11.636,11.637,11.704,11.772,11.841,11.91,11.979,12.048,12.118,12.189,12.26,12.331,12.403,12.475,12.547,12.62,12.693,12.767,12.841,12.916,12.991,13.066,13.142,13.219,13.295,13.373,13.45,13.529,13.607,13.686,13.766,13.846,13.926,14.007,14.088,14.17,14.253,14.335,14.419,14.502,14.587,14.671,14.757,14.842,14.929,15.015,15.103,15.19,15.279,15.367,15.457,15.547,15.637,15.728,15.819,15.911,16.003,16.096,16.19,16.284,16.379,16.474,16.569,16.666,16.763,16.86,16.958,17.056,17.156,17.255,17.355,17.456,17.558,17.66,17.762,17.866,17.969,18.074,18.179,18.284,18.391,18.497,18.605,18.713,18.822,18.931,19.041,19.152,19.263,19.375,19.487,19.601,19.715,19.829,19.944,20.06,20.177,20.294,20.412,20.53,20.65,20.77,20.89,21.012,21.134,21.257,21.38,21.504,21.629,21.755,21.881,22.008,22.136,22.265,22.394,22.524,22.655,22.787,22.919,23.052,23.186,23.321,23.457,23.593,23.73,23.868,24.006,24.146,24.286,24.427,24.569,24.712,24.856,25,25.001];
                    structLUT.lutCp   = [0,0.1926,0.23047,0.26258,0.2898,0.31287,0.33252,0.34938,0.36401,0.37681,0.3876,0.39726,0.40567,0.41307,0.41962,0.42544,0.43054,0.4353,0.43922,0.44291,0.44627,0.44896,0.45148,0.45387,0.45566,0.45716,0.45858,0.45992,0.46098,0.46155,0.46209,0.4626,0.46308,0.46354,0.46371,0.46357,0.46343,0.46331,0.46319,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46316,0.46299,0.46281,0.46199,0.46097,0.45997,0.45899,0.45804,0.46028,0.46016,0.45223,0.44444,0.43678,0.42926,0.42186,0.41459,0.40745,0.40043,0.39353,0.38675,0.38009,0.37354,0.3671,0.36078,0.35456,0.34845,0.34245,0.33655,0.33075,0.32505,0.31945,0.31395,0.30854,0.30322,0.298,0.29286,0.28782,0.28286,0.27799,0.2732,0.26849,0.26386,0.25932,0.25485,0.25046,0.24614,0.2419,0.23773,0.23364,0.22961,0.22566,0.22177,0.21795,0.21419,0.2105,0.20688,0.20331,0.19981,0.19637,0.19298,0.18966,0.18639,0.18318,0.18002,0.17692,0.17387,0.17088,0.16793,0.16504,0.1622,0.1594,0.15665,0.15396,0.1513,0.1487,0.14613,0.14362,0.14114,0.13871,0.13632,0.13397,0.13166,0.1294,0.12717,0.12497,0.12282,0.12071,0.11863,0.11658,0.11457,0.1126,0.11066,0.10875,0.10688,0.10504,0.10323,0.10145,0.099701,0.097984,0.096295,0.094636,0.093006,0.091403,0.089829,0.088281,0.08676,0.085265,0.083796,0.082352,0.080933,0.079539,0.078169,0.076822,0.075498,0.074197,0.072919,0.071663,0.070428,0.069215,0.068022,0.06685,0.065698,0.064566,0.063454,0.062361,0.061286,0.06023,0.059193,0.058173,0.05717,0.056185,0.055217,0.054266,0.053331,0.052412,0.051509,0.050622,0.04975,0.048892,0.04805,0.047222,0.046409,0.046403];
                    structLUT.lutCt   = [0.06672,1.0952,1.0757,1.0571,1.0394,1.0227,1.007,0.99229,0.97841,0.96536,0.95294,0.94125,0.93017,0.91965,0.90968,0.9002,0.89117,0.88267,0.87439,0.86661,0.8592,0.8519,0.84503,0.83854,0.83206,0.82579,0.81987,0.81427,0.80881,0.80328,0.79805,0.79309,0.7884,0.78396,0.77951,0.77503,0.77078,0.76675,0.76294,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.76209,0.75681,0.75083,0.74442,0.73796,0.73165,0.72548,0.71945,0.71282,0.71212,0.67211,0.64401,0.62102,0.60088,0.58256,0.5656,0.55022,0.53548,0.52189,0.50876,0.49653,0.48462,0.47352,0.46238,0.45186,0.44166,0.43179,0.42241,0.4132,0.40443,0.39594,0.3876,0.37971,0.372,0.36443,0.35729,0.35022,0.34299,0.33618,0.32949,0.32291,0.31663,0.3105,0.30447,0.29867,0.29305,0.28752,0.28215,0.277,0.27194,0.26697,0.26216,0.25715,0.25228,0.24757,0.243,0.2385,0.23408,0.22987,0.22573,0.22166,0.21773,0.21392,0.21019,0.20652,0.20304,0.19962,0.19626,0.19264,0.18916,0.18574,0.18237,0.17913,0.17597,0.17286,0.16982,0.16691,0.16404,0.16124,0.15852,0.1559,0.15333,0.15081,0.14842,0.14608,0.14379,0.14119,0.13869,0.13623,0.13381,0.13147,0.12919,0.12695,0.12476,0.12266,0.1206,0.11859,0.11664,0.11476,0.11292,0.11113,0.10942,0.10775,0.10613,0.10457,0.10307,0.1013,0.099476,0.097721,0.096004,0.09432,0.092675,0.09109,0.089538,0.088019,0.086555,0.085135,0.083748,0.082401,0.081112,0.079857,0.078635,0.077468,0.076344,0.075252,0.074201,0.073205,0.072241,0.07131,0.070047,0.068786,0.067549,0.066343,0.065176,0.064033,0.062914,0.06184,0.060793,0.059771,0.058781,0.057835,0.060036,0.060036];
                    
                case {'axialInduction'}
                    % No preparation needed
                    structLUT = struct();
                    
                otherwise
                    error('Control methodology with name: "%s" not defined for the NREL 5MW turbine', controlMethod);
            end
            
            obj.structLUT = structLUT;
        end
        
        function [pitch,TSR,axInd] = initialValues(obj)
            switch obj.controlMethod
                case {'pitch'}
                    pitch = 0;   % Blade pitch angles, by default set to greedy
                    TSR   = nan; % Lambdas  are set to NaN
                    axInd = nan; % Axial inductions  are set to NaN
                case {'greedy'}
                    pitch = nan; % Blade pitch angles are set to NaN
                    TSR   = nan; % Lambdas  are set to NaN
                    axInd = nan; % Axial inductions  are set to NaN
                otherwise
                    error(['Control methodology with name: "' obj.controlMethod '" not defined']);
            end
        end
        
        function [cp,ct,adjustCpCtYaw] = calculateCpCt(obj,condition,turbineControl)
            controlMethod = obj.controlMethod;
            structLUT     = obj.structLUT;
            
            switch controlMethod
                case {'pitch'}
                    cp = interp2(structLUT.wsRange, deg2rad(structLUT.pitchRange),...
                        structLUT.lutCp, condition.avgWS, turbineControl.pitchAngle);
                    ct = interp2(structLUT.wsRange, deg2rad(structLUT.pitchRange),...
                        structLUT.lutCt, condition.avgWS, turbineControl.pitchAngle);
                    adjustCpCtYaw = true; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    
                case {'greedy'}
                    cp = interp1(structLUT.wsRange, structLUT.lutCp, condition.avgWS);
                    ct = interp1(structLUT.wsRange, structLUT.lutCt, condition.avgWS);
                    adjustCpCtYaw = true; % do function call 'adjust_cp_ct_for_yaw' after this func.
                    
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
        end
        
    end
end
