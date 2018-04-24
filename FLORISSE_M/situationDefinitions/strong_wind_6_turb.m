classdef strong_wind_6_turb < generic_6_turb & situation_prototype
    %strong_wind_6_turb Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        windDirection
        uInfWf
        TI_0
        airDensity
    end
    methods
        function obj = strong_wind_6_turb()
            %strong_wind_6_turb Construct an instance of this class
            %   Detailed explanation goes here

            % Atmospheric settings
            % Compute windDirection in the inertial frame, and the wind-aligned flow speed (uInfWf)
            obj.windDirection = 0.30; % Wind dir in radians (inertial frame)
            obj.uInfWf        = 12.0; % axial flow speed in wind frame
            obj.TI_0          = .1; % turbulence intensity [-] ex: 0.1 is 10% turbulence intensity
            obj.airDensity    = 1.1716; % Atmospheric air density (kg/m3)
        end
        
        function V = Ufun(obj,Height)
            %METHOD1 Inflow (vertical profile)
            %   Inflow (vertical profile) accoridng to some rule
            V = obj.uInfWf;
        end
    end
end

