function s = calc_yield_to_mat (bond, valuation_date)
  s = bond;
  
  % set start parameter and bounds
  x0 = 0.01;
  lb = -1;
  ub = 1;
  
  if ( nargin < 2)
        valuation_date = datestr(today);
  elseif ( nargin == 2)
        valuation_date = datestr(valuation_date);
  end
  
  if ( ischar(valuation_date))
    valuation_date = datenum(valuation_date);
  end

  % Check, whether cash flow have already been roll out 
  cf_values = s.cf_values;  
  if ( length(s.cf_values) < 1)
        disp('Warning: No cash flows defined for bond. setting YtM = 0.0')
        s.ytm = 0.0;
  else
	if ( rows(cf_values) > 1 )
		cf_values = cf_values(1,:);
		fprintf('WARNING: More than one cash flow value scenario provided.')
		fprintf('Taking only first scenario as base values.\n')
	end
		% generic call
		objfunc = @ (x) phi_ytm(x, valuation_date, s.cf_dates, cf_values, s.value_base);
		s.ytm = calibrate_generic(objfunc,x0,lb,ub);
  end
   
end

%-------------------------------------------------------------------------------
%--------------------------- Begin Subfunction ---------------------------------

% Definition Objective Function for yield to maturity:	       
function obj = phi_ytm (x,valuation_date,cashflow_dates, ...
						cashflow_values,act_value)
			tmp_yield = [x];
            % get discount factors for all cash flow dates and ytm rate
            tmp_df 	= discount_factor (valuation_date, valuation_date + cashflow_dates', ...
                                                   tmp_yield,'disc',3,'annual'); 
            % Calculate actual NPV of cash flows    
            tmp_npv = cashflow_values * tmp_df;
        
			obj = (act_value - tmp_npv).^2;
end
%-------------------------------------------------------------------------------
