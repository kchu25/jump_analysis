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


"""
    detect_jumps_magnitude(prices, volumes=nothing; threshold_pct=2.0, volume_threshold=1.5, window_size=20)

Detect jumps based on price change magnitude and volume confirmation.

# Arguments
- `prices`: Vector of prices
- `volumes`: Optional vector of volumes (same length as prices)
- `threshold_pct`: Percentage threshold for jump detection (default: 2.0%)
- `volume_threshold`: Volume spike multiplier (default: 1.5x moving average)
- `window_size`: Window size for volume moving average (default: 20)

# Returns
- Tuple of (jump_indices, returns, volume_spikes)
"""
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


"""
    visualize_magnitude_jumps(month, day, ticker; threshold_pct=1.5, window_size=20, time_start="9:45", time_end="15:45", jump_side=:both)

Detect and visualize price jumps based on magnitude of price changes.

# Arguments
- `month::Int`: Month number (e.g., 9 for September)
- `day::Int`: Day of month (e.g., 15)
- `ticker::String`: Ticker symbol to analyze (e.g., "TSLL")
- `threshold_pct::Float64`: Percentage threshold for jump detection (default: 1.5%)
- `window_size::Int`: Window size for rolling calculations and jump_side comparison (default: 20)
- `time_start::String`: Start time for analysis window (default: "9:45")
- `time_end::String`: End time for analysis window (default: "15:45")
- `jump_side::Symbol|String`: Which jumps to display based on price change vs `window_size` periods ago: `:positive`, `:negative`, or `:both` (default: `:both`)
- `sell_after_hours::Real`: Hours to hold before selling (default: 2.0)
- `use_volume_confirmation::Bool`: Whether to require volume confirmation for jumps (default: false)
- `volume_threshold::Float64`: Volume spike multiplier for confirmation (default: 1.5)

# Returns
- Tuple of (filtered_jump_indices, returns, plot, trades_df)

# Example
```julia
jump_indices, returns, plt, trades = visualize_magnitude_jumps(9, 15, "TSLL", threshold_pct=2.0, jump_side=:positive, use_volume_confirmation=true)
```
"""
function visualize_magnitude_jumps(month::Int, day::Int, ticker::String; 
                                   threshold_pct::Float64=1.5,
                                   window_size::Int=20,
                                   time_start::String="9:45",
                                   time_end::String="15:45",
                                   jump_side::Union{Symbol,String} = :both,
                                   sell_after_hours::Real = 2.0,
                                   use_volume_confirmation::Bool = false,
                                   volume_threshold::Float64 = 1.5,
                                   )
    
    # =============================
    # Load and prepare data
    # =============================
    # Construct data path from month and day
    month_str = lpad(string(month), 2, '0')
    day_str = lpad(string(day), 2, '0')
    data_path = "../$(month_str)/2025-$(month_str)-$(day_str).csv.gz"
    
    println("Loading data from $(data_path)...")
    
    io = GzipDecompressorStream(open(data_path))
    df = CSV.File(io) |> DataFrame
    close(io)
    
    # Filter for ticker
    d = @view df[df.ticker .== ticker, :]
    
    if isempty(d)
        error("No data found for ticker: $(ticker)")
    end
    
    # Time processing
    dts = DateTime(1970, 1, 1) .+ Nanosecond.(d.window_start)
    d.date_only = Date.(dts)
    d.time_only = Time.(dts)
    
    # Filter by time window
    mask = Time(time_start) .<= d.time_only .<= Time(time_end)
    times = d.time_only[mask]
    prices = d.close[mask]
    volumes = d.volume[mask]
    
    if length(prices) < 2
        error("Not enough data points in the specified time window")
    end
    
    println("Data loaded: $(length(prices)) data points from $(times[1]) to $(times[end])")
    
    # =============================
    # Jump Detection: Magnitude-based
    # =============================
    println("Detecting jumps with threshold: $(threshold_pct)%, window: $(window_size)...")
    
    # Use helper function for jump detection
    if use_volume_confirmation
        jump_indices, returns, volume_spikes = detect_jumps_magnitude(prices, volumes; 
                                                                      threshold_pct=threshold_pct, 
                                                                      volume_threshold=volume_threshold, 
                                                                      window_size=window_size)
        println("Volume confirmation enabled: $(length(volume_spikes)) volume spikes detected")
    else
        jump_indices, returns, _ = detect_jumps_magnitude(prices, nothing; 
                                                         threshold_pct=threshold_pct, 
                                                         window_size=window_size)
    end
    
    n_total_jumps = length(jump_indices)
    println("Found $(n_total_jumps) jumps (pre-filter)")
    println()

    # Normalize jump_side to a Symbol and validate
    if isa(jump_side, String)
        jump_side = Symbol(lowercase(strip(jump_side)))
    end
    if !(jump_side in (:positive, :negative, :both))
        error("Invalid value for jump_side. Use :positive, :negative, or :both (or corresponding strings).")
    end

    # Filter jumps by sign (comparing to price window_size periods ago)
    filtered_jump_indices = Int[]
    if n_total_jumps > 0 && jump_side != :both
        for jidx in jump_indices
            # Compare current price to price window_size periods ago
            lookback_idx = jidx - window_size
            if lookback_idx >= 1
                price_change_pct = ((prices[jidx] - prices[lookback_idx]) / prices[lookback_idx]) * 100
                
                if (jump_side == :positive && price_change_pct > 0) || 
                   (jump_side == :negative && price_change_pct < 0)
                    push!(filtered_jump_indices, jidx)
                end
            end
        end
    elseif jump_side == :both
        filtered_jump_indices = jump_indices
    end
    
    n_filtered = length(filtered_jump_indices)
    println("After filtering for $(jump_side): $(n_filtered) jumps (out of $(n_total_jumps))")

    
    # =============================
    # Visualization
    # =============================
    println("Creating visualization...")
    
    # Plot 1: Price with jump annotations
    p1 = plot(times, prices, 
             label="Close Price", 
             linewidth=2, 
             color=:blue,
             title="$(ticker) - Magnitude Jump Detection (Threshold: $(threshold_pct)%)",
             xlabel="Time",
             ylabel="Price (\$)",
             legend=:best)
    
    # Add jump markers (filtered)
    if !isempty(filtered_jump_indices)
        scatter!(p1, times[filtered_jump_indices], prices[filtered_jump_indices], 
                color=:red, 
                marker=:circle, 
                markersize=8, 
                markerstrokewidth=2,
                label="Detected $(jump_side) Jumps ($(length(filtered_jump_indices)))")
    end
    
    # Plot 2: Returns with threshold lines
    p2 = plot(times[2:end], returns, 
             label="Returns (%)", 
             linewidth=1, 
             color=:gray,
             title="Percentage Returns",
             xlabel="Time",
             ylabel="Return (%)",
             legend=:best)
    
    # Add threshold lines
    hline!(p2, [threshold_pct, -threshold_pct], 
          color=:red, 
          linestyle=:dash, 
          linewidth=2, 
          label="Threshold (±$(threshold_pct)%)")
    
    # Highlight detected jumps (filtered)
    if !isempty(filtered_jump_indices)
        jump_return_indices = filtered_jump_indices .- 1  # Adjust for returns array
        valid_indices = jump_return_indices[jump_return_indices .>= 1]
        if !isempty(valid_indices)
            scatter!(p2, times[valid_indices .+ 1], returns[valid_indices], 
                    color=:red, 
                    marker=:circle, 
                    markersize=6,
                    label="$(jump_side) Jump Returns")
        end
    end
    
    # Plot 3: Volume
    p3 = plot(times, volumes, 
             label="Volume", 
             linewidth=1, 
             color=:green,
             title="Trading Volume",
             xlabel="Time",
             ylabel="Volume",
             legend=:best)
    
    # Highlight volume at jump times (filtered)
    if !isempty(filtered_jump_indices)
        scatter!(p3, times[filtered_jump_indices], volumes[filtered_jump_indices], 
                color=:red, 
                marker=:circle, 
                markersize=6,
                label="Volume at $(jump_side) Jumps")
    end

    # Compute sell points (after sell_after_hours) and plot them
    sell_indices = Int[]
    sell_times_vec = Time[]
    sell_prices = Float64[]
    trade_returns = Float64[]

    if !isempty(filtered_jump_indices) && sell_after_hours > 0
        sell_delta = Minute(Int(round(sell_after_hours * 60)))
        for jidx in filtered_jump_indices
            buy_time = times[jidx]
            target_time = buy_time + sell_delta
            sidx = findfirst(t -> t >= target_time, times)
            if sidx === nothing
                sidx = lastindex(times)
            end
            push!(sell_indices, sidx)
            push!(sell_times_vec, times[sidx])
            push!(sell_prices, prices[sidx])
            buy_price = prices[jidx]
            push!(trade_returns, ((prices[sidx] - buy_price) / buy_price) * 100)
        end

        # Plot sell markers and connecting lines on p1
        scatter!(p1, times[sell_indices], sell_prices, color=:green, marker=:diamond, markersize=7, label="Sell (after $(sell_after_hours)h)")
        # draw lines from buy to sell for each trade
        for (bi, si) in zip(filtered_jump_indices, sell_indices)
            plot!(p1, [times[bi], times[si]], [prices[bi], prices[si]], color=:black, linestyle=:dot, label="")
        end

        # Also show volume at sell times on p3
        scatter!(p3, times[sell_indices], volumes[sell_indices], color=:green, marker=:diamond, markersize=6, label="Volume at Sell")
    end
    
    # Combine all plots
    final_plot = plot(p1, p2, p3, 
                     layout=(3, 1), 
                     size=(1200, 900),
                     margin=5Plots.mm)
    
    display(final_plot)
    
    # =============================
    # Summary Report
    # =============================
    println("\n" * "="^60)
    println("MAGNITUDE JUMP DETECTION SUMMARY")
    println("="^60)
    println("Ticker: $(ticker)")
    println("Date: 2025-$(lpad(string(month), 2, '0'))-$(lpad(string(day), 2, '0'))")
    println("Time window: $(time_start) to $(time_end)")
    println("Data points: $(length(prices))")
    println("Window size: $(window_size)")
    println("Jump threshold: $(threshold_pct)%")
    println("Jumps detected (after filtering $(jump_side)): $(length(filtered_jump_indices))")
    println()
    
    if !isempty(filtered_jump_indices)
        println("Jump Details:")
        println("-" * "-"^58)
        println(@sprintf("%-12s %-12s %-12s %-12s", "Time", "Price", "Return (%)", "Volume"))
        println("-" * "-"^58)
        
        for (k, jump_idx) in enumerate(filtered_jump_indices)
            jump_time = times[jump_idx]
            jump_price = prices[jump_idx]
            jump_volume = volumes[jump_idx]
            
            # Calculate return compared to window_size periods ago
            lookback_idx = jump_idx - window_size
            if lookback_idx >= 1
                price_change = ((jump_price - prices[lookback_idx]) / prices[lookback_idx]) * 100
            else
                price_change = 0.0
            end

            # Sell info if computed
            sell_info = ""
            if !isempty(sell_prices)
                sprice = sell_prices[k]
                stime = sell_times_vec[k]
                sell_ret = trade_returns[k]
                sell_info = @sprintf(" | Sell: %s \$%.2f (%.2f%%)", string(stime), sprice, sell_ret)
            end
            
            println(@sprintf("%-12s \$%-11.2f %-12.2f %-12d%s", 
                           string(jump_time), jump_price, price_change, jump_volume, sell_info))
        end
        println("-" * "-"^58)
    else
        println("No jumps detected with current threshold.")
        println("Consider lowering threshold_pct for more sensitivity.")
    end
    
    println("="^60)
    
    # Build trades DataFrame to return (if any)
    trades_df = DataFrame()
    if !isempty(filtered_jump_indices) && !isempty(sell_indices)
        trades_df = DataFrame(
            buy_time=times[filtered_jump_indices], 
            buy_price=prices[filtered_jump_indices],
            sell_time=sell_times_vec, 
            sell_price=sell_prices, 
            return_pct=trade_returns
        )
    end
    
    return filtered_jump_indices, returns, final_plot, trades_df
end



"""
    detect_trades_for_date(month::Int, day::Int, ticker; year=2025, kwargs...)

Helper: detect jumps and compute trades (buy at jump, sell after sell_after_hours) for a single date.
Returns a DataFrame of trades (may be empty) and does not plot.

# Arguments
- `month::Int`: Month number (1-12)
- `day::Int`: Day of month
- `ticker::String`: Stock ticker symbol
- `year::Int`: Year (default: 2025)
- Other keyword arguments same as visualize_magnitude_jumps

# Returns
- DataFrame with columns: date, buy_time, buy_price, sell_time, sell_price, return_pct
"""
function detect_trades_for_date(month::Int, day::Int, ticker::String; 
                                year::Int=2025,
                                threshold_pct::Float64=1.5,
                                window_size::Int=20,
                                time_start::String="9:45",
                                time_end::String="15:45",
                                sell_after_hours::Real=2.0,
                                jump_side::Union{Symbol,String} = :both,
                                use_volume_confirmation::Bool = false,
                                volume_threshold::Float64 = 1.5)

    month_str = lpad(string(month), 2, '0')
    day_str = lpad(string(day), 2, '0')
    data_path = "../$(month_str)/$(year)-$(month_str)-$(day_str).csv.gz"
    
    if !isfile(data_path)
        return DataFrame()
    end

    io = GzipDecompressorStream(open(data_path))
    df = CSV.File(io) |> DataFrame
    close(io)

    d = @view df[df.ticker .== ticker, :]
    if isempty(d)
        return DataFrame()
    end

    dts = DateTime(1970, 1, 1) .+ Nanosecond.(d.window_start)
    d.time_only = Time.(dts)
    mask = Time(time_start) .<= d.time_only .<= Time(time_end)
    times = d.time_only[mask]
    prices = d.close[mask]
    volumes = d.volume[mask]

    if length(prices) < 2
        return DataFrame()
    end

    # Use helper function for jump detection
    if use_volume_confirmation
        jump_indices, returns, _ = detect_jumps_magnitude(prices, volumes; 
                                                          threshold_pct=threshold_pct, 
                                                          volume_threshold=volume_threshold, 
                                                          window_size=window_size)
    else
        jump_indices, returns, _ = detect_jumps_magnitude(prices, nothing; 
                                                          threshold_pct=threshold_pct, 
                                                          window_size=window_size)
    end

    # normalize jump_side
    if isa(jump_side, String)
        jump_side = Symbol(lowercase(strip(jump_side)))
    end
    if !(jump_side in (:positive, :negative, :both))
        error("Invalid jump_side")
    end

    if isempty(jump_indices)
        return DataFrame()
    end

    # Filter jumps by sign (comparing to price window_size periods ago)
    filtered_jump_indices = Int[]
    if !isempty(jump_indices)
        if jump_side == :both
            filtered_jump_indices = jump_indices
        else
            for jidx in jump_indices
                lookback_idx = jidx - window_size
                if lookback_idx >= 1
                    price_change_pct = ((prices[jidx] - prices[lookback_idx]) / prices[lookback_idx]) * 100
                    
                    if (jump_side == :positive && price_change_pct > 0) || 
                       (jump_side == :negative && price_change_pct < 0)
                        push!(filtered_jump_indices, jidx)
                    end
                end
            end
        end
    end
    
    if isempty(filtered_jump_indices)
        return DataFrame()
    end

    # compute sells
    sell_delta = Minute(Int(round(sell_after_hours * 60)))
    sell_indices = Int[]
    sell_times_vec = Time[]
    sell_prices = Float64[]
    trade_returns = Float64[]
    
    for jidx in filtered_jump_indices
        buy_time = times[jidx]
        target_time = buy_time + sell_delta
        sidx = findfirst(t -> t >= target_time, times)
        if sidx === nothing
            sidx = lastindex(times)
        end
        push!(sell_indices, sidx)
        push!(sell_times_vec, times[sidx])
        push!(sell_prices, prices[sidx])
        buy_price = prices[jidx]
        push!(trade_returns, ((prices[sidx] - buy_price) / buy_price) * 100)
    end

    date_val = Date(year, month, day)
    trades_df = DataFrame(
        date = fill(date_val, length(filtered_jump_indices)),
        buy_time = times[filtered_jump_indices], 
        buy_price = prices[filtered_jump_indices],
        sell_time = sell_times_vec, 
        sell_price = sell_prices, 
        return_pct = trade_returns
    )
    return trades_df
end


"""
    compute_jump_trade_stats(start_month::Int, start_day::Int, end_month::Int, end_day::Int, ticker; year=2025, kwargs...)

Loop over the date range (inclusive), detect jumps and simulated trades (buy at jump, sell after sell_after_hours),
and return a tuple (trades_df, stats_dict) where trades_df contains one row per trade and stats_dict contains summary metrics.

# Arguments
- `start_month::Int`: Starting month (1-12)
- `start_day::Int`: Starting day
- `end_month::Int`: Ending month (1-12)
- `end_day::Int`: Ending day
- `ticker::String`: Stock ticker symbol
- `year::Int`: Year (default: 2025)
- Other keyword arguments same as visualize_magnitude_jumps

# Returns
- Tuple of (trades_df::DataFrame, stats::Dict) with aggregated statistics
"""
function compute_jump_trade_stats(start_month::Int, start_day::Int, 
                                  end_month::Int, end_day::Int, 
                                  ticker::String; 
                                  year::Int=2025,
                                  threshold_pct::Float64=1.5,
                                  window_size::Int=20,
                                  time_start::String="9:45",
                                  time_end::String="15:45",
                                  sell_after_hours::Real=2.0,
                                  jump_side::Union{Symbol,String} = :both,
                                  use_volume_confirmation::Bool = false,
                                  volume_threshold::Float64 = 1.5)

    trades = DataFrame()
    start_date = Date(year, start_month, start_day)
    end_date = Date(year, end_month, end_day)
    
    for d in start_date:Day(1):end_date
    m = Dates.month(d)
    dy = Dates.day(d)
        day_trades = detect_trades_for_date(m, dy, ticker; 
                                           year=year,
                                           threshold_pct=threshold_pct, 
                                           window_size=window_size,
                                           time_start=time_start, 
                                           time_end=time_end,
                                           sell_after_hours=sell_after_hours, 
                                           jump_side=jump_side,
                                           use_volume_confirmation=use_volume_confirmation,
                                           volume_threshold=volume_threshold)
        if !isempty(day_trades)
            append!(trades, day_trades)
        end
    end

    stats = Dict()
    n = nrow(trades)
    stats[:n_trades] = n
    
    if n == 0
        stats[:mean_return] = 0.0
        stats[:median_return] = 0.0
        stats[:std_return] = 0.0
        stats[:total_return_pct] = 0.0
        stats[:win_rate] = 0.0
        stats[:max_return] = 0.0
        stats[:min_return] = 0.0
        return trades, stats
    end

    returns = trades.return_pct
    stats[:mean_return] = mean(returns)
    stats[:median_return] = Statistics.median(returns)
    stats[:std_return] = std(returns)
    stats[:total_return_pct] = sum(returns) # simple additive total (not compounded)
    stats[:win_rate] = count(>(0.0), returns) / n
    stats[:max_return] = maximum(returns)
    stats[:min_return] = minimum(returns)

    println("\n" * "="^60)
    println("JUMP TRADE STATISTICS SUMMARY")
    println("="^60)
    println("Ticker: $(ticker)")
    println("Date Range: $(year)-$(lpad(string(start_month),2,'0'))-$(lpad(string(start_day),2,'0')) to $(year)-$(lpad(string(end_month),2,'0'))-$(lpad(string(end_day),2,'0'))")
    println("Total Trades: $(n)")
    println("Mean Return: $(round(stats[:mean_return], digits=3))%")
    println("Median Return: $(round(stats[:median_return], digits=3))%")
    println("Std Dev: $(round(stats[:std_return], digits=3))%")
    println("Total Return (additive): $(round(stats[:total_return_pct], digits=3))%")
    println("Win Rate: $(round(stats[:win_rate]*100, digits=2))%")
    println("Max Return: $(round(stats[:max_return], digits=3))%")
    println("Min Return: $(round(stats[:min_return], digits=3))%")
    println("="^60)

    return trades, stats
end

