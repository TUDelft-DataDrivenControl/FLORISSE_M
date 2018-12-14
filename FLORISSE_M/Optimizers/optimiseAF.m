 function [xOpt,fOpt] = optimiseAF(AF,xMin,xMax,seeds)
% This function computes the maximum of a given acquisition function. This
% is done using MATLAB's fmincon function, which is a nonlinear programming
% solver that can determine the minimum of a function. 
%   Inputs: 
%   - AF: the acquisition function of which the optimum needs to be
%       determined. 
%   - xMin: left side boundary of the input values.
%   - xMax: right side boundary of the input values. 
%   - seeds: number of seeds that are used to determine the optimum. Multiple
%       seeds are used in order to find the global optimum. 
%   Outputs: 
%   - xOpt: input value for the optimum of the AF.
%   - fOpt: optimum of the given AF.

% Turn of display of fmincon solver in command window. 
options = optimset('Display', 'off');

nm = length(xMin);

% Start the optimisation for the given number of seeds
for i = 1:seeds
%     blockLength = (xMax-xMin)/seeds;    % divide the function input interval into blocks
%     x0 = xMin + (i-1/2)*blockLength;    % starting input value for each block 
    x0 = xMin + rand(nm,1).*(xMax - xMin);
    % Determine minimum of -AF(x) (= maximum of AF(x))
    [xOptNew,fOptNew] = fmincon(@(x)(-AF(x)),x0,[],[],[],[],xMin,xMax,[],options); 
    % If new minimum is lower than previous one, overwrite it.
    if i == 1 || fOptNew < fOpt
       fOpt = fOptNew;
       xOpt = xOptNew; 
    end
end  

end