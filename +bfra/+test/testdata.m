function varargout = testdata(varargin)

   whichdata = validatestring(varargin{1},{'example', 'tests'});
   
   
   switch whichdata
      case 'example'
         
         [T, Q, R] = load_example_data;
         
      case 'tests'
         
   end
   data = {T,Q,R};
   [varargout{1:nargout}] = data{:};

end

function varargout = load_example_data

   datapath = bfra.util.basepath('data');
   
   if bfra.util.isoctave
      load(fullfile(datapath,'dailyflow_octave.mat'),'T','Q','R'); 
      T = datenum(T); %#ok<*DATNM> 
   
   else
      load(fullfile(datapath,'dailyflow.mat'),'T','Q','R');
      T = datenum(T); %#ok<*DATNM> 
   end
   
   [varargout{1:nargout}] = deal(T,Q,R);

end