
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