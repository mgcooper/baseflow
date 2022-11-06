function [T,Q,R,Info] = eventfinder(t,q,r,varargin)
%EVENTFINDER finds recession events on input hydrographs with time 't',
%discharge 'q', and rain 'r'. Use optional inputs to set parameters that
%determine how events are identified. 
% 
% Required inputs:
%  t           =  time
%  q           =  flow (m3/time)
%  r           =  rain (mm/time)
% 
% Optional name-value inputs:
%  nmin        =  minimum event length
%  fmax        =  maximum # of missing values gap-filled
%  rmax        =  maximum run of sequential constant values
%  rmin        =  minimum rainfall required to censor flow (mm/day?)
%  rmconvex    =  remove convex derivatives
%  rmnochange  =  remove consecutive constant derivates
%  rmrain      =  remove rainfall
% 
%  See also: getevents, findevents, eventsplitter, eventpicker, eventplotter

%-------------------------------------------------------------------------------
p = MipInputParser();
p.FunctionName = 'eventfinder';
p.addRequired( 't',                  @(x) isnumeric(x) | isdatetime(x)  );
p.addRequired( 'q',                  @(x) isnumeric(x) & numel(x)==numel(t) );
p.addRequired( 'r',                  @(x) isnumeric(x)                  );
p.addParameter('nmin',        4,     @(x) isnumeric(x) & isscalar(x)    );
p.addParameter('fmax',        2,     @(x) isnumeric(x) & isscalar(x)    );
p.addParameter('rmax',        2,     @(x) isnumeric(x) & isscalar(x)    );
p.addParameter('rmin',        0,     @(x) isnumeric(x) & isscalar(x)    );
p.addParameter('rmconvex',    false, @(x) islogical(x) & isscalar(x)    );
p.addParameter('rmnochange',  false, @(x) islogical(x) & isscalar(x)    );
p.addParameter('rmrain',      false, @(x) islogical(x) & isscalar(x)    );
p.parseMagically('caller');
%-------------------------------------------------------------------------------
   

   iS  = [1;find(diff(isnan(q))==-1)+1];       % start non-nan segments
   iE  = [find(diff(isnan(q))==1);length(q)];  % end non-nan segments
   L   = iE-iS+1;                              % segment lengths

   % initialize the combined events
   T   = []; Q = []; R = []; Info = struct; iflag = false;
   
   for n = 1:length(iS)

      if L(n)<nmin                       % set nan if <nmin
         [Tn,Qn,Rn,Infon]  = seteventnan;
      else
                   tn      = t(iS(n):iE(n));
                   qn      = q(iS(n):iE(n));
                   rn      = r(iS(n):iE(n));

        [Tn,Qn,Rn,Infon]   = bfra.eventsplitter(tn,qn,rn,               ...
                                 'nmin',        nmin,                   ...
                                 'fmax',        fmax,                   ...
                                 'rmax',        rmax,                   ...
                                 'rmin',        rmin,                   ...
                                 'rmconvex',    rmconvex,               ...
                                 'rmnochange',  rmnochange,             ...
                                 'rmrain',      rmrain                  );
      end

      % if no events were detected, Infon.istart will be empty
      if all(isempty(Infon.istart)); continue; else
         
         % iS is the start of the entire flow segment, but the indices in
         % Info are relative to the event returned by segmentevents. here
         % we add iS to these indices, except runlengths
         fields   = fieldnames(Infon);
         
         if numel(Infon.ikeep) > 0
            
            for m = 1:numel(fields)
               Infon.(fields{m}) = Infon.(fields{m}) + iS(n) - 1;
            end
            
            % add the first non-nan index and runlengths to Info
%             Infon.ifirst      = opts.ifirst;
%             Infon.runlengths  = Infon.istop - Infon.istart + 1;
         end

         % this is needed b/c 'info' has no fieldnames until first detected event
         if iflag == false           % no events detected yet
             T = Tn; Q = Qn; R = Rn; Info = Infon; iflag = true;
             continue
         else                        % at least one detected event
             T    = [T;Tn];
             Q    = [Q;Qn];
             R    = [R;Rn];
             Info = catStructFields(1,Info,Infon);
         end
      end

    end

    % if no events were returned, set events nan
    if isempty(fieldnames(Info))
        [T,Q,R,Info] = seteventnan;
    else

        % cycle through and remove empty events
        inan = false(size(T));
        for n = 1:numel(T)
            if isempty(T{n})
                inan(n) = true; 
            end
        end

        T   = T(~inan);
        Q   = Q(~inan);
        R   = R(~inan);

        Info.istart     = Info.istart(~inan);
        Info.istop      = Info.istop(~inan);
%         Info.runlengths = Info.runlengths(~inan);

    end

end
