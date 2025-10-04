# Strike Price: Options Terminology Explained

## What is Strike Price?

**Strike price (K)** = The **predetermined price** at which you have the **right** to buy (for calls) or sell (for puts) the underlying stock.

**Important**: Strike does NOT mean "buy" — it's the exercise price written into the option contract.

---

## For Put Options (Your Strategy)

When you buy a put option with strike price $K$:
- You have the **right to sell** the stock at price $K$
- This right is valuable when the stock price falls below $K$
- You profit when the market price is significantly below your strike

### Example: $100 Strike Put

You buy a put option with strike $K = \$100$ for a premium of $\$3$.

| Stock Price | Put Value (approx) | Your P/L | Explanation |
|-------------|-------------------|----------|-------------|
| $\$105$ | $\$0$ | $-\$3$ (loss) | No value; why sell at $100 when market is $105? |
| $\$100$ | $\$0-3$ | $-\$3$ to $\$0$ | At-the-money; only time value remains |
| $\$95$ | $\$5$ | $+\$2$ (profit) | Intrinsic value = $100 - $95 = $5; minus $3 premium = $2 profit |
| $\$90$ | $\$10$ | $+\$7$ (profit) | Intrinsic value = $100 - $90 = $10; minus $3 premium = $7 profit |
| $\$85$ | $\$15$ | $+\$12$ (profit) | Intrinsic value = $100 - $85 = $15; minus $3 premium = $12 profit |

**Key insight**: Your strike price ($100) is the level at which you can **sell** the stock. The lower the market price goes below your strike, the more profitable your put becomes.

---

## Complete Options Terminology

| Term | Definition | Example |
|------|------------|---------|
| **Strike Price (K)** | Predetermined exercise price in the contract | $K = \$100$ means you can sell at $100 (put) or buy at $100 (call) |
| **Premium** | The price you **pay** to buy an option | You pay $\$3$ to acquire the put option |
| **Buy / Go Long** | Purchase an option (you pay premium) | "Buy a $100 strike put for $3" |
| **Sell / Go Short / Write** | Sell an option (you collect premium) | "Sell a $100 strike put, collect $3" (risky: unlimited downside) |
| **Exercise** | Actually use your right in the contract | Exercise the put = sell stock at strike price $K$ |
| **Intrinsic Value** | How much the option is "in the money" | For put: $\max(K - S, 0)$ where $S$ is stock price |
| **Extrinsic Value** | Time value + volatility value | Premium - Intrinsic Value |
| **Expiration** | Date when option contract ends | Options expire worthless if not in-the-money |

---

## Your Strategy Broken Down

**What you're doing**:
1. **Buy a put option** (go long a put)
2. **Choose a strike price $K$** (e.g., $K = $ current price or slightly below)
3. **Pay a premium** (this is your maximum loss)
4. **Hope the stock drops** below $K$ by afternoon
5. **Sell the put** (close position) for a profit if stock dropped

**Example trade**:
```
Morning: Stock jumps to $50
You buy: $48 strike put for $1.50 premium
Afternoon: Stock drops to $46
Your put is now worth: ~$2.50 (intrinsic: $48-$46=$2, plus remaining time value)
You sell: Close the put for $2.50
Profit: $2.50 - $1.50 = $1.00 per share
```

---

## Strike Selection Matters

| Strike Choice | Delta | Cost | Probability | Required Move |
|--------------|-------|------|-------------|---------------|
| **ATM** (At-the-money) | ~-0.50 | Medium | ~50% | Moderate drop needed |
| **OTM** (Out-of-the-money) | -0.30 to -0.40 | Cheap | ~30-40% | Large drop needed |
| **ITM** (In-the-money) | -0.60 to -0.90 | Expensive | ~60-90% | Small drop needed |

**For your strategy**: You'll likely choose **OTM puts** (strike below current price) to keep costs low, but this requires a significant drop to profit.

---

## Common Confusion: Strike vs Premium

| Aspect | Strike Price | Premium |
|--------|-------------|----------|
| **What it is** | Exercise price in contract | Price you pay for the option |
| **Fixed?** | Yes (set at purchase) | No (changes continuously) |
| **Who sets it** | Exchange (standardized strikes) | Market (supply/demand) |
| **Your cash flow** | No money changes hands | You pay this upfront |
| **Example** | $K = \$100$ | Premium = $\$3$ per share |

**The transaction**: You pay the **premium** ($3) to buy an option that gives you the right to sell at the **strike** ($100).

---

## Quick Reference: Put Option Payoff

At expiration, a long put is worth:

$$\text{Put Value} = \max(K - S_T, 0)$$

Your profit/loss:

$$\text{P/L} = \max(K - S_T, 0) - \text{Premium Paid}$$

Where:
- $K$ = strike price
- $S_T$ = stock price at expiration (or when you close)
- Premium Paid = what you paid upfront

**Break-even**: Stock must drop to $K - \text{Premium}$ for you to break even at expiration.

Example: $100 strike put, $3 premium → break-even at $\$97$

---

## Summary

- **Strike price** ≠ "buy" — it's the **exercise price** in the contract
- For puts: Strike is the price at which you can **sell** the stock
- You **pay a premium** to buy the option
- You profit when stock price drops **below** your strike (minus the premium you paid)
- Strike selection involves a trade-off: lower strikes are cheaper but need bigger moves

In your jump-fade strategy, you're buying OTM puts hoping the stock drops enough below your strike to overcome the premium paid and time decay.