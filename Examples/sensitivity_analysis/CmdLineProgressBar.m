classdef CmdLineProgressBar < handle
% class for command-line progress-bar notification.
% Use example:
%   pb = CmdLineProgressBar('Doing stuff...');
%   for k = 1 : 10
%       pb.print(k,10)
%       % do stuff
%   end
%
% Author: Itamar Katz, itakatz@gmail.com

    properties
        last_msg_len = 0;
    end
    methods
        %--- ctor
        function obj = CmdLineProgressBar(msg)
            fprintf('%s', msg)
        end
        %--- print method
        function print(obj, n, tot)
            fprintf('%s', char(8*ones(1, obj.last_msg_len))) % delete last info_str
            info_str = sprintf('%d/%d', n, tot);
            fprintf('%s', info_str);
            %--- assume user counts monotonically
            if n == tot
                fprintf('\n')
            end
            obj.last_msg_len = length(info_str);
        end
        %--- dtor
        function delete(obj)
            fprintf('\n')
        end
    end
end