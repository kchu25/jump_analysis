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
    visualize_magnitude_jumps(month, day, ticker; threshold_pct=1.5, window_size=20, time_start="9:45", time_end="15:45", jump_side=:both)

Detect and visualize price jumps based on magnitude of price changes.

# Arguments
- `month::Int`: Month number (e.g., 9 for September)
- `day::Int`: Day of month (e.g., 15)
- `ticker::String`: Ticker symbol to analyze (e.g., "TSLL")
- `threshold_pct::Float64`: Percentage threshold for jump detection (default: 1.5%)
- `window_size::Int`: Window size for rolling calculations (default: 20)
- `time_start::String`: Start time for analysis window (default: "9:45")
- `time_end::String`: End time for analysis window (default: "15:45")
- `jump_side::Symbol|String`: Which jumps to display: `:positive`, `:negative`, or `:both` (default: `:both`). Strings are accepted (case-insensitive).

# Returns
- Tuple of (filtered_jump_indices, returns, plot)

# Example
```julia
jump_indices, returns, plt = visualize_magnitude_jumps(9, 15, "TSLL", threshold_pct=2.0, jump_side=:positive)
```
"""
function visualize_magnitude_jumps(month::Int, day::Int, ticker::String; 
                                   threshold_pct::Float64=1.5,
                                   window_size::Int=20,
                                   time_start::String="9:45",
                                   time_end::String="15:45",
                                   jump_side::Union{Symbol,String} = :both,
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
    
    # Calculate percentage returns
    returns = diff(prices) ./ prices[1:end-1] * 100  # Percentage returns
    
    # Detect jumps where absolute return exceeds threshold
    jump_indices = findall(x -> abs(x) > threshold_pct, returns) .+ 1
    
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

    # Filter jumps by sign if requested
    if n_total_jumps > 0
        # returns indices corresponding to jump_indices are jump_indices .- 1
        jump_return_idxs = jump_indices .- 1
        # guard against any 0/negative indices
        valid_mask = jump_return_idxs .>= 1
        valid_jump_indices = jump_indices[valid_mask]
        valid_return_idxs = jump_return_idxs[valid_mask]

        jump_returns = returns[valid_return_idxs]

        if jump_side == :positive
            keep_mask = jump_returns .> 0
        elseif jump_side == :negative
            keep_mask = jump_returns .< 0
        else
            keep_mask = trues(length(jump_returns))
        end

        filtered_jump_indices = valid_jump_indices[keep_mask]
        n_filtered = length(filtered_jump_indices)
    else
        filtered_jump_indices = Int[]
        n_filtered = 0
    end

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
        
        for jump_idx in filtered_jump_indices
            jump_time = times[jump_idx]
            jump_price = prices[jump_idx]
            jump_volume = volumes[jump_idx]
            
            # Calculate return for this jump
            if jump_idx > 1
                prev_price = prices[jump_idx - 1]
                price_change = ((jump_price - prev_price) / prev_price) * 100
            else
                price_change = 0.0
            end
            
            println(@sprintf("%-12s \$%-11.2f %-12.2f %-12d", 
                           string(jump_time), jump_price, price_change, jump_volume))
        end
        println("-" * "-"^58)
    else
        println("No jumps detected with current threshold.")
        println("Consider lowering threshold_pct for more sensitivity.")
    end
    
    println("="^60)
    
    return filtered_jump_indices, returns, final_plot
end


# =============================
# Example Usage
# =============================
if abspath(PROGRAM_FILE) == @__FILE__
    # Example: Run the analysis
    
    
    month = 2
    day = 27
    ticker = "TSLL"
    threshold = 1.5
    window_size = 20
    jump_indices, returns, plt = visualize_magnitude_jumps(month, day, ticker, threshold_pct=threshold, 
    window_size=window_size, 
    jump_side=:negative)




end
