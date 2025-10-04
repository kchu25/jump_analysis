# =============================
# Magnitude-Based Jump Detection and Visualization
# =============================
using CSV
using DataFrames
using CodecZlib
using Dates
using Plots
using Statistics
using Printf

# =============================
# Core Data Structures and Types
# =============================

"""Market data for a single day"""
struct MarketData
    times::Vector{Time}
    prices::Vector{Float64}
    volumes::Vector{Float64}
    ticker::String
    date::Date
end

"""Trading parameters configuration"""
struct TradingParams
    threshold_pct::Float64
    window_size::Int
    time_start::String
    time_end::String
    sell_after_hours::Real
    jump_side::Symbol
    use_volume_confirmation::Bool
    volume_threshold::Float64
    year::Int
    
    function TradingParams(; threshold_pct=1.5, window_size=20, time_start="9:45", 
                          time_end="15:45", sell_after_hours=2.0, jump_side=:both,
                          use_volume_confirmation=false, volume_threshold=1.5, year=2025)
        # Normalize and validate jump_side
        if isa(jump_side, String)
            jump_side = Symbol(lowercase(strip(jump_side)))
        end
        if !(jump_side in (:positive, :negative, :both))
            error("Invalid jump_side. Use :positive, :negative, or :both")
        end
        
        new(threshold_pct, window_size, time_start, time_end, sell_after_hours, 
            jump_side, use_volume_confirmation, volume_threshold, year)
    end
end

"""Trade result"""
struct Trade
    buy_time::Time
    buy_price::Float64
    sell_time::Time
    sell_price::Float64
    return_pct::Float64
end

# =============================
# Core Functions (Single Responsibility)
# =============================

"""Load and preprocess market data for a single day"""
function load_market_data(month::Int, day::Int, ticker::String, params::TradingParams)::Union{MarketData, Nothing}
    month_str = lpad(string(month), 2, '0')
    day_str = lpad(string(day), 2, '0')
    data_path = "../$(month_str)/$(params.year)-$(month_str)-$(day_str).csv.gz"
    
    if !isfile(data_path)
        return nothing
    end

    io = GzipDecompressorStream(open(data_path))
    df = CSV.File(io) |> DataFrame
    close(io)

    # Filter for ticker
    d = @view df[df.ticker .== ticker, :]
    if isempty(d)
        return nothing
    end

    # Time processing
    dts = DateTime(1970, 1, 1) .+ Nanosecond.(d.window_start)
    times_raw = Time.(dts)
    
    # Filter by time window
    mask = Time(params.time_start) .<= times_raw .<= Time(params.time_end)
    times = times_raw[mask]
    prices = d.close[mask]
    volumes = d.volume[mask]
    
    if length(prices) < 2
        return nothing
    end
    
    return MarketData(times, prices, volumes, ticker, Date(params.year, month, day))
end

"""Detect jumps based on price change magnitude and volume confirmation"""
function detect_jumps_magnitude(prices, volumes=nothing; threshold_pct=2.0, volume_threshold=1.5, window_size=20)
    returns = diff(prices) ./ prices[1:end-1] * 100  # Percentage returns
    
    # Base threshold detection
    jump_candidates = findall(x -> abs(x) > threshold_pct, returns) .+ 1
    
    # Volume confirmation if available
    if volumes !== nothing && length(volumes) == length(prices)
        vol_ma = [mean(volumes[max(1,i-window_size):i]) for i in (window_size+1):length(volumes)]
        volume_spikes = findall(x -> x > volume_threshold, volumes[(window_size+1):end] ./ vol_ma) .+ window_size
        
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

"""Create visualization plots for jump analysis"""
function create_jump_visualization(market_data::MarketData, jump_indices, returns, trades::Vector{Trade}, params::TradingParams)
    println("Creating visualization...")
    
    # Plot 1: Price with jump annotations
    p1 = plot(market_data.times, market_data.prices, 
             label="Close Price", 
             linewidth=2, 
             color=:blue,
             title="$(market_data.ticker) - Magnitude Jump Detection (Threshold: $(params.threshold_pct)%)",
             xlabel="Time",
             ylabel="Price (\$)",
             legend=:best)
    
    # Add jump markers
    if !isempty(jump_indices)
        scatter!(p1, market_data.times[jump_indices], market_data.prices[jump_indices], 
                color=:red, 
                marker=:circle, 
                markersize=8, 
                markerstrokewidth=2,
                label="Detected $(params.jump_side) Jumps ($(length(jump_indices)))")
    end
    
    # Add sell markers and connecting lines
    if !isempty(trades)
        sell_times = [t.sell_time for t in trades]
        sell_prices = [t.sell_price for t in trades]
        buy_times = [t.buy_time for t in trades]
        buy_prices = [t.buy_price for t in trades]
        
        scatter!(p1, sell_times, sell_prices, 
                color=:green, marker=:diamond, markersize=7, 
                label="Sell (after $(params.sell_after_hours)h)")
        
        # Draw trade lines
        for (bt, bp, st, sp) in zip(buy_times, buy_prices, sell_times, sell_prices)
            plot!(p1, [bt, st], [bp, sp], color=:black, linestyle=:dot, label="")
        end
    end
    
    # Plot 2: Returns with threshold lines
    p2 = plot(market_data.times[2:end], returns, 
             label="Returns (%)", 
             linewidth=1, 
             color=:gray,
             title="Percentage Returns",
             xlabel="Time",
             ylabel="Return (%)",
             legend=:best)
    
    # Add threshold lines
    hline!(p2, [params.threshold_pct, -params.threshold_pct], 
          color=:red, 
          linestyle=:dash, 
          linewidth=2, 
          label="Threshold (±$(params.threshold_pct)%)")
    
    # Highlight detected jumps
    if !isempty(jump_indices)
        jump_return_indices = jump_indices .- 1  # Adjust for returns array
        valid_indices = jump_return_indices[jump_return_indices .>= 1]
        if !isempty(valid_indices)
            scatter!(p2, market_data.times[valid_indices .+ 1], returns[valid_indices], 
                    color=:red, 
                    marker=:circle, 
                    markersize=6,
                    label="$(params.jump_side) Jump Returns")
        end
    end
    
    # Plot 3: Volume
    p3 = plot(market_data.times, market_data.volumes, 
             label="Volume", 
             linewidth=1, 
             color=:green,
             title="Trading Volume",
             xlabel="Time",
             ylabel="Volume",
             legend=:best)
    
    # Highlight volume at jump and sell times
    if !isempty(jump_indices)
        scatter!(p3, market_data.times[jump_indices], market_data.volumes[jump_indices], 
                color=:red, 
                marker=:circle, 
                markersize=6,
                label="Volume at $(params.jump_side) Jumps")
    end
    
    if !isempty(trades)
        sell_times = [t.sell_time for t in trades]
        # Find volume indices for sell times
        sell_volume_indices = [findfirst(t -> t == st, market_data.times) for st in sell_times]
        sell_volume_indices = filter(!isnothing, sell_volume_indices)
        if !isempty(sell_volume_indices)
            scatter!(p3, market_data.times[sell_volume_indices], market_data.volumes[sell_volume_indices], 
                    color=:green, marker=:diamond, markersize=6, label="Volume at Sell")
        end
    end
    
    # Combine all plots
    return plot(p1, p2, p3, 
               layout=(3, 1), 
               size=(1200, 900),
               margin=5Plots.mm)
end

"""Print summary report for jump analysis"""
function print_jump_summary(market_data::MarketData, jump_indices, trades::Vector{Trade}, params::TradingParams)
    println("\n" * "="^60)
    println("MAGNITUDE JUMP DETECTION SUMMARY")
    println("="^60)
    println("Ticker: $(market_data.ticker)")
    println("Date: $(market_data.date)")
    println("Time window: $(params.time_start) to $(params.time_end)")
    println("Data points: $(length(market_data.prices))")
    println("Window size: $(params.window_size)")
    println("Jump threshold: $(params.threshold_pct)%")
    println("Jumps detected (after filtering $(params.jump_side)): $(length(jump_indices))")
    println()
    
    if !isempty(jump_indices) && !isempty(trades)
        println("Jump Details:")
        println("-" * "-"^85)
        println(@sprintf("%-12s %-12s %-12s %-12s %-12s %-12s %-12s", 
                        "Time", "Price", "Return (%)", "Volume", "Sell Time", "Sell Price", "Trade Ret (%)"))
        println("-" * "-"^85)
        
        for (k, (jump_idx, trade)) in enumerate(zip(jump_indices, trades))
            jump_time = market_data.times[jump_idx]
            jump_price = market_data.prices[jump_idx]
            jump_volume = market_data.volumes[jump_idx]
            
            # Calculate return compared to window_size periods ago
            lookback_idx = jump_idx - params.window_size
            price_change = if lookback_idx >= 1
                ((jump_price - market_data.prices[lookback_idx]) / market_data.prices[lookback_idx]) * 100
            else
                0.0
            end
            
            println(@sprintf("%-12s \$%-11.2f %-12.2f %-12d %-12s \$%-11.2f %-12.2f", 
                           string(jump_time), jump_price, price_change, jump_volume,
                           string(trade.sell_time), trade.sell_price, trade.return_pct))
        end
        println("-" * "-"^85)
    else
        println("No jumps detected with current threshold.")
        println("Consider lowering threshold_pct for more sensitivity.")
    end
    
    println("="^60)
end

"""Compute statistics from a collection of trades"""
function compute_trade_statistics(trades_df::DataFrame)::Dict{Symbol, Float64}
    stats = Dict{Symbol, Float64}()
    n = nrow(trades_df)
    stats[:n_trades] = Float64(n)
    
    if n == 0
        stats[:mean_return] = 0.0
        stats[:median_return] = 0.0
        stats[:std_return] = 0.0
        stats[:total_return_pct] = 0.0
        stats[:win_rate] = 0.0
        stats[:max_return] = 0.0
        stats[:min_return] = 0.0
        return stats
    end

    returns = trades_df.return_pct
    stats[:mean_return] = mean(returns)
    stats[:median_return] = Statistics.median(returns)
    stats[:std_return] = std(returns)
    stats[:total_return_pct] = sum(returns) # simple additive total
    stats[:win_rate] = count(>(0.0), returns) / n
    stats[:max_return] = maximum(returns)
    stats[:min_return] = minimum(returns)
    
    return stats
end

"""Print statistics summary"""
function print_trade_statistics(ticker::String, start_month::Int, start_day::Int, 
                               end_month::Int, end_day::Int, year::Int, stats::Dict{Symbol, Float64})
    println("\n" * "="^60)
    println("JUMP TRADE STATISTICS SUMMARY")
    println("="^60)
    println("Ticker: $(ticker)")
    println("Date Range: $(year)-$(lpad(string(start_month),2,'0'))-$(lpad(string(start_day),2,'0')) to $(year)-$(lpad(string(end_month),2,'0'))-$(lpad(string(end_day),2,'0'))")
    println("Total Trades: $(Int(stats[:n_trades]))")
    println("Mean Return: $(round(stats[:mean_return], digits=3))%")
    println("Median Return: $(round(stats[:median_return], digits=3))%")
    println("Std Dev: $(round(stats[:std_return], digits=3))%")
    println("Total Return (additive): $(round(stats[:total_return_pct], digits=3))%")
    println("Win Rate: $(round(stats[:win_rate]*100, digits=2))%")
    println("Max Return: $(round(stats[:max_return], digits=3))%")
    println("Min Return: $(round(stats[:min_return], digits=3))%")
    println("="^60)
end


"""
    visualize_magnitude_jumps(month, day, ticker; kwargs...)

Detect and visualize price jumps based on magnitude of price changes.

# Arguments
- `month::Int`: Month number (e.g., 9 for September)
- `day::Int`: Day of month (e.g., 15)
- `ticker::String`: Ticker symbol to analyze (e.g., "TSLL")
- All other arguments are passed as TradingParams (see TradingParams constructor for defaults)

# Returns
- Tuple of (filtered_jump_indices, returns, plot, trades_df)

# Example
```julia
jump_indices, returns, plt, trades = visualize_magnitude_jumps(9, 15, "TSLL", threshold_pct=2.0, jump_side=:positive, use_volume_confirmation=true)
```
"""
function visualize_magnitude_jumps(month::Int, day::Int, ticker::String; kwargs...)
    # Create trading parameters from kwargs
    params = TradingParams(; kwargs...)
    
    # Load market data
    market_data = load_market_data(month, day, ticker, params)
    if market_data === nothing
        error("No data found for ticker: $(ticker) on $(params.year)-$(lpad(month,2,'0'))-$(lpad(day,2,'0'))")
    end
    
    println("Data loaded: $(length(market_data.prices)) data points from $(market_data.times[1]) to $(market_data.times[end])")
    
    # Detect jumps
    println("Detecting jumps with threshold: $(params.threshold_pct)%, window: $(params.window_size)...")
    
    if params.use_volume_confirmation
        jump_indices, returns, volume_spikes = detect_jumps_magnitude(
            market_data.prices, market_data.volumes; 
            threshold_pct=params.threshold_pct, 
            volume_threshold=params.volume_threshold, 
            window_size=params.window_size)
        println("Volume confirmation enabled: $(length(volume_spikes)) volume spikes detected")
    else
        jump_indices, returns, _ = detect_jumps_magnitude(
            market_data.prices, nothing; 
            threshold_pct=params.threshold_pct, 
            window_size=params.window_size)
    end
    
    n_total_jumps = length(jump_indices)
    println("Found $(n_total_jumps) jumps (pre-filter)")
    
    # Filter jumps by direction
    filtered_jump_indices = filter_jumps_by_direction(jump_indices, market_data.prices, params)
    n_filtered = length(filtered_jump_indices)
    println("After filtering for $(params.jump_side): $(n_filtered) jumps (out of $(n_total_jumps))")
    
    # Compute trades
    trades = compute_trades(market_data, filtered_jump_indices, params)
    
    # Create visualization
    final_plot = create_jump_visualization(market_data, filtered_jump_indices, returns, trades, params)
    display(final_plot)
    
    # Print summary
    print_jump_summary(market_data, filtered_jump_indices, trades, params)
    
    # Convert trades to DataFrame
    trades_df = trades_to_dataframe(trades, market_data.date)
    
    return filtered_jump_indices, returns, final_plot, trades_df
end



"""
    detect_trades_for_date(month::Int, day::Int, ticker; kwargs...)

Helper: detect jumps and compute trades for a single date. Returns DataFrame of trades (may be empty).

# Arguments
- `month::Int`: Month number (1-12)
- `day::Int`: Day of month  
- `ticker::String`: Stock ticker symbol
- All other arguments are passed as TradingParams (see TradingParams constructor for defaults)

# Returns
- DataFrame with columns: date, buy_time, buy_price, sell_time, sell_price, return_pct
"""
function detect_trades_for_date(month::Int, day::Int, ticker::String; kwargs...)
    # Create trading parameters from kwargs
    params = TradingParams(; kwargs...)
    
    # Load market data
    market_data = load_market_data(month, day, ticker, params)
    if market_data === nothing
        return DataFrame()
    end

    # Detect jumps
    if params.use_volume_confirmation
        jump_indices, _, _ = detect_jumps_magnitude(
            market_data.prices, market_data.volumes; 
            threshold_pct=params.threshold_pct, 
            volume_threshold=params.volume_threshold, 
            window_size=params.window_size)
    else
        jump_indices, _, _ = detect_jumps_magnitude(
            market_data.prices, nothing; 
            threshold_pct=params.threshold_pct, 
            window_size=params.window_size)
    end

    # Filter jumps by direction
    filtered_jump_indices = filter_jumps_by_direction(jump_indices, market_data.prices, params)
    
    if isempty(filtered_jump_indices)
        return DataFrame()
    end

    # Compute trades
    trades = compute_trades(market_data, filtered_jump_indices, params)
    
    # Convert to DataFrame
    return trades_to_dataframe(trades, market_data.date)
end


"""
    compute_jump_trade_stats(start_month::Int, start_day::Int, end_month::Int, end_day::Int, ticker; kwargs...)

Loop over date range, detect jumps and compute trades, return aggregated results and statistics.

# Arguments
- `start_month::Int`: Starting month (1-12)
- `start_day::Int`: Starting day
- `end_month::Int`: Ending month (1-12)  
- `end_day::Int`: Ending day
- `ticker::String`: Stock ticker symbol
- All other arguments are passed as TradingParams (see TradingParams constructor for defaults)

# Returns
- Tuple of (trades_df::DataFrame, stats::Dict) with aggregated statistics
"""
function compute_jump_trade_stats(start_month::Int, start_day::Int, 
                                  end_month::Int, end_day::Int, 
                                  ticker::String; kwargs...)
    # Create trading parameters from kwargs
    params = TradingParams(; kwargs...)
    
    # Collect trades across date range
    all_trades = DataFrame()
    start_date = Date(params.year, start_month, start_day)
    end_date = Date(params.year, end_month, end_day)
    
    for d in start_date:Day(1):end_date
        m = Dates.month(d)
        dy = Dates.day(d)
        day_trades = detect_trades_for_date(m, dy, ticker; kwargs...)
        if !isempty(day_trades)
            append!(all_trades, day_trades)
        end
    end

    # Compute statistics
    stats = compute_trade_statistics(all_trades)
    
    # Print summary
    print_trade_statistics(ticker, start_month, start_day, end_month, end_day, params.year, stats)

    return all_trades, stats
end

