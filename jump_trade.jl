
"""Detect jumps based on price change magnitude and volume confirmation"""
function detect_jumps_magnitude(prices, volumes=nothing; threshold_pct=2.0, volume_threshold=1.5, window_size=20)
    returns = @views diff(prices) ./ prices[1:end-1] * 100  # Percentage returns
    
    # Base threshold detection
    jump_candidates = findall(x -> abs(x) > threshold_pct, returns) .+ 1
    
    # Volume confirmation if available
    if volumes !== nothing && length(volumes) == length(prices)
        vol_ma = @views [mean(volumes[max(1,i-window_size):i]) for i in (window_size+1):length(volumes)]
        volume_spikes = @views findall(x -> x > volume_threshold, volumes[(window_size+1):end] ./ vol_ma) .+ window_size
        
        # Jumps confirmed by volume
        jump_indices = intersect(jump_candidates, volume_spikes)
        return jump_indices, returns, volume_spikes
    else
        return jump_candidates, returns, Int[]
    end
end

"""Filter jump indices by direction (positive/negative/both)"""
function filter_jumps_by_direction(jump_indices, prices, params::TradingParams)::Vector{Int}
    if params.jump_side == :both || isempty(jump_indices)
        return jump_indices
    end
    
    filtered_indices = Int[]
    for jidx in jump_indices
        lookback_idx = jidx - params.window_size
        if lookback_idx >= 1
            price_change_pct = ((prices[jidx] - prices[lookback_idx]) / prices[lookback_idx]) * 100
            
            if (params.jump_side == :positive && price_change_pct > 0) || 
               (params.jump_side == :negative && price_change_pct < 0)
                push!(filtered_indices, jidx)
            end
        end
    end
    
    return filtered_indices
end

"""Compute trades from jump indices"""
function compute_trades(market_data::MarketData, jump_indices, params::TradingParams)::Vector{Trade}
    if isempty(jump_indices)
        return Trade[]
    end
    
    trades = Trade[]
    sell_delta = Minute(Int(round(params.sell_after_hours * 60)))
    
    for jidx in jump_indices
        buy_time = market_data.times[jidx]
        buy_price = market_data.prices[jidx]
        
        # Find sell index
        target_time = buy_time + sell_delta
        sidx = findfirst(t -> t >= target_time, market_data.times)
        if sidx === nothing
            sidx = lastindex(market_data.times)
        end
        
        sell_time = market_data.times[sidx]
        sell_price = market_data.prices[sidx]
        return_pct = ((sell_price - buy_price) / buy_price) * 100
        
        push!(trades, Trade(buy_time, buy_price, sell_time, sell_price, return_pct))
    end
    
    return trades
end

"""Convert trades to DataFrame"""
function trades_to_dataframe(trades::Vector{Trade}, date::Date)::DataFrame
    if isempty(trades)
        return DataFrame()
    end
    
    return DataFrame(
        date = fill(date, length(trades)),
        buy_time = [t.buy_time for t in trades],
        buy_price = [t.buy_price for t in trades],
        sell_time = [t.sell_time for t in trades],
        sell_price = [t.sell_price for t in trades],
        return_pct = [t.return_pct for t in trades]
    )
end
