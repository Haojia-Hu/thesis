# Chapter 2 – Housing Market Quantitative Analysis

This folder contains the core empirical scripts for Chapter 2:
Mortgage Rate Lock-in and Housing Market Activity.

The workflow follows the structure of the paper:

1. Construct first-stage fitted rate gap (IV setup)
2. Estimate static 2SLS effects on housing-market proxies
3. Estimate difference-in-differences (DID) specification
4. Estimate dynamic local projection IV (LP-IV) responses

All scripts assume CBSA-by-month panel data.

---

## 01_first_stage_rategap_hat.R

**Purpose**  
Estimate the first-stage regression of the mortgage rate gap on the Bartik instrument
and control variables, including CBSA and month fixed effects.

**Specification**
RateGap_{m,t} = π0 + π1 Z_{m,t} + π'X_{m,t} + μ_m + τ_t + u_{m,t}

**Inputs**
- `thesis/data/transformed/ch02/rate_gap/Rate_gap_monthly.csv`
- `thesis/data/transformed/ch02/iv/SS_IV.csv`
- Control variables:
  - unemployment
  - migration
  - building permits

**Outputs**
- `thesis/data/transformed/ch02/rate_gap/Panel_rategap_hat.csv`

Contains:
- cbsa_code
- ym
- rate_gap
- Z_bartik
- controls
- rategap_hat (fitted values)

---

## 02_iv_lockin_proxies.R

**Purpose**  
Estimate static 2SLS effects of the mortgage rate gap on housing-market lock-in proxies.

Second-stage specification:
Y_{m,t} = β0 + β1 dRateGap_{m,t} + β'X_{m,t} + μ_m + τ_t + ε_{m,t}

The mortgage rate gap is instrumented using the Bartik instrument.

**Inputs**
- `thesis/data/transformed/ch02/rate_gap/Panel_rategap_hat.csv`
- Zillow CBSA-month outcomes:
  - zillow_invt.csv
  - zillow_newlisting.csv
  - zillow_newlypending.csv
  - zillow_daytopending.csv
  - zillow_sharepricecut.csv

**Outputs**
- `thesis/data/output/ch02/housing_quant/iv_lockin_proxies_2sls_results.csv`

---

## 03_did_lockin_exposure.R

**Purpose**  
Implement a difference-in-differences design comparing high-lock-in vs low-lock-in
CBSAs before and after the 2022 rate shock.

High-lock-in CBSAs are defined using the 2021 baseline outstanding-balance-weighted
mortgage rate (bottom tercile).

Specification:
y_{m,t} = β (HighLockedIn_m × Post_t) + μ_m + τ_t + ε_{m,t}

Post_t = 1 if ym ≥ March 2022.

Two specifications are estimated:
- log outcome
- level outcome

**Inputs**
- `thesis/data/transformed/ch02/rate_gap/MSA_outstanding_weighted_rate_monthly.csv`
- Zillow CBSA-month outcomes (same as above)

**Outputs**
- `thesis/data/output/ch02/housing_quant/did_lockin_exposure_results.csv`

---

## 04_lp_iv_new_listings.R

**Purpose**  
Estimate dynamic local projection IV (LP-IV) impulse responses of new listings
to the mortgage rate gap.

For each horizon h = 1,…,12:
Y_{m,t+h} = β_h dRateGap_{m,t} + μ_m + τ_t + ε_{m,t+h}

The rate gap is instrumented using the Bartik instrument.

**Inputs**
- `thesis/data/transformed/ch02/rate_gap/Panel_rategap_hat.csv`
- `thesis/data/transformed/ch02/zillow/zillow_newlisting.csv`

**Outputs**
- `thesis/data/output/ch02/housing_quant/lp_iv_new_listings_irf.csv`
- `thesis/data/output/ch02/housing_quant/lp_iv_new_listings_irf.png`

---

## Empirical Strategy Structure

The scripts correspond to the following parts of the paper:

- Static IV estimates → Table 2
- DID specification → Table 3
- Dynamic LP-IV → Figure 2

All regressions:
- Include CBSA fixed effects
- Include month fixed effects
- Cluster standard errors at the CBSA level

---

## Notes

- All time variables use monthly format (`YYYY-MM`).
- All CBSA codes are 5-digit strings.
- Scripts assume that transformed datasets are already built.
- Raw data construction occurs in other folders (e.g., zillow/, control_variables/, iv/).
