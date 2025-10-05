# Algorithmic Trading Bot Overview

This document outlines the general structure and operation of an algorithmic trading bot, which can be run as a background service under `systemd`.

---

## General Idea

An **algo trading bot** typically:

1. Connects to a **broker or exchange API** (e.g., Interactive Brokers, Binance, Alpaca).
2. **Fetches live market data** (prices, volumes, etc.).
3. **Applies a trading strategy** to decide whether to buy or sell.
4. **Sends orders** to the exchange.
5. **Monitors positions**, **logs performance**, and **handles errors/restarts**.

### Market Hours

- Bots usually operate only during market hours (e.g., 9:30am–4:00pm ET for U.S. stocks).
- For crypto or other 24/7 markets, the bot may run continuously.
- Outside trading hours, the bot may idle or perform analytics/backtesting.

---

## General Pseudocode

```python
# trading_bot.py

initialize_broker_connection(api_key, secret_key)
initialize_logger()
load_strategy_parameters()

while True:
    current_time = now()

    # Only trade during market hours
    if market_is_open(current_time):
        prices = fetch_market_data(symbols=["AAPL", "GOOG"])
        signals = strategy(prices)           # compute buy/sell/hold decisions

        for sym, signal in signals.items():
            if signal == "BUY":
                place_order(sym, "buy", amount=calculate_size(sym))
            elif signal == "SELL":
                place_order(sym, "sell", amount=calculate_size(sym))
        
        update_position_status()
        log_trades_and_pnl()
    
    else:
        sleep_until_next_market_open()

    sleep(60)  # wait before next cycle (1 minute)
