function varargout = specialfunctions(funcname,varargin)
   
%    L2      = L.*L;
%    phiA2   = phi.*A.^2;
%    phiL2   = phi.*L.^2;
%    kL2     = kD.*L.^2;
   
   switch funcname
      
      case 'fR1'
         
         n     = varargin{1};
         fR1   = getfR1(n);
         
         % prep output
         varargout{1}   = fR1;
         
%          % for extended functionality
%          kD    = varargin{2};
%          L     = varargin{3};
%          phi   = varargin{4};
%          b     = 3;
%          N     = -3;
%          c     = fR1./(kD.*phi.*L.^2);

      case 'fR2'
         
         n     = varargin{1};
         fR2   = getfR2(n);
         
         % prep output
         varargout{1}   = fR2;
         
%          % for extended functionality
%          kD    = varargin{2};
%          L     = varargin{3};
%          phi   = varargin{4};
%          A     = varargin{5};
%          
%          b     = (2.*n+3)./(n+2);
%          N     = -n./(n+2);
%          c     = fR2./phi.*( (kD.*L.*L) ./ (2.^n.*(n+1).*A.^(n+3)));         

         
      case 'fLo'
         
         h0overD = 0.0;                  % assume h0=0, fLo=1.1361
         fLo     = getfLo(h0overD,soln);
         
         
         b       = 3;
         N       = -3;
         c       = fLo./(kD.*phiL2);
         
   end
end
   
   
function fR1 = getfR1(n)
    BR1     = beta(n+2,2);
    gamma   = 2.*(n+2).*BR1;
    mu      = (4-3.*gamma-sqrt(gamma.^2-2.*gamma+4))./(4.*(1-2.*gamma));
    fR1     = (1-mu).*(n+1).*(n+2)./(2.*(1-2.*mu));
end

function fR2 = getfR2(n)
    BR2     = beta((n+2)./(n+3),1/2);
    fR2     = (n+2).*(BR2./(n+3)).^(1./(n+2));
end

function fLo = getfLo(h0overD,soln)
    
    % various solutions exist, all depend on ratio of water level in stream
    % (h0) to initial water table level (h_infinity, or as I call it D)
    
    switch soln
        case 2              % Lockington
            
            a   = -0.4604;
            b   = 1.0734;
            c   = -0.9673;
            d   = 1.1361;
            
            fLo = a.*h0overD.^3 + b.*h0overD.^2 + c.*h0overD + d;
    
        case 20             % Hayek
            
            % not sure exactly how to represent Hayek's function, the
            % a/b/c/d values are functions of D, whereas Rupp gave a single
            % set for all D, I think, but that set might be an
            % approximation that works well for all D. See tabl 3 of Hayek
            
        case 21             % Basha
    end
    
end

   