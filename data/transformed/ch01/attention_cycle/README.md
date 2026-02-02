# Transformed Data: Attention Cycles

This directory contains analysis-level data products used to study cyclical
dynamics and short-term predictability in category-level household attention
for Chapter 1.

All files in this directory are generated from first-differenced attention
indices and are reproducible using the scripts in
`code/ch01/02_attention_cycles/`.

---

## Contents

### 1. AR-Based Cycle Detection

- **File**:
  - `ar_cycle_summary.csv`

This file reports results from univariate AR models estimated on
first-differenced attention indices. For each consumption category, it
contains the AR lag order selected by the Bayesian Information Criterion (BIC),
an indicator for the presence of cyclical dynamics, and the implied cycle
period (in months) derived from AR characteristic roots.

These results are used to construct Table 2 (AR-based evidence) in the paper.

---

### 2. AR Forecasts

- **Files**:
  - `forecasts/*_ar_forecast.csv`

These files contain 12-month-ahead forecasts generated from univariate AR
models estimated on first-differenced attention indices. Forecasts are used
to assess short-term predictability in household attention dynamics.

Each forecast file includes point forecasts and corresponding confidence
intervals and is generated using AR lag orders selected by BIC.

---

### 3. Frequency-Domain and Rolling FFT Results

- **Files**:
  - `fft_cycle_summary.csv`
  - `rolling_fft_summary.csv`
  - `rolling_fft_cluster_results.csv`

These files summarize frequency-domain evidence on attention cycles,
including dominant cycle periods, time variation in cycle length, and
heterogeneity across consumption categories. They support the analysis of
attention cycle stability and clustering.
