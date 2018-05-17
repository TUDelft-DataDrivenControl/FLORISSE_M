classdef turbine_type < handle
    %TURBINE_TYPE This class instantiates turbine_type objects.
    %   This class inherits from handle. This means that if multiple
    %   turbines in a layout use the same turbine type they all refer to
    %   the same actual object. Changing the Cp/Ct functions or
    %   controlmethods for the turbine_type will thus immediately make this
    %   same change to turbines that have the same type. A turbine_type
    %   should thus hold a description of a turbine. The parameters that
    %   vary per simulation such as power are stored elsewhere (TODO: explain where)
    
    properties
        controlMethod
        rotorRadius
        rotorArea
        genEfficiency
        hubHeight
        pP
    end
    properties (Access = private)
        allowableControlMethods
        dataPath
        lutCp
        lutCt
        lutGreedy
    end
    
    methods
        function obj = turbine_type(rotorRadius, genEfficiency, hubHeight, pP, path, allowableControlMethods)
            %turbine_prototype Construct an instance of this class
            %   The turbine characters are saved as properties
            obj.controlMethod = nan;
            obj.dataPath = path;
            obj.allowableControlMethods = allowableControlMethods;
            
            obj.rotorRadius = rotorRadius;
            obj.rotorArea = pi*rotorRadius.^2;
            obj.genEfficiency = genEfficiency;
            obj.hubHeight = hubHeight;
            obj.pP = pP;
        end
        
        function set.controlMethod(obj, controlMethod)
            %set.controlMethod Prepare cp and ct functions
            % Herein we define how the turbine are controlled. In the traditional
            % FLORIS model, we directly control the axial induction factor of each
            % turbine. However, to apply this in practise, we still need a mapping to
            % the turbine generator torque and the blade pitch angles. Therefore, we
            % have implemented the option to directly control and optimize the blade
            % pitch angles 'pitch', under the assumption of optimal generator torque
            % control. Additionally, we can also assume fully greedy control, where we
            % cannot adjust the generator torque nor the blade pitch angles ('greedy').
            
            % Choice of how a turbine's axial control setting is determined
            % pitch:          use pitch angles and Cp-Ct LUTs for pitch and WS,
            % greedy:         greedy control   and Cp-Ct LUT for WS,
            % axialInduction: specify axial induction directly.
            
            % If the controlMethod is set to nan do not prepare any lookup tables
            if isnan(controlMethod)
                return
            end
            % If the desired controlMethod is not available for this
            % turbine, throw an error.
            if ~any(strcmp(obj.allowableControlMethods, controlMethod))
                error('The turbine_type defined in \n%s,\ndoes not support the control method: "%s".',...
                      obj.dataPath, controlMethod)
            end
            
            obj.controlMethod = controlMethod;
            
            switch controlMethod
                % use pitch angles and Cp-Ct LUTs for pitch and WS,
                case {'pitch'}
                % Load the lookup tables for cp and ct as a function of
                % windspeed and pitch
                    obj.lutCp = csvReadCCompatible([obj.dataPath '/cpPitch.csv']);
                    obj.lutCt = csvReadCCompatible([obj.dataPath '/ctPitch.csv']);
                % The lookup tables are formatted in this way:
                % Wind speed in LUT in m/s
                % lut_ws    = lut(1,2:end);
                % Blade pitch angle in LUT in radians
                % lut_pitch = deg2rad(lut(2:end,1));
                % Values of Cp/Ct [dimensionless]
                % lut_value = lut(2:end,2:end);
                case {'greedy'}
                % Load the lookup table for cp and ct as a function of windspeed
                    obj.lutGreedy = csvReadCCompatible([obj.dataPath '/cpctgreedy.csv']);
                case {'axialInduction'}
                % No preparation needed
                otherwise
                    error('Control methodology with name: "%s" not defined', controlMethod);
            end
        end
        
        function turbineResult = cPcTpower(obj, condition, turbineControl, turbineResult)
            %cPcTpower returns a struct with the computed turbine characteristics 
            %   Computes the power coefficient for this turbine depending
            %   on the condition at the rotor area and the controlset of
            %   the turbine
%             keyboard
            switch obj.controlMethod
                case {'pitch'}
                    turbineResult.cp = interp2(obj.lutCp(1,2:end), deg2rad(obj.lutCp(2:end,1)), obj.lutCp(2:end,2:end), ...
                                               condition.avgWS, turbineControl.pitchAngle);
                    turbineResult.ct = interp2(obj.lutCt(1,2:end), deg2rad(obj.lutCt(2:end,1)), obj.lutCt(2:end,2:end), ...
                                               condition.avgWS, turbineControl.pitchAngle);
                    turbineResult.axialInduction = obj.calc_axial_induction(turbineResult.ct);
                case {'greedy'}
                    turbineResult.cp = interp1(obj.lutGreedy(1,:), obj.lutGreedy(2,:), condition.avgWS);
                    turbineResult.ct = interp1(obj.lutGreedy(1,:), obj.lutGreedy(3,:), condition.avgWS);
                    turbineResult.axialInduction = obj.calc_axial_induction(turbineResult.ct);
                case {'axialInduction'}
                    turbineResult.axialInduction = turbineControl.axialInduction;
                    turbineResult.cp = 4*turbineControl.axialInduction*(1-turbineControl.axialInduction);
                    turbineResult.ct = 4*turbineControl.axialInduction*(1-turbineControl.axialInduction)^2;
                otherwise
                    error('Control methodology with name: "%s" not defined', obj.controlMethod);
            end
            
            % Correct Cp and Ct for rotor misallignment
            turbineResult.ct = turbineResult.ct * cos(turbineControl.thrustAngle)^2;
            turbineResult.cp = turbineResult.cp * cos(turbineControl.thrustAngle)^obj.pP;
            
            turbineResult.power = (0.5*condition.rho*obj.rotorArea*turbineResult.cp)*(condition.avgWS^3.0)*obj.genEfficiency;
        end
    end
    methods (Static)
        function axialInd = calc_axial_induction(ct)
            % Calculate axial induction factor
            if ct > 0.96 % Glauert condition
                axialInd = 0.143+sqrt(0.0203-0.6427*(0.889-ct));
            else
                axialInd = 0.5*(1-sqrt(1-ct));
            end
        end
    end
end

function lut = csvReadCCompatible(path)
    fid = fopen(path);
    a = fread(fid, '*char');
    fclose(fid);

    iis = 0;
    lls = 1;
    line1 = 1;
    nl = 0;
    for pos = 1:length(a)
        if (a(pos) == ',') && line1
            lls=lls+1;
        end
        if (a(pos) == char(13))||(a(pos) == char(10))
            if nl == 0
                line1 = 0;
                nl = 1;
                iis = iis + 1;
            end
        else
            nl = 0;
        end
    end
    lut = zeros(iis,lls);

    ii=1;
    ll=1;
    num = '                                       ';
    aai =1;
    nl = 0;
    for pos = 1:length(a)
        if (a(pos) == ',')
            lut(ii,ll) = real(str2double(num));
            ll=ll+1;
            num = '                                       ';
            aai =1;
            nl = 0;
        elseif ~(a(pos) == char(13))||(a(pos) == char(10))
            num(aai) = a(pos);
            aai = aai +1;
            nl = 0;
        elseif (a(pos) == char(13))||(a(pos) == char(10))
            if nl == 0
                nl = 1;
                lut(ii,ll) = real(str2double(num));
                ii = ii + 1;
                ll=1;
                num = '                                       ';
                aai =1;
            end
        end
    end
end

function Zi = codegen_interp2(X,Y,Z,xi,yi)
%#codegen
% zi = codegen_interp2(X,Y,Z,xi,yi) gives the same result as
% interp2(X,Y,Z,xi,yi)
% Unlike interp2, codegen_interp2 is compatible with code generation
% Only linear interpolation is available

% Usage restrictions
%   X and Y must have the same size as Z
%   e.g.,  [X,Y] = meshgrid(x,y);
% keyboard
X = X*1.0001;
Y = Y*1.0001;
Z = Z*1.0001;
xi = xi*1.0001;
yi = yi*1.0001;
ndx = 1/(X(1,2)-X(1,1));        ndy = 1/(Y(2,1)-Y(1,1));

idyi=(xi - X(1,1))*ndx+1;       idxi=(yi - Y(1,1))*ndy+1;

if idxi/ceil(idxi)~=1&&idyi/ceil(idyi)~=1
    if any(any(isnan(Z)))
        error('nancrash')
    end
    Z1=Z(ceil(idxi)-1,ceil(idyi)-1);
    Z2=Z(ceil(idxi)-1,ceil(idyi));
    Z3=Z(ceil(idxi),ceil(idyi)-1);
    Z4=Z(ceil(idxi),ceil(idyi));
    
    Zi= Z1*(ceil(idxi)-idxi)*(ceil(idyi)-idyi)+...
        Z2*(ceil(idxi)-idxi)*(1-(ceil(idyi)-idyi))+...
        Z3*(1-(ceil(idxi)-idxi))*(ceil(idyi)-idyi)+...
        Z4*(1-(ceil(idxi)-idxi))*(1-(ceil(idyi)-idyi));
    
elseif idxi/ceil(idxi)~=1&&idyi/ceil(idyi)==1
    Z1=Z(ceil(idxi)-1,idyi);
    Z2=Z(ceil(idxi),idyi);
    
    Zi=Z1*(ceil(idxi)-idxi)+Z2*(1-(ceil(idxi)-idxi));
    
elseif idxi/ceil(idxi)==1&&idyi/ceil(idyi)~=1    
    Z1=Z(idxi,ceil(idyi)-1);
    Z2=Z(idxi,ceil(idyi));
    
    Zi=Z1*(ceil(idyi)-idyi)+Z2*(1-(ceil(idyi)-idyi));
else
    Zi=Z(idxi,idyi);    
end
    
end