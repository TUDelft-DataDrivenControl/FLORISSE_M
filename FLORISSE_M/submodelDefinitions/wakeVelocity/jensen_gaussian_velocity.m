classdef jensen_gaussian_velocity < velocity_interface
    %JENSEN_GAUSSIAN_VELOCITY Wake velocity object implementing a version
    %of the jensen wake model as described in :cite:`Jensen1983`. That
    %paper describes as a possible variant a cosine bell fitted tp the
    %tophat velocity profile. The approach taken here is to fit a 2D
    %gaussian to the wake tophat.
    
    properties
        wakeRadiusInit % Initial wake radius
        a % Axial induction factor
        Ke % Base expansion coefficient
        gv % Gaussian variable, ratio between wake radius and standard deviation
        sd % Number of std. devs to which the gaussian wake extends
        P_normcdf_lb % normcdf(-sd,0,1)
        P_normcdf_ub % normcdf(sd,0,1)
    end
    
    methods
        function obj = jensen_gaussian_velocity(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %JENSEN_GAUSSIAN_VELOCITY Construct an instance of this class
            
            % Initial wake radius [m]
            obj.wakeRadiusInit = turbine.turbineType.rotorRadius;
            % Store the axial induction
            obj.a = turbineResult.axialInduction;
            % Calculate ke, the basic expansion coefficient
            obj.Ke = modelData.Ke + modelData.KeCorrCT*(turbineResult.ct-modelData.baselineCT);
            
            obj.gv = .65; % Gaussian variable
            obj.sd = 2;   % Number of std. devs to which the gaussian wake extends
            obj.P_normcdf_lb = 0.022750131948179; % This is the evaluation of normcdf(-sd,0,1) for sd = 2
            obj.P_normcdf_ub = 0.977249868051821; % This is the evaluation of normcdf(+sd,0,1) for sd = 2
        end
        
        function Vdeficit = deficit(obj, x, y, z)
            %DEFICIT Compute the velocity deficit at a certain position
            
            % Wake radius as a function of x [m]
            rJens = obj.Ke*x+obj.wakeRadiusInit;
            % Wake intensity reduction factor according to Jensen
            cJens = (obj.wakeRadiusInit./rJens).^2;
            varWake = rJens.*obj.gv;
            % to avoid dependencies on the Statistics Toolbox
            floris_normpdf = (1/(varWake*sqrt(2*pi)))*exp(-(hypot(y,z)).^2/(2*varWake.^2));
            
            % cFull is the wake intensity reduction factor
            % cFull = (pi*rJens(x).^2).*(normpdf(r,0,varWake(x))./((normcdf(sd,0,1)-normcdf(-sd,0,1))*varWake(x)*sqrt(2*pi))).*cJens(x);
            % The above function is the true equation. The lower one is evaluated for std = 2,  to avoid dependencies on the Statistics Toolbox.
            cFull = (pi*rJens.^2).*(floris_normpdf./((obj.P_normcdf_ub-obj.P_normcdf_lb)*varWake*sqrt(2*pi))).*cJens;

            % wake.V is an analytical function for flow speed [m/s] in a single wake
            Vdeficit = 2*obj.a*cFull;
        end
        function booleanMap = boundary(obj, x, y, z)
            %BOUNDARY Determine if a coordinate is inside the wake

            % Wake radius as a function of x [m]
            rJens = obj.Ke*x+obj.wakeRadiusInit;      
            varWake = rJens.*obj.gv;
            booleanMap = hypot(y,z)<( obj.sd*varWake);
        end
    end
end
