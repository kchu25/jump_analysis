# Black-Scholes: Intuitive Explanation

## The Big Question

**How much should you pay today for the right (but not obligation) to buy/sell a stock at a fixed price in the future?**

This is what Black-Scholes answers. It's a formula that tells you the "fair value" of an option based on observable inputs.

---

## The Core Insight

An option's value comes from **uncertainty about the future**:
- If you knew exactly where the stock would be, options would be simple to price
- Because the future is uncertain, there's a range of possible outcomes
- Black-Scholes calculates the **expected value** across all these possible outcomes

**Key principle**: The option is worth the **average payoff across all possible future stock prices**, adjusted for the probability of each outcome and discounted to present value.

---

## The Formula (Put Option)

$$V_{BS}^{\text{put}} = Ke^{-rt}N(-d_2) - S_0N(-d_1)$$

This looks intimidating, but it has a beautiful intuitive structure.

---

## Breaking It Down: Two Parts

The formula consists of **two terms**:

$$\underbrace{Ke^{-rt}N(-d_2)}_{\text{Part 1: Money you receive}} - \underbrace{S_0N(-d_1)}_{\text{Part 2: Stock you give up}}$$

### For a Put Option:

| Part | Formula | Intuitive Meaning |
|------|---------|-------------------|
| **Part 1** | $Ke^{-rt}N(-d_2)$ | **Present value** of the strike price you'll receive, weighted by probability you'll exercise |
| **Part 2** | $S_0N(-d_1)$ | **Current value** of the stock you'll give up, weighted by risk-adjusted probability |

**Put option value** = Expected money you receive - Expected stock you surrender

---

## Understanding Each Component

### 1. The Strike Price Term: $Ke^{-rt}$

$$Ke^{-rt}$$

- $K$ = Strike price (the money you receive if you exercise)
- $e^{-rt}$ = **Discount factor** (converts future money to present value)
- $r$ = Risk-free interest rate (e.g., 5% = 0.05)
- $t$ = Time to expiration (in years)

**Intuition**: Money in the future is worth less than money today. If $K = \$100$ and you receive it in 1 year at 5% interest, its present value is $100 \times e^{-0.05 \times 1} \approx \$95.12$.

**Example**:
- Strike $K = \$100$
- Time $t = 0.25$ years (3 months)
- Rate $r = 0.05$
- Present value: $100 \times e^{-0.05 \times 0.25} = 100 \times 0.9876 = \$98.76$

---

### 2. The Probability Terms: $N(d_1)$ and $N(d_2)$

$N(\cdot)$ is the **cumulative standard normal distribution** — it gives probabilities.

**What $N(x)$ means**: The probability that a standard normal random variable is less than $x$.

| Value | $N(x)$ | Interpretation |
|-------|--------|----------------|
| $x = 0$ | 0.50 | 50% probability |
| $x = 1$ | 0.84 | 84% probability |
| $x = -1$ | 0.16 | 16% probability |
| $x = 2$ | 0.977 | 97.7% probability |

**For puts**: 
- $N(-d_2)$ ≈ **Probability the option expires in-the-money** (stock price < strike)
- $N(-d_1)$ ≈ **Risk-adjusted probability** used for hedging (related to delta)

---

### 3. The $d_1$ and $d_2$ Terms

$$d_1 = \frac{\ln(S_0/K) + (r + \sigma^2/2)t}{\sigma\sqrt{t}}$$

$$d_2 = d_1 - \sigma\sqrt{t}$$

These look complex, but they encode everything about the option's "moneyness" and uncertainty.

#### Breaking down $d_1$:

**Numerator**: $\ln(S_0/K) + (r + \sigma^2/2)t$

- $\ln(S_0/K)$ = How far is the stock from the strike? (log ratio)
  - $S_0 > K$ → positive (stock above strike, put is OTM)
  - $S_0 < K$ → negative (stock below strike, put is ITM)
- $(r + \sigma^2/2)t$ = Drift term (expected growth + volatility adjustment)

**Denominator**: $\sigma\sqrt{t}$

- $\sigma$ = Volatility (uncertainty about future price)
- $\sqrt{t}$ = Time scaling (more time = more uncertainty)
- Together: "How many standard deviations can the stock move?"

**Intuition**: 
- Large positive $d_1$ → Stock is far above strike → Put is unlikely to pay off → Low value
- Large negative $d_1$ → Stock is far below strike → Put is likely to pay off → High value

---

## Putting It All Together: The Economic Story

### For a Put Option:

**Scenario**: You own a put with strike $K = \$100$, stock is at $S_0 = \$95$.

1. **What happens if you exercise?**
   - You sell stock worth $\$95$ (current market value)
   - You receive $\$100$ (the strike price)
   - Your gain: $\$5$

2. **But will you exercise?**
   - Only if the stock is below $K$ at expiration
   - Probability of this: $N(-d_2)$

3. **Black-Scholes calculation**:
   - Expected strike you receive: $K \times e^{-rt} \times N(-d_2)$
   - Expected stock value you give up: $S_0 \times N(-d_1)$
   - Put value: The difference

---

## Why This Formula?

The Black-Scholes formula comes from solving a **partial differential equation** (PDE) that describes how option prices must evolve to prevent arbitrage.

### The Key Assumptions:

1. **Stock follows geometric Brownian motion**: 
   $$dS = \mu S dt + \sigma S dW$$
   - Stock returns are normally distributed
   - Volatility $\sigma$ is constant

2. **No arbitrage**: You can't make risk-free profits by combining stocks and options

3. **Continuous trading**: You can trade and hedge at any moment

4. **No transaction costs**: No fees or spreads

### The PDE:

$$\frac{\partial V}{\partial t} + \frac{1}{2}\sigma^2 S^2 \frac{\partial^2 V}{\partial S^2} + rS\frac{\partial V}{\partial S} - rV = 0$$

**Black-Scholes is the closed-form solution** to this equation with the appropriate boundary conditions.

---

## Visual Intuition: The Probability Distribution

Imagine the stock price at expiration follows a bell curve (lognormal distribution):

```
Probability
    ^
    |     /\
    |    /  \
    |   /    \___
    |  /         \___
    |_/_______________\___> Stock Price at Expiration
         K (Strike)
    
    [Put pays off here]
```

**For a put**:
- You profit when stock ends up **left of the strike** (below $K$)
- Black-Scholes integrates over all possible outcomes, weighted by probability
- The formula calculates: Expected payoff × Probability - Cost of stock

---

## The Five Inputs and Their Impact

| Input | Symbol | Meaning | Effect on Put Value |
|-------|--------|---------|---------------------|
| **Stock Price** | $S_0$ | Current market price | ↑ $S_0$ → ↓ Put value |
| **Strike Price** | $K$ | Exercise price | ↑ $K$ → ↑ Put value |
| **Time to Expiry** | $t$ | Time remaining (years) | ↑ $t$ → ↑ Put value (usually) |
| **Volatility** | $\sigma$ | Expected fluctuation | ↑ $\sigma$ → ↑ Put value |
| **Interest Rate** | $r$ | Risk-free rate | ↑ $r$ → ↓ Put value (small effect) |

### Why Volatility Increases Put Value?

Higher volatility = wider distribution of outcomes = higher chance of large moves.

```
Low Vol:      High Vol:
    ^             ^
    |  /\         |   /\
    | /  \        |  /  \
    |/____\       | /    \
    |      S      |/_     _\> S
         K              K

More probability    More probability
of small moves      of LARGE moves
                    (benefits puts!)
```

With high volatility, there's a greater chance the stock drops far below the strike, making the put more valuable.

---

## Example Calculation

Let's price a 3-month put option:

**Inputs**:
- $S_0 = \$100$ (current stock price)
- $K = \$95$ (strike price, OTM put)
- $t = 0.25$ years (3 months)
- $\sigma = 0.30$ (30% annual volatility)
- $r = 0.05$ (5% interest rate)

**Step 1**: Calculate $d_1$

$$d_1 = \frac{\ln(100/95) + (0.05 + 0.30^2/2) \times 0.25}{0.30 \times \sqrt{0.25}}$$

$$d_1 = \frac{\ln(1.0526) + (0.05 + 0.045) \times 0.25}{0.30 \times 0.5}$$

$$d_1 = \frac{0.0513 + 0.0238}{0.15} = \frac{0.0751}{0.15} = 0.501$$

**Step 2**: Calculate $d_2$

$$d_2 = d_1 - \sigma\sqrt{t} = 0.501 - 0.30 \times 0.5 = 0.501 - 0.15 = 0.351$$

**Step 3**: Look up probabilities

- $N(-d_1) = N(-0.501) \approx 0.308$ (30.8%)
- $N(-d_2) = N(-0.351) \approx 0.363$ (36.3%)

**Step 4**: Calculate put value

$$V_{put} = 95 \times e^{-0.05 \times 0.25} \times 0.363 - 100 \times 0.308$$

$$V_{put} = 95 \times 0.9876 \times 0.363 - 100 \times 0.308$$

$$V_{put} = 34.05 - 30.80 = \$3.25$$

**Result**: This OTM put is worth approximately **$3.25**.

---

## Why Black-Scholes Won the Nobel Prize

Before Black-Scholes (1973):
- Options were priced by intuition and negotiation
- No consensus on "fair value"
- Risk management was crude

After Black-Scholes:
- **Standardized pricing**: Everyone agrees on the formula
- **Risk management**: Greeks allow precise hedging
- **Liquid markets**: Market makers can quote prices instantly
- **Financial innovation**: Enabled derivatives markets to explode

**Impact**: It transformed options from exotic instruments to mainstream financial tools. The formula is used trillions of times per day in global markets.

---

## Limitations (Why Real Markets Differ)

Black-Scholes makes simplifying assumptions that don't hold in reality:

| Assumption | Reality | Market Fix |
|-----------|---------|-----------|
| Constant volatility | Vol changes over time | Use implied volatility surface |
| Normal returns | Fat tails, jumps, crashes | Adjust for skew, use jump models |
| No transaction costs | Spreads, commissions exist | Account for in pricing |
| Continuous trading | Discrete trades, gaps | Add friction costs |
| No dividends | Stocks pay dividends | Adjust formula: $S_0 \to S_0 e^{-qt}$ |

This is why **implied volatility varies by strike and expiry** (the volatility surface) — the market prices violations of Black-Scholes assumptions.

---

## Summary: The Intuition

**Black-Scholes answers**: What's the fair price for uncertain future payoffs?

**The formula structure**:
$$\text{Put Value} = \underbrace{\text{PV(Strike)} \times P(\text{exercise})}_{\text{Money you get}} - \underbrace{\text{Stock} \times P(\text{risk-adjusted})}_{\text{Stock you give}}$$

**Core insights**:
1. Options are worth more when the future is more uncertain (higher $\sigma$)
2. More time = more uncertainty = higher value
3. The probability terms weight outcomes by their likelihood
4. The discount factor converts future payoffs to present value

**Practical use**: While traders don't calculate BS by hand, it provides the framework for:
- Implied volatility (solve for $\sigma$ given market price)
- The Greeks (derivatives of the formula)
- Understanding how inputs affect option prices

The formula is elegant because it reduces a complex stochastic problem (uncertain future stock prices) to a simple closed-form solution based on five observable inputs.