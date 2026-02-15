# Chapter 2 – Housing Price Analysis (IV & LP-IV)

This folder contains the empirical scripts for the **house price component** of Chapter 2:
Mortgage Rate Lock-in and Housing Market Activity.

All scripts operate on CBSA-by-month panel data and use the Bartik instrument
(`Z_bartik`) to instrument the local mortgage rate gap (`rate_gap`).

All regressions:

- Include CBSA fixed effects
- Include month fixed effects
- Cluster standard errors at the CBSA level
- Use monthly time format (`YYYY-MM`)
- Use 5-digit CBSA codes (string format)

---

## 01_price_2sls_robustness.R

### Purpose

Estimate static 2SLS models of monthly house price growth on the mortgage rate gap.

Specification:

PriceGrowth_{m,t} = β * RateGap_{m,t} + X_{m,t} + μ_m + τ_t + ε_{m,t}

where:

- `price_chg = 100 * Δlog(ZHVI)`
- `rate_gap` is instrumented by `Z_bartik`
- X includes unemployment, migration, and building permits

### Inputs

- `data/transformed/ch02/zillow/zillow_zhvi.csv`
- `data/transformed/ch02/housing_quant/panel_rategap_hat.csv`
- `data/transformed/ch02/zillow/zillow_newlisting.csv`

### Outputs

- `data/output/ch02/housing_price/housing_price_2sls_baseline_and_robustness.csv`
- `data/output/ch02/housing_price/housing_price_2sls_models.rds`

Includes:

- Baseline 2SLS
- Lagged dependent variable specification
- Trimmed sample (5–95 pct)
- High-gap vs Low-gap subsamples
- COVID vs hiking-period subsamples

Corresponds to: **Static IV results (Table – House Prices)**

---

## 02_price_lpiv_irf.R

### Purpose

Estimate dynamic Local Projection IV (LP-IV) impulse responses of house price growth.

For horizons h = 0–12:

PriceGrowth_{m,t+h} = β_h RateGap_{m,t} + X_{m,t} + μ_m + τ_t + ε_{m,t+h}

Non-cumulative (month-by-month) responses.

### Outputs

- `lp_price_irf_non_cum.csv`
- `lp_price_irf_non_cum.png`

Corresponds to: **Dynamic IRF figure – House Prices**

---

## 03_build_saiz2010_cbsa.R

### Purpose

Construct CBSA-level housing supply elasticity from Saiz (2010).

Steps:

- Load original Saiz MSA-level elasticity
- Use Census crosswalk (MSA99 → CBSA03)
- Map each old MSA to a primary CBSA
- Output CBSA-level elasticity

### Output

- `data/transformed/ch02/housing_price/saiz2010_cbsa.csv`

Used for: **Heterogeneity by housing supply elasticity**

---

## 04_qcew_cbsa_monthly_emp.R

### Purpose

Construct CBSA-level monthly total employment from BLS QCEW quarterly files.

Steps:

- Read quarterly QCEW singlefile CSVs
- Filter to total employment (own_code = 0, industry = 10)
- Convert quarterly to monthly
- Map counties to CBSA
- Aggregate to CBSA-month

### Output

- `data/transformed/ch02/housing_price/QCEW_cbsa_totalemp.csv`

Used for: **Heterogeneity by local employment growth**

---

## 05_price_lpiv_heterogeneity.R

### Purpose

Estimate heterogeneous static IV and LP-IV responses of house prices by:

1. Employment growth (high vs low CBSA average growth)
2. Housing supply elasticity (Saiz 2010 median split)

All specifications instrument `rate_gap` with `Z_bartik`.

### Outputs

- `lp_price_irf_hetero_employment.csv`
- `lp_price_irf_hetero_employment.png`
- `lp_price_irf_hetero_elasticity.csv`
- `lp_price_irf_hetero_elasticity.png`

Corresponds to:

- Heterogeneity Figure – Employment
- Heterogeneity Figure – Supply Elasticity

---

## Empirical Structure (House Price Block)

The scripts correspond to the paper structure:

- Static IV → House price baseline effect
- Robustness → Sample splits and trimming
- Dynamic LP-IV → Impulse responses
- Heterogeneity → Labor demand & supply elasticity

All scripts assume transformed datasets are already constructed.

Raw data processing occurs in:

- `data/raw/ch02/price_hetero/`
- `code/ch02/07_housing_price/03_*`
- `code/ch02/07_housing_price/04_*`
