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
<!-- $\text{Put Value} = \underbrace{\text{PV}(K) \times \mathbb{P}(\text{exercise})}_{\mathrm{Money you get}} - \underbrace{S_0 \times \mathbb{P}^*(\text{risk-adjusted})}_{\mathrm{Stock you give}}$ -->

$$\text{Put Value} = \underbrace{\text{PV}(K) \times \mathbb{P}(\text{exercise})}_{\mathrm{Money\ you\ get}} - \underbrace{S_0 \times \mathbb{P}^*(\text{risk-adjusted})}_{\mathrm{Stock\ you\ give}}$$


Where:
- $\text{PV}(K)$ = **Present Value** of strike price = $Ke^{-rt}$ (future money discounted to today)
- $\mathbb{P}(\text{exercise})$ = **Probability** of exercising the option = $N(-d_2)$ for puts
- $S_0$ = Current stock price
- $\mathbb{P}^*(\text{risk-adjusted})$ = **Risk-neutral probability** = $N(-d_1)$ for puts (probability used for hedging)

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

---

## How This is Actually Used in Trading

### You DON'T Calculate Black-Scholes When Trading

**Important**: As a trader, you **almost never directly calculate** the Black-Scholes formula. Here's what actually happens:

#### When You Want to Buy a Put:

```
Your broker/exchange shows:
Put Option: Strike $100, Expiry Oct 15
Bid: $2.95
Ask: $3.05
```

**You see prices, not formulas**. Market makers have already priced the options using Black-Scholes (or more sophisticated models).

**You simply**:
1. Look at the Ask price ($3.05)
2. Decide if it's worth it for your strategy
3. Click "Buy"
4. Pay $3.05 per share ($305 per contract)

**No calculation required** — the market has done the pricing for you.

---

### So Why Learn Black-Scholes?

Even though you don't calculate it manually, BS is essential for understanding **what drives option prices** and **how to evaluate if an option is expensive or cheap**.

#### 1. Understanding What You're Paying For

When you see a put option costs $3.05, Black-Scholes tells you this price reflects:

| Component | What It Means | How to Check |
|-----------|--------------|--------------|
| **Intrinsic Value** | $\max(K - S_0, 0)$ | If stock is $98 and strike is $100: intrinsic = $2 |
| **Time Value** | Premium - Intrinsic | $3.05 - $2 = $1.05 time value |
| **Implied Volatility** | Market's expectation of future moves | High IV after jumps = expensive options |
| **Time Decay (Theta)** | How much you lose per day | Same-day options bleed fast |

**Practical use**: 
- If IV is historically high (IVR > 70%), you're overpaying
- If theta is large ($-0.30/day), your option bleeds $30/day on a 100-share contract
- This tells you whether the trade makes sense

---

#### 2. Working Backwards: Finding Implied Volatility

This is the **primary real-world use** of Black-Scholes for traders.

**The Process**:

```
Known:
- Market price of put = $3.05 (observed)
- Stock price S₀ = $98
- Strike K = $100
- Time t = 1 day (0.0027 years)
- Rate r = 0.05

Unknown:
- What volatility (σ) does the market expect?
```

**Solve**: Find σ such that $V_{BS}(S_0, K, t, r, \sigma) = \$3.05$

This gives you **Implied Volatility (IV)**.

**Why this matters**:
- If IV = 45% but historical RV = 25%, options are **expensive** (market expects volatility)
- If IV = 20% but RV = 35%, options are **cheap** (market is underpricing volatility)

**For your strategy**: After a morning jump, IV spikes. You're buying when IV might be 50-60%, but normal IV might be 30%. This means you're overpaying by ~40-60%.

---

#### 3. Estimating the Greeks Without Calculation

Black-Scholes derivatives give you the Greeks. Your broker displays these:

```
Put Option Display:
Price: $3.05
Delta: -0.35
Gamma: 0.08
Theta: -$0.28/day
Vega: $0.12
```

**You don't calculate these** — your platform does. But understanding BS helps you interpret them:

| Greek | What You Check | Trading Decision |
|-------|----------------|------------------|
| **Delta** | If -0.35, stock drops $1 → put gains ~$0.35 | Need $10 drop to gain $3.50 |
| **Theta** | Losing $0.28/day | In 3 hours (1/8 day) you lose ~$0.035 |
| **Vega** | Gains $0.12 per 1% IV increase | If IV drops 5%, you lose $0.60 even if stock doesn't move |
| **Gamma** | How fast delta changes | High gamma near expiry = unstable position |

**Practical decision**: If theta is -$0.28/day and you're trading same-day, you need the stock to drop quickly. If it trades sideways for 2 hours, you've already lost ~$0.12 to time decay.

---

#### 4. Comparing Options: Which Strike to Buy?

You're deciding between three puts. Your broker shows:

| Strike | Premium | Delta | Theta | IV | Break-Even |
|--------|---------|-------|-------|----|-----------| 
| $100 (ITM) | $5.50 | -0.75 | -$0.45 | 40% | Stock → $94.50 |
| $98 (ATM) | $3.05 | -0.50 | -$0.35 | 42% | Stock → $94.95 |
| $95 (OTM) | $1.20 | -0.25 | -$0.15 | 45% | Stock → $93.80 |

**Without BS knowledge**: You might just pick the cheapest.

**With BS knowledge**: You understand:
- OTM is cheaper but needs a BIGGER move (delta only -0.25)
- OTM has higher IV (45% vs 40%) = more expensive per unit of probability
- ATM has highest theta = bleeds fastest
- ITM has better delta but costs more upfront

**Your decision** depends on:
- How confident are you in a big drop? → OTM
- Want balanced risk/reward? → ATM
- High conviction, willing to pay? → ITM

BS framework helps you understand these trade-offs.

---

#### 5. Deciding When to Exit

You bought the put at $3.05. Stock drops to $96. Your put is now worth $3.80.

**Question**: Sell now (+$0.75 profit) or hold for more?

**BS thinking helps**:

```
Time passed: 2 hours (still 6 hours to close)
Theta cost: ~$0.10 already eaten
Current IV: Dropped from 42% to 38% (vol crush)
Vega loss: -4% IV × $0.12 = -$0.48

Without IV drop, your put would be worth: $3.80 + $0.48 = $4.28
Stock move gave you: $4.28 - $3.05 = $1.23
But IV crush cost you: $0.48
Net gain: $0.75
```

**Insight**: You made money on direction, but volatility crush cost you 40% of potential gains. This explains why your profit is less than expected.

**Decision**: If IV is still elevated (IVR > 50%), it might drop further. Sell now. If IV has normalized, you can hold.

---

### The Real Trading Workflow

#### Before the Trade:

1. **Check IV Percentile** (IVR or IV Rank)
   - IVR < 30% → Options are cheap historically
   - IVR > 70% → Options are expensive historically
   - **Your situation**: Post-jump IVR is probably 80-90% → very expensive

2. **Estimate Required Move**
   - Use Delta: If delta = -0.35, you need ~$3 drop per $1 profit
   - Check break-even: Strike - Premium
   - **Your situation**: Need 3-5% drop in hours → high bar

3. **Assess Time Decay**
   - Look at Theta
   - Calculate: How much will I lose per hour?
   - **Your situation**: 0DTE options, theta might be -$0.50/day = -$0.02/hour

#### During the Trade:

4. **Monitor Greeks, Not Just Price**
   - Is delta changing (gamma risk)?
   - Is IV dropping (vega risk)?
   - How much theta have I paid?

5. **Set Exit Rules**
   - Target profit: "Exit if I make 50% ($1.50 on $3 put)"
   - Stop loss: "Exit if down 30% (put drops to $2.10)"
   - Time stop: "Exit at 2pm regardless" (avoid last-hour theta burn)

#### After the Trade:

6. **Post-Trade Analysis**
   - Did IV crush hurt me?
   - Was theta worse than expected?
   - Did I actually need that strike, or should I have gone ATM?

**Black-Scholes framework** guides all these decisions, even though you never manually calculate the formula.

---

### Summary: BS is a Framework, Not a Calculator

| What You DON'T Do | What You DO Do |
|-------------------|----------------|
| Calculate BS formula by hand | Check IV percentile (expensive vs cheap?) |
| Derive the PDE | Compare strikes using Delta/Theta |
| Compute $N(d_1)$ manually | Understand why IV spike makes options expensive |
| Solve for option price | Work backwards to find implied volatility |
| Memorize formulas | Use Greeks to estimate P&L and risk |

**The key insight**: Black-Scholes is the **language** of options markets. Market makers use it to quote prices. Your broker uses it to calculate Greeks. You use it to:
- Understand what you're paying for
- Evaluate if options are expensive (high IV)
- Estimate how much you'll make/lose
- Decide which strike/expiry to trade
- Know when to exit

**For your strategy**: BS tells you that buying puts right after a morning jump means:
1. High IV → You overpay
2. Short time → Theta kills you fast  
3. Need significant move → Delta requires big drop
4. IV will likely drop → Vega works against you

This is why your strategy has a 60-80% cost headwind — all visible through the BS framework.

You don't calculate the formula, but you **must understand it** to trade options successfully.

---

## Critical Clarification: BS Calculates Present Value at ANY Moment

### A Common Confusion

**Wrong thinking**: "BS is for pricing when I buy, then I need a different formula when I sell"

**Correct thinking**: "BS prices the option at ANY moment in time. Market makers run it continuously. I see the results as Bid/Ask prices"

### The Market Pricing Loop

Every second, this is happening:

```
Market Makers → Run BS with current data → Update Bid/Ask → You see prices
      ↑                                                            ↓
      └─────────── Adjust continuously as inputs change ───────────┘
```

**You never calculate BS yourself** - you just see the final Bid/Ask prices that result from these calculations.

---

### BS Works at Every Point in Time

Black-Scholes gives you the option's **present value** at any moment, whether:
- 9:30 AM when you're **buying**
- 11:00 AM when you're **monitoring**  
- 2:00 PM when you're **selling**

The formula continuously recalculates as inputs change:
- Stock price $S_0$ (updates every second)
- Time remaining $t$ (counts down continuously)
- Implied volatility $\sigma$ (changes with market conditions)

---

### Example: Your Trade Timeline

Let's walk through what's happening behind the scenes:

#### 9:30 AM - You Want to Buy

**Market maker's BS calculation:**
```
Inputs:
- Stock price S₀ = $100
- Strike K = $98
- Time to close t = 6.5 hours = 6.5/(24×252) ≈ 0.00107 years
- Implied volatility σ = 45% (elevated after jump)
- Risk-free rate r = 5%

BS Output: Put value = $3.05
```

**What you see on screen:**
```
Put Option $98 Strike
Bid: $2.95
Ask: $3.05

[Buy Button]
```

**You click "Buy" and pay $3.05** - no calculation needed on your part.

---

#### 11:00 AM - Stock Drops, You Check

**Market maker's BS calculation (automatically updated):**
```
Inputs:
- Stock price S₀ = $96 ← Changed!
- Strike K = $98
- Time to close t = 5 hours = 5/(24×252) ≈ 0.00082 years ← Less time
- Implied volatility σ = 38% ← Decreased!
- Risk-free rate r = 5%

BS Output: Put value = $3.80
```

**What you see:**
```
Put Option $98 Strike
Bid: $3.75
Ask: $3.85
Your Position: +$0.75 (bought at $3.05)
```

---

#### 2:00 PM - You Want to Sell

**Market maker's BS calculation:**
```
Inputs:
- Stock price S₀ = $95 ← Dropped more!
- Strike K = $98
- Time to close t = 2 hours = 2/(24×252) ≈ 0.00033 years ← Much less time
- Implied volatility σ = 35% ← Normalized
- Risk-free rate r = 5%

BS Output: Put value = $4.20
```

**What you see:**
```
Put Option $98 Strike
Bid: $4.15
Ask: $4.25

[Sell Button]
```

**You click "Sell" and receive $4.15** - again, no calculation needed.

**Your profit:** $4.15 - $3.05 = **$1.10 per share**

---

### How BS Was Used Throughout

| Time | What Changed | BS Recalculated | Result | Your Action |
|------|--------------|-----------------|---------|-------------|
| **9:30 AM** | Jump happened, IV spiked | Put worth $3.05 | Ask = $3.05 | You buy |
| **9:31 AM** | Stock moved slightly | Put worth $3.02 | Bid/Ask updates | You hold |
| **9:45 AM** | Stock dropped $1 | Put worth $3.35 | Bid/Ask updates | You hold |
| **11:00 AM** | Stock at $96, IV dropped | Put worth $3.80 | Bid/Ask updates | You monitor |
| **2:00 PM** | Stock at $95, time running out | Put worth $4.20 | Bid = $4.15 | You sell |

**Every single price** (whether you're buying, holding, or selling) comes from BS being calculated with current market conditions.

---

### Why Understanding BS Matters (Even Though You Don't Calculate It)

#### When Buying (9:30 AM):

**You see:** Ask = $3.05

**BS knowledge helps:**
- "IV is 45%, but historical average is 30% → I'm overpaying by ~40%"
- "Theta is -$0.40/day → I lose $0.05/hour from time decay"
- "Delta is -0.35 → I need $3 drop to make $1"

**Decision:** "Worth it only if I expect a big, fast drop"

---

#### During Trade (11:00 AM):

**You see:** Current value $3.80 (up $0.75)

**BS knowledge helps:**
- "Stock dropped $4, but my put only gained $0.75... why?"
- "IV dropped from 45% to 38% (7% decrease)"
- "Vega is $0.12, so -7% IV cost me -7 × $0.12 = -$0.84"
- "I lost $0.10 to theta (1.5 hours elapsed)"
- "Stock move gave me ~$1.40, but IV crush + theta cost $0.94"

**Understanding:** "I'm fighting IV crush - need to sell soon before it drops more"

---

#### When Selling (2:00 PM):

**You see:** Bid = $4.15

**BS knowledge helps:**
- "Stock dropped $5 total, my put should be worth more..."
- "But time is almost up (high theta cost)"
- "And IV dropped from 45% to 35% (10% total decline)"
- "Profit is less than expected, but IV normalized - good time to exit"

**Decision:** "Take the $1.10 profit before theta eats more"

---

### Analogy: Like Stock Prices

Think of it like stock prices:

**Stocks:**
- Price updates every second based on supply/demand
- You see: "AAPL: $175.50"
- You don't calculate this price - market determines it
- But understanding valuation (P/E, growth, etc.) helps you know if it's expensive

**Options:**
- Price updates every second based on BS inputs
- You see: "Put: Bid $4.15 / Ask $4.25"
- You don't calculate BS - market makers do it
- But understanding BS (IV, theta, delta, etc.) helps you know if it's expensive

---

### The Bottom Line

**Three Key Points:**

1. **BS is continuous**: It calculates present value at ANY moment (buying, holding, selling)

2. **Market does the math**: Your broker/exchange runs BS automatically and shows you Bid/Ask

3. **You use the framework**: Even without calculating, BS helps you:
   - Know when you're overpaying (high IV)
   - Estimate your edge (delta vs theta)
   - Understand P&L (why gains are less than expected)
   - Make better decisions (which strike, when to exit)

**For your strategy:** Every time you check the option price (whether buying at 9:30 AM or selling at 2 PM), that price came from BS being calculated with current conditions. You see the result, not the formula.

Understanding BS doesn't mean calculating it yourself - it means understanding **why** the prices are what they are and **how** they'll change as market conditions evolve.