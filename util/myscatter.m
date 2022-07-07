function [ h ] = myscatter( x,y,varargin )
%MYSCATTER better scatter plot
%   Alias for h = scatter(x,y,'filled');

% realized this doesn't support the case where c is a variable 

% x,y required, then either sz or c, check for either one, then any
% supported Name,Value. the checks exist so that either sz or c can be
% passed in, in any order. 
sz      = 36;
c       = [0,0.447,0.741];
cIsVar  = false;            % assume c is not a variable
numargs = nargin-2;         % two required
if numargs>0
chkarg  = varargin{1};      % check the first argument
    switch size(chkarg,2)   % number of columns 
        case 3              % means 1st arg has three columns
            c=chkarg;       % assume it is a color triplet
            if (numargs-1)==1 % means there is a 2nd arg to check 
                if isscalar(varargin{numargs})
                            % means 2nd arg is a scalar, assume it's sz
                    sz=varargin{numargs};
                elseif all(size(varargin{numargs})==size(x))
                            % means 2nd arg has same size as x,y, assume
                            % its a variable used to shade the scatter
                    c=varargin{numargs};
                    cIsVar=true;
                else        % means 2nd arg is an array that doesn't match
                            % the size of x and y, which isn't supported 
                    error('unsupported input');
                end
            end
        case 1              % means 1st arg has one column
            if isscalar(chkarg)
                            % means 1st arg is a scalar, assume it's sz
                sz=chkarg;
            elseif all(size(chkarg)==size(x))
                            % means 1st arg has same size as x,y, assume
                            % its a variable used to shade the scatter
                    c=chkarg;
                    cIsVar=true;
            end
            if (numargs-1)==1
                            % means there is a 2nd arg to check
                if size(varargin{numargs},2)==3
                            % means 2nd arg is a color triplet
                    c=varargin{numargs};
                elseif all(size(varargin{numargs})==size(x))
                            % means 2nd arg has same size as x,y, assume
                            % its a variable used to shade the scatter
                    c=varargin{numargs};
                    cIsVar=true;
                else        % means 2nd arg is an array that doesn't match
                            % the size of x and y, which isn't supported 
                    error('unsupported input');
                end
            end
            
        otherwise
            warning('unsupported input');
    end
    varargin(1:max(1,numargs))=[];
end

h.scatter = scatter(x,y,sz,c,'filled',varargin{:});

if cIsVar
    h.colorbar = colorbar;
end

end

