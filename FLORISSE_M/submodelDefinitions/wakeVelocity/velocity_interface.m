classdef velocity_interface
    %VELOCITY_INTERFACE This superclass defines the methods that must be
    %implemented to create a valid wake_velocity_deficit object
    
    methods (Abstract)
        deficit(obj, x, y, z)
        boundary(obj, x, y, z)
    end
    methods
        function [overlap, RVdef] = deficit_integral(obj, deltax, dy, dz, rotRadius)
            %DEFICIT_INTEGRAL computes the wake deficit and overlap are
            %that the wake has with the rotor
            %
            % The below figure shows what the input parameters represent.
            % The deficit function which should also be part of this wake
            % velocity object has a velocity deficit profile which is
            % computed around the wake centerline.
            %
            % .. image:: Images/inputsToDeficitIntegral.png
            %     :width: 100 %
            %     :alt: Diagram of function inputs
            %     :align: center
            
            rotorArea = pi * rotRadius^2;
            
            dY_wc = @(y) y+dy;
            dZ_wc = @(z) z+dz;
            % Create a mask that is 1 where the wake exists and 0 where it
            % does not exists
            mask = @(y,z) obj.boundary(deltax,dY_wc(y),dZ_wc(z));
            % Make a velocity function that combines the free stream and
            % wake velocity by using the mask. The velocity function is
            % normalized with respect the to the free stream.
            VelocityFun = @(y,z) (mask(y,z).*obj.deficit(deltax,dY_wc(y),dZ_wc(z)));
            polarfun = @(theta,r) VelocityFun(r.*cos(theta), r.*sin(theta)).*r;
            
            % Volumetric flowrate deficit
            Q = quad2d(polarfun,0,2*pi,0,rotRadius,'Abstol',15,...
            'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);
            % Relative volumetric flowrate through swept area
            RVdef = 1-Q/rotorArea;
            
            % Estimate the size of the area affected by the wake
            [Y,Z] = meshgrid(linspace(-rotRadius,rotRadius,50),linspace(-rotRadius,rotRadius,50));
            overlap = nnz((hypot(Y,Z)<rotRadius)&...
                (obj.boundary(deltax, Y+dy, Z+dz)))/nnz(hypot(Y,Z)<rotRadius);
            
            % Compute the size of the area affected by the wake
%             polarfunBound = @(theta,r) mask(r.*cos(theta), r.*sin(theta)).*r;
%             wakeArea = quad2d(polarfunBound,0,2*pi,0,rotRadius,'Abstol',15,...
%             'Singular',false,'FailurePlot',true,'MaxFunEvals',3500);
%             overlap = wakeArea/rotorArea;
            
%             [PHI,Rmesh] = meshgrid([0:.1:2*pi 2*pi],0:rotRadius);
%             figure;surf(Rmesh.*cos(PHI), Rmesh.*sin(PHI), polarfun(PHI,Rmesh)./Rmesh,'edgeAlpha',0);
%             title(sprintf('Volumetric flowrate deficit = %.2f m^3/s', Q)); daspect([1 1 .002]);
% 
%             [y,z] = meshgrid(-100:100,-89:100);
%             wakeV = obj.turbineResults(turbNumAffector).wake.deficit(deltax,dY_wc(y),dZ_wc(z));
%             figure;surf(y, z, wakeV,'edgeAlpha',0);
%             keyboard
        end
    end
end
