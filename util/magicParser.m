classdef MipInputParser < inputParser
    % Make argument parsing fun and magical and reduce typing.
    %
    % 2016 benjamin.heasly@gmail.com
    
    methods (Static)
        function isInList = itemIsInList(item, varargin)
            isInList = false;
            nItems = numel(varargin);
            for ii = 1:nItems
                if isequaln(item, varargin{ii})
                    isInList = true;
                    break;
                end
            end
            
            if ~isInList
                error('MipInputParser:itemIsInList', ...
                    'The value %s should be one of: %s', ...
                    evalc('disp(item)'), ...
                    evalc('disp(varargin)'));
            end
        end
        
        function validatorFunction = isAny(varargin)
            validatorFunction = @(item) MipInputParser.itemIsInList(item, varargin{:});
        end
    end
    
    methods
        function obj = MipInputParser()
            obj.KeepUnmatched = true;
            obj.CaseSensitive = true;
            obj.PartialMatching = false;
            obj.StructExpand = true;
        end
        
        function addProperties(obj, target)
            props = properties(target);
            nProps = numel(props);
            for pp = 1:nProps
                name = props{pp};
                obj.addParameter(name, target.(name));
            end
        end
        
        function addPreference(obj, prefGroup, name, default, validator)
            if ispref(prefGroup, name)
                paramDefault = getpref(prefGroup, name);
            else
                paramDefault = default;
            end
            obj.addParameter(name, paramDefault, validator);
        end
        
        function addAllPreferences(obj, name, prefGroup, prefDefaults)
            if ispref(prefGroup)
                defaults = getpref(prefGroup);
            else
                defaults = prefDefaults;
            end
            obj.addParameter(name, defaults, @(val) isempty(val) || isstruct(val));
        end
        
        function target = parseMagically(obj, target)
            
            %% Steal required args from the caller.
            requiredArgNames = obj.requiredArgNames();
            nRequired = numel(requiredArgNames);
            requiredArgs = cell(1, nRequired);
            for rr = 1:nRequired
                try
                    requiredArgs{rr} = evalin('caller', requiredArgNames{rr});
                catch
                    continue;
                end
            end
            
            %% Steal non-required args from the caller.
            try
                parameterArgs = evalin('caller', 'varargin');
            catch
                parameterArgs = {};
            end
            
            %% Parse arguments as if the caller passed them to us.
            inputArgs = cat(2, requiredArgs, parameterArgs);
            obj.parse(inputArgs{:});
            
            %% Assign results to target workspace, struct or object.
            names = fieldnames(obj.Results);
            for nn = 1:numel(names)
                name = names{nn};
                value = obj.Results.(name);
                if ischar(target)
                    assignin(target, name, value);
                elseif isstruct(target) || isprop(target, name)
                    target.(name) = value;
                end
            end
        end
    end
    
    methods (Access = private)
        function names = requiredArgNames(obj)
            wid = 'MATLAB:structOnObject';
            oldWarningState = warning('query', wid);
            warning('off', wid);
            
            cursed = struct(obj);
            names = {cursed.Required.name};
            
            warning(oldWarningState.state, wid);
        end
    end
end
