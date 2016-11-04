function obj = calc_greeks(option,valuation_date,value_type,underlying,vola_riskfactor,discount_curve,tmp_vola_surf_obj,path_static)
    obj = option;
    if ( nargin < 5)
        error('Error: No  discount curve, vola surface or underlying set. Aborting.');
    end
    if ( nargin < 6)
        valuation_date = today;
    end
    if (ischar(valuation_date))
        valuation_date = datenum(valuation_date);
    end
    if ( nargin < 7)
        path_static = pwd;
    end
    % Get discount curve nodes and rate
        tmp_nodes        = discount_curve.get('nodes');
        tmp_rates_base   = discount_curve.getValue('base');
        comp_type_curve = discount_curve.get('compounding_type');
        comp_freq_curve = discount_curve.get('compounding_freq');
        basis_curve     = discount_curve.get('basis');
    tmp_type = obj.sub_type;
    option_type = obj.option_type;
    call_flag = obj.call_flag;
    if ( call_flag == 1 )
        moneyness_exponent = 1;
    else
        moneyness_exponent = -1;
    end
    
    
    % Get input variables
    tmp_dtm                  = (datenum(obj.maturity_date) - valuation_date); 
    tmp_rf_rate              = interpolate_curve(tmp_nodes,tmp_rates_base,tmp_dtm ) + obj.spread;
    tmp_impl_vola_spread     = obj.vola_spread;
    % Get underlying absolute scenario value 
    tmp_underlying_value     = underlying.getValue('base');
   
    if ( tmp_dtm < 0 )
        theo_value  = 0.0;
        theo_delta  = 0.0;
        theo_gamma  = 0.0;
        theo_vega   = 0.0;
        theo_theta  = 0.0;
        theo_rho    = 0.0;
        theo_omega  = 0.0; 
        
    else
        tmp_strike         = obj.strike;
        tmp_value          = obj.value_base;
        tmp_multiplier     = obj.multiplier;
        tmp_moneyness      = ( tmp_underlying_value ./ tmp_strike).^moneyness_exponent;
                
        % get implied volatility spread (choose offset to vola, that tmp_value == option_bs with input of appropriate vol):
        tmp_indexvol_base  = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness);
        tmp_impl_vola_atm  = max(vola_riskfactor.getValue(value_type),-tmp_indexvol_base);
        
      % Get Volatility according to volatility smile given by vola surface
        % Calculate Volatility depending on model
        tmp_model = vola_riskfactor.model;
        if ( strcmpi(tmp_model,'GBM') || strcmpi(tmp_model,'BKM') ) % Log-normal Motion
            if ( strcmpi(value_type,'stress'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + ...
                            tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness)) ...
                            .* exp(vola_riskfactor.getValue(value_type));
            elseif ( strcmpi(value_type,'base'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + tmp_indexvol_base);
            else
                tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness) ...
                                .* exp(tmp_impl_vola_atm) + tmp_impl_vola_spread;
            end
        else        % Normal Model
            if ( strcmpi(value_type,'stress'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + ...
                            tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness)) ...
                            .* (vola_riskfactor.getValue(value_type) + 1);
            elseif ( strcmpi(value_type,'base'))
                tmp_imp_vola_shock  = (tmp_impl_vola_spread + tmp_indexvol_base);
            else
                tmp_imp_vola_shock  = tmp_vola_surf_obj.getValue(tmp_dtm,tmp_moneyness) ...
                                    + tmp_impl_vola_atm + tmp_impl_vola_spread;  
            end
        end
       % Convert timefactor from Instrument basis to pricing basis (act/365)
        tmp_dtm_pricing  = timefactor (valuation_date, ...
                                valuation_date + tmp_dtm, obj.basis) .* 365;
       
       % Convert divyield and interest rates into act/365 continuous (used by pricing)        
        tmp_rf_rate_conv = convert_curve_rates(valuation_date,tmp_dtm,tmp_rf_rate, ...
                        comp_type_curve,comp_freq_curve,basis_curve, ...
                        'cont','annual',3);
        divyield = obj.get('div_yield');
        
      % Valuation for: Black-Scholes Modell (EU) or Willowtreemodel (AM):
        if ( strcmpi(option_type,'European')  )     % calling Black-Scholes option pricing model
            [theo_value theo_delta theo_gamma theo_vega theo_theta theo_rho ...
                                    theo_omega] = option_bs(call_flag, ...
                                    tmp_underlying_value, tmp_strike, tmp_dtm_pricing, ...
                                    tmp_rf_rate_conv, tmp_imp_vola_shock, divyield);            
        elseif ( strcmpi(option_type,'American') )   
            % because of performance reasons calculate greeks with Berksund-Stensland model
            % calculating effective greeks -> imply from derivatives
            theo_value_base	= option_bjsten(call_flag, tmp_underlying_value, ...
                                tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock, divyield);
            undvalue_down	= option_bjsten(call_flag, tmp_underlying_value - 1, ...
                                tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock, divyield);
            undvalue_up	    = option_bjsten(call_flag, tmp_underlying_value + 1, ...
                                tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock, divyield);
            rfrate_down     = option_bjsten(call_flag, tmp_underlying_value, ...
                                tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv - 0.01, ...
                                tmp_imp_vola_shock, divyield);
            rfrate_up	    = option_bjsten(call_flag, tmp_underlying_value, ...
                                tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv + 0.01, ...
                                tmp_imp_vola_shock, divyield);                       
            vola_down	    = option_bjsten(call_flag, tmp_underlying_value, ...
                                tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock - 0.01, divyield);                           
            vola_up	        = option_bjsten(call_flag, tmp_underlying_value, ...
                                tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock + 0.01, divyield);
            time_down	    = option_bjsten(call_flag, tmp_underlying_value, ...
                                tmp_strike, tmp_dtm_pricing - 1, tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock, divyield);
            time_up	        = option_bjsten(call_flag, tmp_underlying_value, ...
                                tmp_strike, tmp_dtm_pricing + 1, tmp_rf_rate_conv, ...
                                tmp_imp_vola_shock, divyield);
            theo_delta  = (undvalue_up - undvalue_down) / 2;
            theo_gamma  = (undvalue_up + undvalue_down - 2 * theo_value_base);
            theo_vega   = (vola_up - vola_down) / 2;
            theo_theta  = -(time_up - time_down) / 2;
            theo_rho    = -(rfrate_up - rfrate_down) / 2;
            theo_omega  = theo_delta .* tmp_underlying_value ./ theo_value_base;
        elseif ( strcmpi(option_type,'Barrier') ) 
            % calculating effective greeks -> imply from derivatives
            theo_value_base	= option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing, tmp_rf_rate_conv, tmp_imp_vola_shock, divyield, obj.rebate);
            undvalue_down	= option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value - 1, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing, tmp_rf_rate_conv, tmp_imp_vola_shock, divyield, obj.rebate);
            undvalue_up	    = option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value + 1, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing, tmp_rf_rate_conv, tmp_imp_vola_shock, divyield, obj.rebate);
            rfrate_down     = option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing, tmp_rf_rate_conv - 0.01, tmp_imp_vola_shock, divyield, obj.rebate);                                
            rfrate_up	    = option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing, tmp_rf_rate_conv + 0.01, tmp_imp_vola_shock, divyield, obj.rebate);                                
            vola_down	    = option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing, tmp_rf_rate_conv, tmp_imp_vola_shock - 0.01, divyield, obj.rebate);                                
            vola_up	        = option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing, tmp_rf_rate_conv, tmp_imp_vola_shock + 0.01, divyield, obj.rebate);                                    
            time_down	    = option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing - 1, tmp_rf_rate_conv, tmp_imp_vola_shock, divyield, obj.rebate);
            time_up	        = option_barrier(call_flag,obj.upordown,obj.outorin, tmp_underlying_value, tmp_strike, ...
                                obj.barrierlevel, tmp_dtm_pricing + 1, tmp_rf_rate_conv, tmp_imp_vola_shock, divyield, obj.rebate);                 
            theo_delta  = (undvalue_up - undvalue_down) / 2;
            theo_gamma  = (undvalue_up + undvalue_down - 2 * theo_value_base);
            theo_vega   = (vola_up - vola_down) / 2;
            theo_theta  = -(time_up - time_down) / 2;
            theo_rho    = -(rfrate_up - rfrate_down) / 2;
            theo_omega  = theo_delta .* tmp_underlying_value ./ theo_value_base;
        elseif ( strcmpi(option_type,'Asian') ) 
            % calculating effective greeks -> imply from derivatives
            avg_rule = option.averaging_rule;
            avg_monitoring = option.averaging_monitoring;
            % distinguish Asian options:
            if ( strcmpi(avg_rule,'geometric') && strcmpi(avg_monitoring,'continuous') )
              theo_value_base = option_asian_vorst90(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);
              undvalue_down	= option_asian_vorst90(call_flag, tmp_underlying_value - 1, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);
              undvalue_up	= option_asian_vorst90(call_flag, tmp_underlying_value + 1, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);
              rfrate_down   = option_asian_vorst90(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv - 0.01, ...
                                    tmp_imp_vola_shock, divyield);
              rfrate_up	    = option_asian_vorst90(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv + 0.01, ...
                                    tmp_imp_vola_shock, divyield);                                
              vola_down	    = option_asian_vorst90(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock - 0.01, divyield);                                
              vola_up	    = option_asian_vorst90(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock + 0.01, divyield);                                    
              time_down	    = option_asian_vorst90(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing - 1, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);
              time_up	    = option_asian_vorst90(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing + 1, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);                
              theo_delta  = (undvalue_up - undvalue_down) / 2;
              theo_gamma  = (undvalue_up + undvalue_down - 2 * theo_value_base);
              theo_vega   = (vola_up - vola_down) / 2;
              theo_theta  = -(time_up - time_down) / 2;
              theo_rho    = -(rfrate_up - rfrate_down) / 2;
              theo_omega  = theo_delta .* tmp_underlying_value ./ theo_value_base;
            elseif ( strcmpi(avg_rule,'arithmetic') && strcmpi(avg_monitoring,'continuous') )
              % Call Levy pricing model
              theo_value_base = option_asian_levy(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);
              undvalue_down	= option_asian_levy(call_flag, tmp_underlying_value - 1, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);
              undvalue_up	= option_asian_levy(call_flag, tmp_underlying_value + 1, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);
              rfrate_down   = option_asian_levy(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv - 0.01, ...
                                    tmp_imp_vola_shock, divyield);
              rfrate_up	    = option_asian_levy(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv + 0.01, ...
                                    tmp_imp_vola_shock, divyield);                                
              vola_down	    = option_asian_levy(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock - 0.01, divyield);                                
              vola_up	    = option_asian_levy(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock + 0.01, divyield);                                    
              time_down	    = option_asian_levy(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing - 1, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);
              time_up	    = option_asian_levy(call_flag, tmp_underlying_value, ...
                                    tmp_strike, tmp_dtm_pricing + 1, tmp_rf_rate_conv, ...
                                    tmp_imp_vola_shock, divyield);                
              theo_delta  = (undvalue_up - undvalue_down) / 2;
              theo_gamma  = (undvalue_up + undvalue_down - 2 * theo_value_base);
              theo_vega   = (vola_up - vola_down) / 2;
              theo_theta  = -(time_up - time_down) / 2;
              theo_rho    = -(rfrate_up - rfrate_down) / 2;
              theo_omega  = theo_delta .* tmp_underlying_value ./ theo_value_base;
            else
                error('Unknown Asian averaging rule >>%s<< or monitoring >>%s<<',avg_rule,avg_monitoring);
            end
        end
    end   % close loop if tmp_dtm < 0
    
      
    % store theo_value vector in appropriate class property   
    if ( strcmpi(value_type,'stress'))
        %obj = obj.set('value_stress',theo_value);  
    elseif ( strcmpi(value_type,'base'))
        obj = obj.set('theo_delta',theo_delta .* tmp_multiplier);
        obj = obj.set('theo_gamma',theo_gamma .* tmp_multiplier);
        obj = obj.set('theo_vega',theo_vega .* tmp_multiplier);
        obj = obj.set('theo_theta',theo_theta .* tmp_multiplier);
        obj = obj.set('theo_rho',theo_rho .* tmp_multiplier);
        obj = obj.set('theo_omega',theo_omega .* tmp_multiplier);       
    end
   
end


