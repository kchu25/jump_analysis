

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
        legend=:outerright)

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
        label="Jump percentage (%)",
        linewidth=1,
        color=:gray,
        title="Jump Percentage",
        xlabel="Time",
        ylabel="Return (%)",
        legend=:outerright)

    # Add threshold lines
    hline!(p2, [params.threshold_pct, -params.threshold_pct],
        color=:red,
        linestyle=:dash,
        linewidth=2,
        label="Threshold (±$(params.threshold_pct)%)")

    # Highlight detected jumps
    if !isempty(jump_indices)
        jump_return_indices = jump_indices .- 1  # Adjust for returns array
        valid_indices = jump_return_indices[jump_return_indices.>=1]
        if !isempty(valid_indices)
            scatter!(p2, market_data.times[valid_indices.+1], returns[valid_indices],
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
        legend=:outerright)

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
