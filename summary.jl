
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