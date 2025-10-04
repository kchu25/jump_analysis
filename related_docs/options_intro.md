# Essential Options Trading Concepts for Algo Trading

## 1. The Greeks: Risk Exposures

| Greek | Formula | Range | Intuition | Algo Relevance |
|-------|---------|-------|-----------|----------------|
| **Delta (Δ)** | $\Delta = \frac{\partial V}{\partial S}$ | Put: $-1 < \Delta < 0$ | \$1 stock move = $\|\Delta\|$ option move | Hedge ratio; Delta-neutral = no directional exposure |
| **Gamma (Γ)** | $\Gamma = \frac{\partial^2 V}{\partial S^2}$ | Always positive | How fast Delta changes; high $\Gamma$ = unstable position | Peaks ATM near expiry; large moves blow up position |
| **Theta (θ)** | $\theta = \frac{\partial V}{\partial t}$ | Always negative (long) | Lose $\|\theta\|$ per day from time passing | 0DTE options lose 20-50% in hours; theta kills same-day trades |
| **Vega (ν)** | $\nu = \frac{\partial V}{\partial \sigma}$ | Always positive (long) | IV spike = option price up (even if stock flat) | Right on direction but lose on IV crush = common trap |

### Key Greek Relationships
- **Gamma peaks**: ATM options near expiration
- **Theta accelerates**: Exponentially near expiry (last week: 30-50% decay)
- **Vega matters**: Post-jump IV is elevated → you overpay for options

---

## 2. Black-Scholes Framework

### Call and Put Pricing

$$C = S_0 N(d_1) - Ke^{-rt}N(d_2)$$

$$P = Ke^{-rt}N(-d_2) - S_0N(-d_1)$$

Where:
$$d_1 = \frac{\ln(S_0/K) + (r + \sigma^2/2)t}{\sigma\sqrt{t}}$$

$$d_2 = d_1 - \sigma\sqrt{t}$$

### Parameters

| Parameter | Symbol | Meaning | Algo Impact |
|-----------|--------|---------|-------------|
| Stock Price | $S_0$ | Current price | Your entry point |
| Strike Price | $K$ | Exercise price | Choose based on desired $\Delta$ |
| Volatility | $\sigma$ | Implied volatility | Jumps = high IV = expensive options |
| Time | $t$ | Time to expiry | Small $t$ = fast decay |
| Rate | $r$ | Risk-free rate | Mostly irrelevant for short-term |

**Critical Insight**: Options price *expected* volatility, not realized. Post-jump, everyone expects moves → options already expensive.

---

## 3. Volatility Concepts

| Type | Definition | Formula | Trading Implication |
|------|------------|---------|---------------------|
| **Implied Volatility (IV)** | Market's expected future volatility | Derived from option prices | High after jumps (bad for buyers) |
| **Realized Volatility (RV)** | Actual historical volatility | $\sigma_{RV} = \sqrt{252} \times \text{std}(r_{\text{daily}})$ | Compare to IV to find edge |
| **IV Rank (IVR)** | Current IV relative to range | $\text{IVR} = \frac{IV - IV_{52w,\text{low}}}{IV_{52w,\text{high}} - IV_{52w,\text{low}}}$ | IVR > 50% = buying expensive |

### The Volatility Trade
- **Buying options** = long volatility (profitable if $RV > IV$)
- **After jump**: IV spikes → you buy high → need massive move to profit
- **Expected Move**: $EM = S_0 \times IV \times \sqrt{t/252}$

---

## 4. Moneyness and Strike Selection

| Type | Condition (Put) | Delta Range | Characteristics | Use Case |
|------|----------------|-------------|-----------------|----------|
| **ATM** | $S \approx K$ | $\Delta \approx -0.5$ | Highest $\Gamma$, most $\theta$ decay | Balanced risk/reward |
| **OTM** | $S > K$ | $-0.5 < \Delta < 0$ | Cheaper, needs bigger move | Lottery ticket; your likely choice |
| **ITM** | $S < K$ | $-1 < \Delta < -0.5$ | Expensive, acts like stock short | High probability, high cost |

**For Your Strategy**: OTM puts ($\Delta \approx -0.3$ to $-0.4$) keep cost down, but require SIGNIFICANT drop.

---

## 5. Value Components and Relationships

### Put-Call Parity
$$P + S = C + PV(K)$$
No arbitrage between puts, calls, and stock.

### Option Value Decomposition
$$\text{Put Value} = \max(K - S, 0) + \text{Time Value}$$

| Component | Before Expiry | At Expiry | What Decays |
|-----------|--------------|-----------|-------------|
| **Intrinsic** | $\max(K-S, 0)$ | $\max(K-S, 0)$ | Never |
| **Extrinsic** | Priced by BS model | 0 | This is $\theta$ |

---

## 6. Execution and Market Microstructure

| Concept | Formula | Typical Values | Algo Impact |
|---------|---------|----------------|-------------|
| **Bid-Ask Spread** | $\text{Ask} - \text{Bid}$ | 2-10% of price | Instant loss on entry |
| **Mid Price** | $\frac{\text{Bid} + \text{Ask}}{2}$ | Theoretical | Can't actually trade here |
| **Slippage** | $\|\text{Fill} - \text{Mid}\|$ | 5-20% of spread | Must account in backtest |

### Liquidity Filters for Algos
```python
if volume < 100 or open_interest < 500:
    skip_this_option()  # Too illiquid
```

**Reality**: 
- You buy at Ask, sell at Bid → immediate 2-10% loss
- On volatile jumps: spreads widen = worse fills
- First 5 min: widest spreads, most chaotic

---

## 7. Advanced Volatility Structure

### Volatility Smile and Skew
- **Smile**: IV varies by strike (U-shaped curve)
- **Skew**: OTM puts have HIGHER IV (fear premium) → your puts cost more
- **Term Structure**: IV varies by expiry; front-month most volatile

### Volatility Surface
$$\sigma = f(K, T)$$
IV is a function of both strike $K$ and time to expiry $T$.

---

## 8. Position Sizing and Risk Management

| Metric | Formula | Guideline |
|--------|---------|-----------|
| **Max Loss** | Premium paid | 100% of position (options can → 0) |
| **Position Size** | - | 1-2% account risk per trade MAX |
| **Kelly Criterion** | $f^* = \frac{pb - q}{b}$ | Use $\frac{1}{4}$ Kelly to avoid ruin |
| **Expectancy** | $E = (p \times W) - (q \times L)$ | Must be > 0 after all costs |

Where: $p$ = win probability, $q = 1-p$, $b$ = win/loss ratio, $W$ = avg win, $L$ = avg loss

---

## 9. Break-Even Analysis

### Long Put Break-Even
$$\text{Break-even} = K - \text{Premium Paid}$$

Stock must drop to this level for you to profit at expiration.

### Profit/Loss at Expiration
$$\text{P/L} = \max(K - S_T, 0) - \text{Premium}$$

**Before expiration**: Value includes time value, so P/L is more complex.

---

## 10. The Complete Cost Stack (Your Reality)

| Cost Component | Impact | Magnitude |
|----------------|--------|-----------|
| **Theta Decay** | $-\|\theta\|$ per day | -$X$ every hour |
| **High IV** | Post-jump elevation | Overpay 10-30% |
| **Delta Requirement** | Need significant move | 2-5%+ drop to profit |
| **Bid-Ask Spread** | Entry/exit slippage | Instant 1-3% loss |
| **15-min Delay** | Missed optimal entry | Worse pricing |

### Profitability Condition
$$(\text{Win Rate} \times \text{Avg Win}) > (\text{Loss Rate} \times \text{Avg Loss}) + \theta_{\text{cost}} + \text{Spread Cost}$$

**Rough requirement**: Need 60%+ win rate OR 3:1 reward:risk ratio.

---

## 11. Recommended Trading Progression

| Stage | Instrument | Why | Complexity |
|-------|-----------|-----|------------|
| **1. Validate Edge** | Short stock | Clean P/L, no Greeks, no $\theta$ | Low |
| **2. Add Definition** | Put spreads | Defined risk, less $\theta$ | Medium |
| **3. Optimize Returns** | Naked puts | Max leverage (if edge proven) | High |

**Critical**: Most retail algo traders lose on options by underestimating $\theta$ decay and overestimating directional edge.

---

## Summary: Big Picture for Your Strategy

Your **challenge stack**:
1. Racing the clock (theta decay)
2. Buying expensive (elevated post-jump IV)
3. Need large move (OTM puts require significant drop)
4. Execution costs (bid-ask spread)
5. Information delay (15-min lag)

**Math reality**: Each of these eats 10-20% of potential profit. Stacked together, they create a ~60-80% headwind.

**Path forward**: Prove the directional edge exists with simpler instruments (short stock) BEFORE adding options complexity.