
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
**Now parallelized using threading for better performance on multi-core systems.**

# Arguments
- `start_month::Int`: Starting month (1-12)
- `start_day::Int`: Starting day
- `end_month::Int`: Ending month (1-12)  
- `end_day::Int`: Ending day
- `ticker::String`: Stock ticker symbol
- All other arguments are passed as TradingParams (see TradingParams constructor for defaults)

# Performance
- Uses `Threads.@threads` to process dates in parallel
- Performance scales with available CPU cores
- For large date ranges (>100 days), consider `compute_jump_trade_stats_distributed`

# Returns
- Tuple of (trades_df::DataFrame, stats::Dict) with aggregated statistics
"""
function compute_jump_trade_stats(start_month::Int, start_day::Int, 
                                  end_month::Int, end_day::Int, 
                                  ticker::String; kwargs...)
    # Create trading parameters from kwargs
    params = TradingParams(; kwargs...)
    
    # Collect trades across date range (parallelized)
    start_date = Date(params.year, start_month, start_day)
    end_date = Date(params.year, end_month, end_day)
    date_range = collect(start_date:Day(1):end_date)
    n_dates = length(date_range)
    
    println("Processing $(n_dates) dates using $(Threads.nthreads()) threads...")
    start_time = time()
    
    # Parallel processing using threads
    trades_per_date = Vector{DataFrame}(undef, n_dates)
    
    Threads.@threads for i in 1:n_dates
        d = date_range[i]
        m = Dates.month(d)
        dy = Dates.day(d)
        trades_per_date[i] = detect_trades_for_date(m, dy, ticker; kwargs...)
    end
    
    # Combine non-empty results
    all_trades = DataFrame()
    for day_trades in trades_per_date
        if !isempty(day_trades)
            append!(all_trades, day_trades)
        end
    end
    
    elapsed_time = time() - start_time
    println("✅ Parallel processing completed in $(round(elapsed_time, digits=2)) seconds")

    # Compute statistics
    stats = compute_trade_statistics(all_trades)
    
    # Print summary
    print_trade_statistics(ticker, start_month, start_day, end_month, end_day, params.year, stats)

    return all_trades, stats
end


"""
    compute_jump_trade_stats_distributed(start_month::Int, start_day::Int, end_month::Int, end_day::Int, ticker; kwargs...)

Distributed version of compute_jump_trade_stats for processing large date ranges across multiple processes.
Requires: `using Distributed; addprocs(n)` where n is number of worker processes.

# Arguments
- Same as compute_jump_trade_stats

# Returns
- Tuple of (trades_df::DataFrame, stats::Dict) with aggregated statistics

# Example
```julia
using Distributed
addprocs(4)  # Add 4 worker processes
@everywhere include("try_mag_jump.jl")
trades, stats = compute_jump_trade_stats_distributed(9, 1, 9, 30, "TSLL", threshold_pct=2.0)
```
"""
# function compute_jump_trade_stats_distributed(start_month::Int, start_day::Int, 
#                                             end_month::Int, end_day::Int, 
#                                             ticker::String; kwargs...)
#     # Create trading parameters from kwargs
#     params = TradingParams(; kwargs...)
    
#     # Collect trades across date range using distributed computing
#     start_date = Date(params.year, start_month, start_day)
#     end_date = Date(params.year, end_month, end_day)
#     date_range = collect(start_date:Day(1):end_date)
    
#     # Check if Distributed is available
#     if !isdefined(Main, :Distributed) || nprocs() == 1
#         @warn "Distributed computing not available or no worker processes. Using threaded version instead."
#         return compute_jump_trade_stats(start_month, start_day, end_month, end_day, ticker; kwargs...)
#     end
    
#     # Distributed processing
#     @eval using Distributed
#     trades_per_date = @distributed (vcat) for d in date_range
#         m = Dates.month(d)
#         dy = Dates.day(d)
#         day_trades = detect_trades_for_date(m, dy, ticker; kwargs...)
#         isempty(day_trades) ? DataFrame() : day_trades
#     end
    
#     # Filter out empty DataFrames and combine
#     all_trades = trades_per_date
    
#     # Compute statistics
#     stats = compute_trade_statistics(all_trades)
    
#     # Print summary
#     print_trade_statistics(ticker, start_month, start_day, end_month, end_day, params.year, stats)

#     return all_trades, stats
# end



"""
    get_threading_info()

Display information about available threading and processing resources.
"""
function get_threading_info()
    println("Threading and Parallel Processing Information:")
    println("=" * "="^50)
    println("Available threads: $(Threads.nthreads())")
    println("Available processes: $(nprocs())")
    println("Worker processes: $(nprocs() - 1)")
    println()
    println("Performance recommendations:")
    if Threads.nthreads() == 1
        println("⚠️  Only 1 thread available. Set JULIA_NUM_THREADS=N before starting Julia for threading benefits.")
    else
        println("✅ $(Threads.nthreads()) threads available for parallel processing.")
    end
    
    if nprocs() == 1
        println("💡 For distributed processing, run: using Distributed; addprocs(N)")
    else
        println("✅ $(nprocs() - 1) worker processes available for distributed computing.")
    end
    
    println()
    println("Usage examples:")
    println("• Threaded (current): compute_jump_trade_stats(...)")
    println("• Distributed: compute_jump_trade_stats_distributed(...)")
    println("=" * "="^50)
end

