# Local Projection Robustness Checks

This folder collects **robustness check results** for the Local Projection (LP)
analysis in Chapter 1. Each robustness check modifies a specific modeling
assumption relative to the baseline specification.

All robustness checks use the **same input panel dataset** unless explicitly stated otherwise. Baseline results are stored separately under: data/output/ch01/local_projection/baseline/

---

## Input data (common across robustness checks)

Unless otherwise noted, all robustness checks are based on:

- `data/transformed/ch01/panel/panel_data.csv`

This panel contains monthly category-level observations (2004–2024) with
attention measures, price signals, news variables, and macroeconomic controls.

---

# Robustness checks

### 1. No lag on attention (current attention)

**Purpose**

This robustness check replaces **lagged attention** with
**contemporaneous attention** in the Local Projection regressions.

**Difference from baseline**

- Baseline: uses `L1_diff_index`
- Robustness: uses current `diff_index`
- Interaction terms are redefined as:
  - `diff_index × Diff_PriceChange`
  - `diff_index × Diff_Volatility`
- Standard errors are clustered by `category` and `Date`

**Code**

code/ch01/03_expectation_formation/06_robustness_check/01_no_lag_attention.R


**Outputs**

data/output/ch01/local_projection/robustness_check/no_lag_attention/


Files include:
- `irf_no_lag_attention.csv`
- `coef_path_no_lag_attention.csv`
- `fig_irf_interactions_no_lag_attention.png`

---

### 2. Macro controls removed (aggregate CPI kept)

**Purpose**

This robustness check removes macroeconomic controls from the baseline LP
regressions, while retaining **aggregate CPI** as a minimal common control.

**Difference from baseline**

- Keeps the baseline attention structure (lagged attention and interactions)
- Drops macro controls: `D_EPU`, `D_ConsumerSent`, `D_Unemployment`, `D_RDI`, `D_Mortgage`
- Retains only `D_CpiAgg`
- Standard errors are clustered by `category` and `Date`

**Code**

code/ch01/03_expectation_formation/06_robustness_check/02_remove_macro_keep_cpiagg.R


**Outputs**

data/output/ch01/local_projection/robustness_check/remove_macro_keep_cpiagg/


Files include:
- `irf_remove_macro_keep_cpiagg.csv`
- `coef_path_remove_macro_keep_cpiagg.csv`
- `fig_irf_interactions_remove_macro_keep_cpiagg.png`

---

## Notes

- Each robustness check has its **own subfolder** containing regression outputs
  and figures.
- When a robustness check requires a **different panel construction**, this
  will be explicitly documented here.
- Additional robustness checks will be appended as new sections in this file.
