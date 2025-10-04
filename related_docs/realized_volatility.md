# Realized Volatility: Complete Mathematical Explanation

## What is Realized Volatility?

**Realized Volatility (RV)** measures the actual historical volatility of a stock based on observed price movements. It quantifies how much the stock price has fluctuated over a given period.

---

## Step-by-Step Calculation

### Step 1: Calculate Daily Returns

Given a sequence of closing prices $P_0, P_1, P_2, \ldots, P_n$ over $n$ days:

$$r_i = \ln\left(\frac{P_i}{P_{i-1}}\right) = \ln(P_i) - \ln(P_{i-1})$$

**Variables**:
- $P_i$ = closing price on day $i$
- $P_{i-1}$ = closing price on the previous day
- $r_i$ = **log return** (continuous return) on day $i$
- $\ln$ = natural logarithm

**Why log returns?**
- They are additive: $r_{1\to 3} = r_1 + r_2 + r_3$
- More theoretically sound for statistical analysis
- Assumption: returns follow a normal distribution (in Black-Scholes framework)

**Example**:
- Day 1: $P_0 = \$100$, Day 2: $P_1 = \$102$
- $r_1 = \ln(102/100) = \ln(1.02) \approx 0.0198$ or 1.98%

---

### Step 2: Calculate Standard Deviation of Daily Returns

$$\sigma_{\text{daily}} = \sqrt{\frac{1}{n-1} \sum_{i=1}^{n} (r_i - \bar{r})^2}$$

**Variables**:
- $n$ = number of days in the sample period
- $r_i$ = daily return on day $i$
- $\bar{r}$ = mean (average) of all daily returns = $\frac{1}{n}\sum_{i=1}^{n} r_i$
- $\sigma_{\text{daily}}$ = standard deviation of daily returns
- $(n-1)$ = **Bessel's correction** (unbiased estimator for sample standard deviation)

**Interpretation**: This measures the typical day-to-day fluctuation in returns.

**Example**:
- If daily returns are: 1%, -0.5%, 2%, 0.5%, -1%
- Calculate mean, then compute deviations from mean, square them, average, and take square root

---

### Step 3: Annualize the Daily Volatility

$$\sigma_{\text{annual}} = \sigma_{\text{daily}} \times \sqrt{252}$$

**Variables**:
- $\sigma_{\text{annual}}$ = **annualized volatility** (the final realized volatility)
- $\sigma_{\text{daily}}$ = daily standard deviation from Step 2
- $252$ = typical number of trading days per year (excludes weekends and holidays)
- $\sqrt{252} \approx 15.87$

**Why multiply by $\sqrt{252}$?**

This comes from the statistical property that **variance scales linearly with time** for independent random variables.

#### Mathematical Derivation:

Assume daily returns $r_i$ are independent and identically distributed (i.i.d.) with variance $\sigma_{\text{daily}}^2$.

Over $T$ days, the cumulative return is:
$$R_T = r_1 + r_2 + \cdots + r_T$$

The variance of the sum of independent random variables is:
$$\text{Var}(R_T) = \text{Var}(r_1) + \text{Var}(r_2) + \cdots + \text{Var}(r_T) = T \times \sigma_{\text{daily}}^2$$

Therefore, the standard deviation over $T$ days is:
$$\sigma_T = \sqrt{\text{Var}(R_T)} = \sqrt{T \times \sigma_{\text{daily}}^2} = \sqrt{T} \times \sigma_{\text{daily}}$$

For one year ($T = 252$ trading days):
$$\sigma_{\text{annual}} = \sqrt{252} \times \sigma_{\text{daily}}$$

**Intuition**: Volatility grows with the square root of time, not linearly. A stock with 2% daily volatility has roughly $2\% \times 15.87 \approx 31.7\%$ annual volatility, not $2\% \times 252 = 504\%$.

---

## Complete Formula

Putting it all together:

$$\boxed{\sigma_{RV} = \sqrt{252} \times \sqrt{\frac{1}{n-1} \sum_{i=1}^{n} \left(\ln\frac{P_i}{P_{i-1}} - \bar{r}\right)^2}}$$

Where:
- $\sigma_{RV}$ = **Realized Volatility** (annualized)
- $P_i$ = closing price on day $i$
- $n$ = number of days in sample period
- $\bar{r}$ = mean of daily log returns
- $252$ = trading days per year

---

## Practical Example

**Given**: 5 days of closing prices: $100, 102, 101, 103, 102$

**Step 1**: Calculate daily returns
- $r_1 = \ln(102/100) = 0.0198$
- $r_2 = \ln(101/102) = -0.0099$
- $r_3 = \ln(103/101) = 0.0196$
- $r_4 = \ln(102/103) = -0.0098$

**Step 2**: Calculate mean return
$$\bar{r} = \frac{0.0198 - 0.0099 + 0.0196 - 0.0098}{4} = 0.0049$$

**Step 3**: Calculate daily standard deviation
$$\sigma_{\text{daily}} = \sqrt{\frac{(0.0198-0.0049)^2 + (-0.0099-0.0049)^2 + (0.0196-0.0049)^2 + (-0.0098-0.0049)^2}{3}}$$
$$\approx 0.0164 \text{ or } 1.64\%$$

**Step 4**: Annualize
$$\sigma_{RV} = 0.0164 \times \sqrt{252} \approx 0.0164 \times 15.87 \approx 0.26 \text{ or } 26\%$$

**Result**: The realized volatility is approximately **26% annualized**.

---

## Key Properties

1. **Lookback period matters**: Typically use 20-252 days
   - 20 days ≈ 1 month (short-term volatility)
   - 60 days ≈ 3 months (medium-term)