classdef jensen_gaussian_velocity < velocity_interface
    %jensen_gaussian_VELOCITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        wakeRadiusInit
        a
        Ke
        gv
        sd
        P_normcdf_lb
        P_normcdf_ub
    end
    
    methods
        function obj = jensen_gaussian_velocity(modelData, turbine, turbineCondition, turbineControl, turbineResult)
            %jensen_gaussian_VELOCITY Construct an instance of this class
            %   Detailed explanation goes here
            
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
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            % Wake radius as a function of x [m]
            rJens = obj.Ke*x+obj.wakeRadiusInit;
            % Wake intensity reduction factor according to Jensen
            cJens = (obj.wakeRadiusInit./rJens).^2;
            varWake = rJens.*obj.gv;
            % cFull is the wake intensity reduction factor
            % cFull = @(x,r) (pi*rJens(x).^2).*(normpdf(r,0,varWake(x))./((normcdf(sd,0,1)-normcdf(-sd,0,1))*varWake(x)*sqrt(2*pi))).*cJens(x);
            % The above function is the true equation. The lower one is evaluated for std = 2,  to avoid dependencies on the Statistics Toolbox.
            floris_normpdf = (1/(varWake*sqrt(2*pi)))*exp(-(hypot(y,z)).^2/(2*varWake.^2)); % to avoid dependencies on the Statistics Toolbox
            cFull = (pi*rJens.^2).*(floris_normpdf./((obj.P_normcdf_ub-obj.P_normcdf_lb)*varWake*sqrt(2*pi))).*cJens;

            % wake.V is an analytical function for flow speed [m/s] in a single wake
            Vdeficit = 2*obj.a*cFull;
        end
        function booleanMap = boundary(obj, x, y, z)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            % Wake radius as a function of x [m]
            rJens = obj.Ke*x+obj.wakeRadiusInit;      
            varWake = rJens.*obj.gv;
            booleanMap = hypot(y,z)<( obj.sd*varWake);
        end
    end
end
