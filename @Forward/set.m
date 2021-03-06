% setting attribute values
function obj = set(obj, varargin)
  % A) Specify fieldnames <-> types key/value pairs
  typestruct = struct(...
                'type', 'char' , ...
                'basis', 'numeric' , ...
                'value_mc', 'special' , ...
                'timestep_mc', 'special' , ...
                'value_stress', 'special' , ...
                'value_base', 'numeric' , ...
                'exposure_base', 'numeric' , ...
                'exposure_stress', 'special' , ...
                'exposure_mc', 'special' , ...
                'underlying_price_base', 'numeric' , ...
                'name', 'char' , ...
                'id', 'char' , ...
                'sub_type', 'char' , ...
                'asset_class', 'char' , ...
                'currency', 'char' , ...
                'description', 'char' , ...
                'cf_values', 'numeric' , ...
                'cf_dates', 'numeric' , ...
                'spread', 'numeric' , ...
                'compounding_freq', 'charvnumber' , ...
                'day_count_convention', 'char' , ...
                'compounding_type', 'char' , ...
                'discount_curve', 'char' , ...
                'foreign_curve', 'char' , ...
                'maturity_date', 'date' , ...
                'issue_date', 'date' , ...
                'underlying_id', 'char' , ...
                'strike_price', 'numeric' , ...
                'component_weight', 'numeric' , ...
                'net_basis', 'numeric' , ...
                'underlying_sensitivity', 'numeric' , ...
                'multiplier', 'numeric' , ...
                'calc_price_from_netbasis', 'boolean' , ...
                'exposure_type', 'char', ...
                'dividend_yield', 'numeric' , ...
                'convenience_yield', 'numeric' , ...
                'storage_cost', 'numeric' , ...
                'theo_delta', 'numeric' , ...
                'theo_gamma', 'numeric' , ...
                'theo_vega', 'numeric' , ...
                'theo_theta', 'numeric' , ...
                'theo_rho', 'numeric' , ...
                'theo_domestic_rho', 'numeric' , ...
                'theo_price', 'numeric', ...
                'theo_foreign_rho', 'numeric'
               );
  % B) store values in object
  if (length (varargin) < 2 || rem (length (varargin), 2) ~= 0)
    error ('set: expecting property/value pairs');
  end
  
  while (length (varargin) > 1)
    prop = varargin{1};
    prop = lower(prop);
    val = varargin{2};
    varargin(1:2) = [];
    % check, if property is an existing field
    if (sum(strcmpi(prop,fieldnames(typestruct)))==0)
        fprintf('set: not an allowed fieldname >>%s<< with value >>%s<< :\n',prop,any2str(val));
        fieldnames(typestruct)
        error ('set: invalid property of %s class: >>%s<<\n',class(obj),prop);
    end
    % get property type:
    type = typestruct.(prop);
    % input checks and validation
    retval = return_checked_input(obj,val,prop,type);
    % store property in object
    obj.(prop) = retval;
  end
end   
