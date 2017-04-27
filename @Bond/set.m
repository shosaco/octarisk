% setting attribute values
function obj = set(obj, varargin)
  % A) Specify fieldnames <-> types key/value pairs
  typestruct = struct(...
                'accrued_interest', 'numeric' , ...
                'last_coupon_date', 'numeric' , ...
                'ir_shock', 'numeric' , ...
                'soy', 'numeric' , ...
                'convexity', 'numeric' , ...
                'dollar_convexity', 'numeric' , ...
                'cf_values_mc', 'special' , ...
                'cf_values_stress', 'numeric' , ...
                'cf_values', 'numeric' , ...
                'cf_dates', 'numeric' , ...
                'value_mc', 'special' , ...
                'value_stress', 'special' , ...
                'value_base', 'numeric' , ...
                'timestep_mc', 'special' , ...
                'timestep_mc_cf', 'special' , ...
                'name', 'char' , ...
                'id', 'char' , ...
                'prepayment_source', 'char' , ...
                'prepayment_type', 'char' , ...
                'issue_date', 'date' , ...
                'maturity_date', 'date' , ...
                'spread_curve', 'char' , ...
                'reference_curve', 'char' , ...
                'discount_curve', 'char' , ...
                'vola_surface', 'char', ...
                'prepayment_curve', 'char' , ...
                'coupon_generation_method', 'char' , ...
                'term', 'numeric' , ...
                'outstanding_balance', 'numeric' , ...
                'prepayment_rate', 'numeric' , ...
                'ytm', 'numeric' , ...
                'compounding_freq', 'charvnumber' , ...
                'day_count_convention', 'char' , ...
                'compounding_type', 'char' , ...
                'sub_type', 'char' , ...
                'valuation_date', 'date' , ...
                'asset_class', 'char' , ...
                'currency', 'char' , ...
                'description', 'char' , ...
                'notional', 'numeric' , ...
                'coupon_rate', 'numeric' , ...
                'business_day_rule', 'numeric' , ...
                'business_day_direction', 'numeric' , ...
                'enable_business_day_rule', 'boolean' , ...
                'prepayment_flag', 'boolean' , ...
                'clean_value_base', 'boolean' , ...
                'spread', 'numeric' , ...
                'principal_payment', 'numeric' , ...
                'psa_factor_term', 'numeric' , ...
                'use_outstanding_balance', 'boolean' , ...
                'long_first_period', 'boolean' , ...
                'use_principal_pmt', 'boolean' , ...
                'long_last_period', 'boolean' , ...
                'last_reset_rate', 'numeric' , ...
                'mod_duration', 'numeric' , ...
                'mac_duration', 'numeric' , ...
                'eff_duration', 'numeric' , ...
                'eff_convexity', 'numeric' , ...
                'dv01', 'numeric' , ...
                'pv01', 'numeric' , ...
                'dollar_duration', 'numeric' , ...
                'spread_duration', 'numeric' , ...
                'in_arrears', 'boolean' , ...
                'fixed_annuity', 'boolean' , ...
                'notional_at_start', 'boolean' , ...
                'notional_at_end', 'boolean', ...
                'type', 'char', ...
                'basis', 'numeric', ...
                'spot_value', 'numeric', ...
                'calibration_flag', 'boolean', ...
                'quantile_base', 'numeric', ...
                'stochastic_riskfactor', 'char' , ...
                'stochastic_surface', 'char', ...
                'stochastic_rf_type', 'char', ...                 
                't_degree_freedom', 'numeric', ...
                'vola_spread', 'numeric', ...
                'convex_adj', 'boolean', ...
                'prorated', 'boolean', ...
                'cms_model', 'char', ...
                'cms_sliding_term', 'numeric', ...
                'cms_term', 'numeric', ...
                'cms_spread', 'numeric', ...
                'cms_comp_type', 'char', ...
                'cms_convex_model', 'char', ...
				'fwd_sliding_term', 'numeric', ...
				'fwd_term', 'numeric', ...
                'rate_composition', 'char', ...
                'prepayment_procedure', 'char', ...
                'alpha', 'numeric' , ...
                'sigma', 'numeric' , ...
                'annuity_amount', 'numeric' , ...
                'use_annuity_amount', 'numeric' , ...
                'treenodes', 'numeric', ...
                'call_schedule', 'char', ...
                'put_schedule', 'char', ...
                'embedded_option_flag', 'boolean', ...
				'cpi_index', 'char', ...
				'infl_exp_curve', 'char', ...
				'cpi_historical_curve', 'char', ...
				'infl_exp_lag', 'numeric', ...	
				'use_indexation_lag', 'boolean', ...
				'strike_rate', 'numeric' , ...
				'underlying_maturity_date', 'date' , ...
				'coupon_prepay', 'char', ...
				'fva_type', 'char', ...
				'key_term', 'numeric', ...
				'key_rate_shock', 'numeric', ...
				'key_rate_width', 'numeric', ...
				'key_rate_eff_dur', 'numeric', ...
				'key_rate_mon_dur', 'numeric', ...
				'key_rate_eff_convex', 'numeric', ...
				'key_rate_mon_convex', 'numeric', ...
                'embedded_option_value', 'numeric'...
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
