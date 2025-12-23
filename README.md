# A STRUCTURAL VAR MODEL with IRFs & FEVD FOR MODELING INTERDEPENDENCIES AMONG FINANCIAL ASSETS 
🛠️ **Tech Stack**: R (vars, urca, tseries, forecast, FinTS)
---
## (i). Overview

This project investigates the **dynamic interdependencies** between global asset prices—**crude oil (WTI)**, **gold (XAU/USD)**, and **Bitcoin (BTC/USD)**—through the lens of a **trivariate Structural Vector Autoregression (SVAR)** model. The objective is to capture both **short-run causal dynamics** and **contemporaneous structural shocks**, shedding light on the interaction of traditional and digital asset markets.

The methodology follows the **SVAR framework** developed by **Sims (1980)**, applying recursive identification to estimate **impulse response functions (IRFs)** and **forecast error variance decompositions (FEVD)**.

---

## (ii). Methodology

### 🔍 Pre-Estimation Diagnostics
- **Descriptive Statistics** and **Normality Tests**  
  - Confirmed non-normality via skewness, kurtosis, and Shapiro-Wilk tests.
  - BTC shows highest volatility (SD = 3.41), WTI is negatively skewed.

- **Stationarity Tests**:
  - Employed **ADF**, **PP**, and **KPSS** tests.
  - All series found to be **non-stationary at level**, stationary at **first difference I(1)**.

- **ARCH Effects**:
  - **WTI** exhibits significant ARCH effect → justifies volatility clustering.
  - **XAU** and **BTC** residuals → no heteroskedasticity.

### 📈 VAR Diagnostics
- Optimal lag selected: **VAR(1)** via AIC, SC, HQ, and FPE.
- VAR residual diagnostics show:
  - No serial correlation (Portmanteau Test: p = 0.9)
  - No multivariate heteroskedasticity (ARCH Test: p = 1.0)

---

## (iii). Modeling Pipeline

```text
Stage 1: Data Cleaning and Transformation (R)
→ Step 2: Descriptive Statistics & Normality
→ Step 3: Stationarity Testing: ADF, PP, KPSS
→ Step 4: ARMA(1,1) residual diagnostics + ARCH test
→ Step 5: VAR(1) Estimation + Residual Checks
→ Step 6: Recursive Structural VAR (SVAR) Estimation
→ Step 7: Impulse Response Functions (IRFs)
→ Step 8: Forecast Error Variance Decomposition (FEVD)
```

### 🔧 SVAR Identification

- Recursive A-matrix imposed:
  ```text
  dWTI → dAUX → dBTC
  ```

- Estimated using **`SVAR()`** function from the **`vars`** package.
- Overidentification test: χ²(3) = 934, p < 2e−16 → Valid restrictions.

---

## (iv). Key Findings

- **dAUX (gold)** and **dBTC (Bitcoin)** respond significantly to **dWTI (oil)** shocks:
  - BTC shows a **negative response**; gold is inert to oil shocks.
- **Gold shocks** → strong **positive response from oil**, **negative from BTC**
- **BTC shocks**:
  - Trigger **significant short-run effects** on both oil and gold.
  - WTI exhibits a sharp upward reaction; XAU declines moderately.

- FEVD shows BTC contributes increasingly to WTI and AUX forecast errors over time.

---

## (v). Application: Risk & Portfolio Implications

- **Bitcoin transmits structural shocks**, influencing traditional markets in the short term.
- **Gold remains a defensive asset**—more resistant to crypto shocks.
- **Oil’s centrality** in the system underscores its macroeconomic importance.
- Implications:
  - Use gold to hedge against crypto–commodity volatility spillovers.
  - Monitor BTC as an emerging systemic asset in high-volatility regimes.

---

## (vi). Repository Contents

- `R Script.R`: Full R workflow (data cleaning → SVAR estimation → IRFs)
- `Dataset.dta`: Monthly returns data for WTI, XAU, BTC
- `Methods and Results.pdf`: Methodological writeup and output tables
- `README.md`: Project documentation


