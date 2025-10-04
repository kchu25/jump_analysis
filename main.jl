
    include("try_mag_jump.jl")

    month = 7
    day = 21
    ticker = "TSLL"
    threshold = 1.5
    window_size = 20

    jump_indices, returns, plt, trades = 
    visualize_magnitude_jumps(month, day, ticker, threshold_pct=threshold, 
    window_size=window_size, 
    volume_threshold=2.0,
    jump_side=:positive,
    sell_after_hours=3.0)


@time compute_jump_trade_stats(7, 1, 7, 30, "TSLL"; 
                         threshold_pct=1.5, 
                         window_size=20, 
                         time_start="9:45", 
                         time_end="15:45", 
                         sell_after_hours=3.0, 
                         jump_side=:positive,
                         use_volume_confirmation=true,
                         volume_threshold=2.0)