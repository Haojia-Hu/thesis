# Transformed Data: Attention Cycles

This directory contains analysis-level data products used to study cyclical
dynamics and short-term predictability in category-level household attention
for Chapter 1.

All files in this directory are generated from first-differenced attention
indices and are fully reproducible using the scripts in
`code/ch01/02_attention_cycles/`.

---

## Overview

The data products in this directory support three complementary empirical
analyses of household attention dynamics:

1. Time-domain evidence based on autoregressive (AR) models  
2. Frequency-domain evidence based on Fast Fourier Transform (FFT)  
3. Time-varying and heterogeneous cycle dynamics based on rolling FFT and
   clustering

Together, these outputs provide the empirical foundation for Sections 5.1–5.3
of the paper.

---

## Contents

### 1. AR-Based Cycle Detection (Time Domain)

**File:**
- `ar_cycle_summary.csv`

This file reports results from univariate autoregressive models estimated on
first-differenced attention indices. For each consumption category, it includes:

- the AR lag order selected by the Bayesian Information Criterion (BIC),
- an indicator for the presence of cyclical dynamics (based on characteristic
  roots),
- the implied cycle period (in months),
- and the modulus of the dominant complex root.

These results provide time-domain evidence of cyclical attention dynamics and
are used to construct the AR-based columns of Table 2.

---

### 2. AR Forecasts (Short-Term Predictability)

**Files:**
- `forecasts/*_ar_forecast.csv`

These files contain 12-month-ahead forecasts generated from univariate AR
models estimated on first-differenced attention indices. Forecasts are used
to assess short-term predictability in household attention dynamics rather
than to build a forecasting system.

Each forecast file includes:
- point forecasts,
- and corresponding confidence intervals.

AR lag orders used in forecasting are selected by BIC and are consistent with
the AR-based cycle detection results.

---

### 3. Frequency-Domain Cycle Evidence (FFT)

**File:**
- `fft_cycle_summary.csv`

This file summarizes frequency-domain evidence on attention cycles obtained
using the Fast Fourier Transform (FFT). For each category, it reports the
dominant cycle period and the next two most prominent periodic components.

These results provide complementary evidence to AR-based methods and are used
to construct the FFT-based columns of Table 2.

---

### 4. Time-Varying Cycles and Heterogeneity (Rolling FFT)

**Files:**
- `rolling_fft_results.csv`
- `rolling_fft_cluster_results.csv`

The file `rolling_fft_results.csv` contains rolling-window FFT estimates of
dominant cycle periods for each category, capturing how attention cycles evolve
over time.

The file `rolling_fft_cluster_results.csv` summarizes rolling FFT dynamics at
the category level. It reports:
- the average cycle length,
- the volatility (standard deviation) of cycle length,
- the time trend in cycle length,
- and cluster assignments based on these features.

These outputs support the analysis of heterogeneity in attention cycles across
consumption categories and are used to construct Figure 4.

### 5. Rolling FFT clustering results

- Based on `rolling_fft_cluster_results.csv`

Category-level cluster assignments derived from rolling FFT features of the differenced attention series. This file is used to define heterogeneity groups in the **local projection** analysis.

Used by:
- `code/ch01/03_expectation_formation/08_heterogeneity/08_lp_hetero_by_fft_cluster.R`

---

## Notes

- All files in this directory are analysis-level transformed data and are not
  tracked in the repository.
- Figures generated from these data are stored separately under
  `data/output/ch01/figures/`.
- Detailed descriptions of estimation procedures are provided in the scripts
  under `code/ch01/02_attention_cycles/`.
