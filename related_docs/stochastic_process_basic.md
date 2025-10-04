# Stochastic Process Basics for Brownian Motion

## 1. Foundation: Random Variables in Continuous Time

A **stochastic process** is a collection of random variables indexed by time: $\{X(t) : t \in T\}$. Think of it as a random function of time, where at each moment $t$, $X(t)$ is a random variable.

For discrete processes you know well (like random walks), we have $X_0, X_1, X_2, \ldots$ In continuous time, we have $X(t)$ for all $t \in [0, \infty)$.

## 2. Brownian Motion (Wiener Process)

**Definition:** A process $B(t)$ is Brownian motion if:
1. $B(0) = 0$
2. Independent increments: $B(t_2) - B(t_1)$ is independent of $B(t_4) - B(t_3)$ for non-overlapping intervals
3. Stationary increments: $B(t+s) - B(t) \sim \mathcal{N}(0, s)$ for all $t, s > 0$
4. Continuous paths (but nowhere differentiable!)

**Key insight:** Brownian motion is the continuous-time limit of a random walk with step size → 0 and step frequency → ∞.

## 3. The Problem with Traditional Calculus

In normal calculus, we'd write:

$$\frac{dX}{dt} = f(X, t) \implies dX = f(X, t)dt$$

But Brownian motion $B(t)$ is **nowhere differentiable**, so $dB/dt$ doesn't exist in the classical sense. We need a new framework.

## 3.5. Why BM is Not Differentiable But We Can Still Use dB

### The Non-Differentiability Proof (Intuition)

**Why BM isn't differentiable:** Consider the derivative definition:

$$B'(t) = \lim_{h \to 0} \frac{B(t+h) - B(t)}{h}$$

For this limit to exist, we need $(B(t+h) - B(t))/h$ to converge as $h \to 0$. But:
- $B(t+h) - B(t) \sim \mathcal{N}(0, h)$ for any $h > 0$
- So $\frac{B(t+h) - B(t)}{h} \sim \mathcal{N}\left(0, \frac{h}{h^2}\right) = \mathcal{N}(0, 1/h)$ for any $h > 0$
  - *Note: If $Z \sim \mathcal{N}(0, \sigma^2)$, then $Z/c \sim \mathcal{N}(0, \sigma^2/c^2)$*

As $h \to 0$, the variance $1/h \to \infty$. The ratio doesn't converge; it explodes! Almost surely, for any $t$, the derivative $B'(t)$ doesn't exist.

**Geometric intuition:** BM has infinite "wiggling" at every scale. Zoom in on any point, and you see more jagged variation, never smoothing out to a tangent line.

### So Why Can We Write dB?

**Key distinction:** $dB$ is NOT $(dB/dt) \cdot dt$. It's a fundamentally different object.

**Is $dB$ a differential?** Not in the classical sense. In traditional calculus, differentials are related to derivatives: $dy = f'(x)dx$ where $f'$ exists. Here, $dB$ is a **stochastic differential** - a new type of object defined through the integration theory itself, not through differentiation.

**What dB means:**

$dB = dB(t) = B(t+dt) - B(t)$

This is an **infinitesimal random increment**, not a derivative times $dt$. Think of it as:
- **$dB$**: a random variable with distribution $\mathcal{N}(0, dt)$
- **Not decomposable** into $(dB/dt) \cdot dt$ because $dB/dt$ doesn't exist
- Best thought of as a "random infinitesimal" - a fundamental building block, not derived from anything else

### The Mathematical Framework: Stochastic Integration

**Traditional calculus:** Integration is defined via derivatives (Fundamental Theorem of Calculus)

**Stochastic calculus:** Integration is defined *directly* via limits of sums:

$$\int_0^T f(t)dB(t) = \lim_{n \to \infty} \sum_{i} f(t_i)(B(t_{i+1}) - B(t_i))$$

This integral is well-defined even though $B(t)$ has no derivative! We're:
1. Partitioning the interval $[0, T]$
2. Taking increments $\Delta B_i = B(t_{i+1}) - B(t_i)$
3. Summing $f(t_i) \cdot \Delta B_i$
4. Taking limit as partition gets finer

**Key insight:** We never need derivatives. We only need:
- The path $B(t)$ itself (which is continuous)
- The increments $B(t_2) - B(t_1)$ (which are well-defined)

### Differential Notation is Shorthand

When we write:

$$dX = \mu \, dt + \sigma \, dB$$

We really mean the **integral equation**:

$$X(t) - X(0) = \int_0^t \mu(s)ds + \int_0^t \sigma(s)dB(s)$$

The differential form $dX$ is just convenient notation for:

$$X(t+dt) - X(t) \approx \mu(t)dt + \sigma(t)dB(t)$$

**Analogy to discrete math:** 
- In difference equations: $X_{n+1} - X_n = f(X_n)$
- We might write: $\Delta X_n = f(X_n)$
- Similarly: $dX = \mu dt + \sigma dB$ means "infinitesimal increment equals..."

We're not claiming $dX/dt$ exists; we're describing how $X$ increments over infinitesimal time intervals.

### Why This Works

**Regularity requirements:**
1. $B(t)$ is continuous (can take limits)
2. $B(t)$ has bounded variation on finite intervals (integration works)
3. Increments are independent and Gaussian (can compute expectations)

Even without differentiability, these properties suffice to build a rigorous integration theory (Itô, 1944).

**Bottom line:** 
- $dB/dt$ doesn't exist ✗
- $dB$ exists as a random infinitesimal ✓
- $\int f \, dB$ exists as a well-defined limit ✓
- Differential notation $dB$ is shorthand for integration, not differentiation

## 4. Stochastic Differentials: The Intuition

### The Differential Notation

When we write **$dB(t)$** (or $dW(t)$), we mean:

$$dB(t) = B(t + dt) - B(t)$$

This is an **infinitesimal increment** of Brownian motion. Key properties:
- $\mathbb{E}[dB(t)] = 0$ (zero mean)
- $\mathbb{E}[dB(t)^2] = dt$ (variance grows linearly with time)
- $dB(t) \sim \mathcal{N}(0, dt)$

### The Scaling Mystery

Here's the non-intuitive part from regular calculus:

$$dB(t) = O(\sqrt{dt}) \quad \text{NOT } O(dt)$$

This is because variance scales with $dt$, so standard deviation scales with $\sqrt{dt}$.

## 5. Stochastic Differential Equations (SDEs)

A typical SDE looks like:

$dX(t) = \mu(X, t)dt + \sigma(X, t)dB(t)$

**Interpretation:**
- **$\mu(X, t)dt$**: deterministic drift (like traditional calculus)
- **$\sigma(X, t)dB(t)$**: random diffusion (the new part)

### Understanding $\mu$ (Drift): Is it a Rate or Percentage?

**Short answer:** $\mu$ is an **instantaneous rate of change** with units of [value/time].

**Intuitive breakdown:**
- In $dX = \mu \, dt$, we have: $\frac{dX}{dt} = \mu$
- So $\mu$ is literally "how fast $X$ changes per unit time" (deterministically)
- Units: If $X$ is dollars and $t$ is years, then $\mu$ has units dollars/year

**When is $\mu$ a percentage?** In finance, for **geometric Brownian motion**:

$dS = \mu S \, dt + \sigma S \, dB$

Here:
- $\mu$ has units [1/time] - it's a **rate of return** (e.g., 0.05/year = 5% per year)
- The equation says: "stock price changes by $\mu$ percent per unit time (on average)"
- Dividing both sides by $S$: $\frac{dS}{S} = \mu \, dt + \sigma \, dB$ ← log-return!

**Key distinction:**
- **Arithmetic BM:** $dX = \mu \, dt + \sigma \, dB$ → $\mu$ is absolute rate (e.g., +$5/year)
- **Geometric BM:** $dX = \mu X \, dt + \sigma X \, dB$ → $\mu$ is relative rate (e.g., +5%/year)

**Drift coefficient** $\mu$ versus **diffusion coefficient** $\sigma$:
- $\mu$ has units [value/time] (or [1/time] if relative)
- $\sigma$ has units [value/$\sqrt{\text{time}}$] (or [1/$\sqrt{\text{time}}$] if relative)
- Over time $\Delta t$: drift contribution is $O(\Delta t)$, diffusion is $O(\sqrt{\Delta t})$

**Discrete approximation** (for intuition):

$$X(t + \Delta t) - X(t) \approx \mu(X, t)\Delta t + \sigma(X, t)\sqrt{\Delta t} \cdot Z$$

where $Z \sim \mathcal{N}(0, 1)$.

## 6. Itô Calculus: The Non-Standard Rules

### Why Normal Calculus Fails

In regular calculus: $(dt)^2 = 0$ (negligible)

In stochastic calculus:

$$(dB)^2 = dt \quad \text{(NOT negligible!)}$$
$$dB \cdot dt = 0$$
$$(dt)^2 = 0$$

This is because $dB = O(\sqrt{dt})$, so $(dB)^2 = O(dt)$.

### Itô's Lemma (Chain Rule for SDEs)

If $X$ satisfies: $dX = \mu dt + \sigma dB$

And $Y = f(X, t)$, then:

$$dY = \left(\frac{\partial f}{\partial t} + \mu \frac{\partial f}{\partial x} + \frac{1}{2}\sigma^2 \frac{\partial^2 f}{\partial x^2}\right)dt + \sigma \frac{\partial f}{\partial x} dB$$

**Notice:** The extra term $\frac{1}{2}\sigma^2 \frac{\partial^2 f}{\partial x^2}$ appears because $(dB)^2 = dt \neq 0$.

**Compare to deterministic calculus:**

$$\frac{dY}{dt} = \frac{\partial f}{\partial t} + \frac{dX}{dt}\frac{\partial f}{\partial x} \quad \text{[no second derivative term]}$$

## 7. Integration: Two Interpretations

For the integral $\int \sigma(X)dB$, there are two conventions:

**Itô integral** (most common):
- $\sigma$ evaluated at the left endpoint of each interval
- Results in a martingale ($\mathbb{E}[X(t) | X(s)] = X(s)$)
- Non-anticipating (causal)

**Stratonovich integral**:
- $\sigma$ evaluated at the midpoint
- Obeys ordinary chain rule
- Written as $\int \sigma(X) \circ dB$

For computer science applications (simulations, filtering), Itô is standard.

## 8. Computational Perspective

**Simulating** $dX = \mu dt + \sigma dB$ from time $t$ to $t + \Delta t$:
```python
X_new = X_old + mu * Delta_t + sigma * sqrt(Delta_t) * randn()
```

This is the **Euler-Maruyama method**, the stochastic analog of Euler's method.

## 9. Key Takeaways

1. **$dB$ is not a traditional differential** – it's an infinitesimal random variable
2. **$(dB)^2 = dt$** – second-order terms matter in stochastic calculus
3. **Brownian motion has $\sqrt{t}$ scaling** – this fundamentally changes calculus rules
4. **SDEs encode two types of dynamics**: deterministic drift + random diffusion
5. **Itô's lemma adds a correction term** involving the second derivative due to $(dB)^2$

## 10. Connection to Your Background

- **Discrete math:** Think of Brownian motion as the limit of a random walk where step size → 0 at rate $\sqrt{\Delta t}$
- **Optimization:** SDEs appear in stochastic gradient descent (Langevin dynamics), simulated annealing, and policy gradient methods
- **CS applications:** Kalman filtering, options pricing, reinforcement learning, generative models (diffusion models!)