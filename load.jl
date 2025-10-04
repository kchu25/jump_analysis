

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
    times = @view times_raw[mask]
    prices = @view d.close[mask]
    volumes = @view d.volume[mask]

    if length(prices) < 2
        return nothing
    end
    
    return MarketData(times, prices, volumes, ticker, Date(params.year, month, day))
end