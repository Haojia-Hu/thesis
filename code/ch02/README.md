Code for Chapter 2.

# Chapter 2 – Mortgage Rate Lock-in and Housing Market

This folder contains all empirical scripts for Chapter 2 of the dissertation:

**Mortgage Rate Lock-in and Housing Market Activity**

All scripts operate on CBSA-by-month panel data and follow the empirical structure of the paper.

---

## Empirical Structure

The workflow corresponds to the identification strategy in the paper:

1. Construct mortgage rate gap
2. Build Bartik (shift-share) instrument
3. Estimate first-stage fitted rate gap
4. Estimate static 2SLS effects
5. Estimate DID exposure design
6. Estimate dynamic Local Projection IV (LP-IV)
7. Analyze heterogeneity (employment and supply elasticity)
8. Estimate effects on house prices

All regressions:

- Include CBSA fixed effects
- Include month fixed effects
- Cluster standard errors at the CBSA level

---

# Folder Structure

---

## 01_hmda

Construct mortgage balance-weighted rates using HMDA LAR data.

- Clean yearly HMDA LAR files
- Combine into CBSA-level panel

Outputs feed into rate gap construction.

---

## 02_rate_gap

Construct mortgage rate gap and Bartik instrument.

Scripts:

- `01_outstanding_rate_monthly.R`
- `02_rate_gap_monthly.R`
- `03_build_shiftshare_iv.R`

Output:
- CBSA-month RateGap panel

---

## 03_control_variables

Build time-varying CBSA controls:

- Migration
- Unemployment (LAUS)
- Building permits

Outputs are merged into the core panel.

---

## 04_iv

Construct shift-share (Bartik) instrument.

- `01_ss_iv_bartik.R`

Produces `Z_bartik` used in all IV regressions.

---

## 05_zillow

Build CBSA-month Zillow outcome variables.

- Construct CBSA crosswalk
- Build monthly housing quantities

Outputs feed into housing activity regressions.

---

## 06_housing_quant

Housing market quantity outcomes.

Implements:

- Static 2SLS lock-in effects
- Difference-in-differences exposure design
- Local Projection IV (LP-IV) dynamic responses

Corresponds to:

- Table 2 (Static IV)
- Table 3 (DID)
- Figure 2 (Dynamic LP-IV)

---

## 07_housing_price

House price analysis module.

Implements:

- Static 2SLS on house price growth
- Robustness checks
- Dynamic LP-IV on price growth
- Heterogeneity:
  - Employment growth
  - Saiz (2010) supply elasticity

Key scripts:

- `01_price_2sls_robustness.R`
- `02_price_lpiv_irf.R`
- `03_build_saiz2010_cbsa.R`
- `04_qcew_cbsa_monthly_emp.R`
- `05_price_lpiv_heterogeneity.R`

Corresponds to:

- Static price IV table
- Dynamic IRF figure
- Heterogeneity IRFs

---

# Data Structure Assumptions

All scripts assume:

- Monthly time format: `ym = YYYY-MM`
- CBSA codes are 5-digit strings
- Transformed datasets already exist in:
thesis/data/transformed/ch02/


Raw data construction occurs in:

thesis/data/raw/ch02/


---

# Reproducibility

To fully reproduce Chapter 2:

1. Build raw datasets (HMDA, Zillow, QCEW, Saiz, etc.)
2. Run rate gap and IV construction
3. Run housing quantity models
4. Run housing price models

Scripts are modular and can be run independently once required inputs exist.
