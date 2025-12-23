# STRUCTURAL VAR MODEL PIPELINE: Oil–Gold–Bitcoin Interactions

# ======================================================================
# STAGE 1: PRELIMINARY ANALYSIS & DATA STRUCTURING
# ======================================================================

# Load Required Libraries
library(xts); library(zoo); library(quantmod); library(tseries)
library(haven); library(pastecs); library(urca); library(vars)
library(mFilter); library(TSstudio); library(forecast); library(tidyverse)

# Load and Prepare Data
data <- read_dta("/Users/thieu/Desktop/Allmonthly-stock.dta")
View(data)

# Inspect and Handle Missing Values
colSums(is.na(data))  # Check missing

# Remove NA values
data_clean <- na.omit(data)
colSums(is.na(data_clean))  # Confirm cleaned

# Define Time Series Objects (Level and First Difference)
WTI  <- ts(data_clean$WTI,  start = c(2010, 7), frequency = 12)
AUX  <- ts(data_clean$AUX,  start = c(2010, 7), frequency = 12)
BTC  <- ts(data_clean$BTC,  start = c(2010, 7), frequency = 12)
dWTI <- ts(data_clean$dWTI, start = c(2010, 7), frequency = 12)
dAUX <- ts(data_clean$dAUX, start = c(2010, 7), frequency = 12)
dBTC <- ts(data_clean$dBTC, start = c(2010, 7), frequency = 12)

# Plot Time Series
ts_plot(WTI, title = "WTI", Xtitle = "Time", Ytitle = "WTI")
ts_plot(AUX, title = "AUX", Xtitle = "Time", Ytitle = "AUX")
ts_plot(BTC, title = "BTC", Xtitle = "Time", Ytitle = "BTC")


# ======================================================================
# STAGE 2: UNIVARIATE DIAGNOSTICS AND MODELING
# ======================================================================

# Descriptive Summary Statistics
stat.desc(data[, c("WTI", "AUX", "BTC")], norm = TRUE)

# ARMA Model Selection & Residual Extraction
arma11_i   <- arima(data_clean$WTI, order = c(1, 0, 1))
arma11_ii  <- arima(data_clean$AUX, order = c(1, 0, 1))
arma11_iii <- arima(data_clean$BTC, order = c(1, 0, 1))

# Store Residuals
resid_i   <- residuals(arma11_i)
resid_ii  <- residuals(arma11_ii)
resid_iii <- residuals(arma11_iii)

# ARCH Test on Residuals
library(FinTS)
ArchTest(resid_i, lags = 5)
ArchTest(resid_ii, lags = 5)
ArchTest(resid_iii, lags = 5)


# ======================================================================
# STAGE 3: STATIONARITY TESTING (LEVEL VS DIFFERENCED SERIES)
# ======================================================================

# Phillips–Perron Test
pp.test(data_clean$WTI);  pp.test(data_clean$dWTI)
pp.test(data_clean$AUX);  pp.test(data_clean$dAUX)
pp.test(data_clean$BTC);  pp.test(data_clean$dBTC)

# Augmented Dickey–Fuller Test
adf.test(data_clean$WTI);  adf.test(data_clean$dWTI)
adf.test(data_clean$AUX);  adf.test(data_clean$dAUX)
adf.test(data_clean$BTC);  adf.test(data_clean$dBTC)

# KPSS Test
kpss.test(data_clean$WTI);  kpss.test(data_clean$dWTI)
kpss.test(data_clean$AUX);  kpss.test(data_clean$dAUX)
kpss.test(data_clean$BTC);  kpss.test(data_clean$dBTC)


# ======================================================================
# STAGE 4: VAR ESTIMATION (I(1) SERIES)
# ======================================================================

# Combine Differenced Variables
dtrivariate <- cbind(data_clean$dWTI, data_clean$dAUX, data_clean$dBTC)
colnames(dtrivariate) <- c("dWTI", "dAUX", "dBTC")

# Lag Selection for VAR
dlag_selection_level <- VARselect(dtrivariate, lag.max = 10, type = "const")
print(dlag_selection_level$selection)

# Estimate VAR(1)
dvar_model <- VAR(dtrivariate, p = 1, type = "const")
summary(dvar_model)

# Diagnostics: Serial Correlation and ARCH effects
dserial_test <- serial.test(dvar_model, lags.pt = 10, type = "PT.asymptotic")
print(dserial_test)

# Check for GARCH effects
darch_test <- arch.test(dvar_model, lags.multi = 15, multivariate.only = TRUE)
print(darch_test)


# ======================================================================
# STAGE 5: STRUCTURAL VAR ESTIMATION (SVAR)
# ======================================================================

# Recursive Structure Imposed
amat <- diag(3)
amat[2,1] <- NA  # AUX ← WTI
amat[3,1] <- NA  # BTC ← WTI
amat[3,2] <- NA  # BTC ← AUX

# Estimate SVAR (recursive identification)
dtrivariateSvar <- SVAR(dvar_model, Amat = amat, Bmat = NULL, hessian = TRUE)
summary(dtrivariateSvar)

# Impulse Response Functions (IRFs)
dirf_dWTI_svar <- irf(dtrivariateSvar, impulse = "dWTI", response = c("dAUX", "dBTC"), n.ahead = 20, boot = TRUE)
plot(dirf_dWTI_svar, ylab = "Response", main = "Shock from dWTI to dAUX and dBTC")

dirf_dAUX_svar <- irf(dtrivariateSvar, impulse = "dAUX", response = c("dWTI", "dBTC"), n.ahead = 20, boot = TRUE)
plot(dirf_dAUX_svar, ylab = "Response", main = "Shock from dAUX to dWTI and dBTC")

dirf_dBTC_svar <- irf(dtrivariateSvar, impulse = "dBTC", response = c("dWTI", "dAUX"), n.ahead = 20, boot = TRUE)
plot(dirf_dBTC_svar, ylab = "Response", main = "Shock from dBTC to dWTI and dAUX")

# Optional Single-Pair IRFs
dSVARi   <- irf(dtrivariateSvar, impulse = "dAUX", response = "dBTC"); plot(dSVARi)
dSVARii  <- irf(dtrivariateSvar, impulse = "dWTI", response = "dBTC"); plot(dSVARii)
dSVARiii <- irf(dtrivariateSvar, impulse = "dWTI", response = "dAUX"); plot(dSVARiii)

# Variance Decomposition (FEVD)
dfevd_svar <- fevd(dtrivariateSvar, n.ahead = 10)
plot(dfevd_svar)

# ======================================================================
# END OF SCRIPT
# ======================================================================