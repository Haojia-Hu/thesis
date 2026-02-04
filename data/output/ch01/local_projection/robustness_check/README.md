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

### 3. Time fixed effects added

**Purpose**

This robustness check adds **time fixed effects** to the baseline LP regressions
to absorb shocks common across categories in a given month.

**Difference from baseline**

- Baseline fixed effects: `| category`
- Robustness fixed effects: `| category + Date`
- Regressor set remains the same (lagged attention, interactions, and macro controls).

**Code**

code/ch01/03_expectation_formation/06_robustness_check/03_add_time_fixed_effects.R


**Outputs**

data/output/ch01/local_projection/robustness_check/time_fixed_effects/


Files include:
- `irf_time_fixed_effects.csv`
- `coef_path_time_fixed_effects.csv`
- `fig_irf_interactions_time_fixed_effects.png`

---

### 4. With news controls

**Purpose**

This robustness check adds a news-volume control to the baseline LP regressions
to test whether the estimated attention–price-signal effects are driven by
changes in information flow.

**Difference from baseline**

- Adds `Diff_News` to the RHS controls
- Fixed effects and core regressors remain the same as baseline.

**Code**

code/ch01/03_expectation_formation/06_robustness_check/04_add_news_controls.R


**Outputs**

data/output/ch01/local_projection/robustness_check/with_news_controls/


Files include:
- `irf_with_news_controls.csv`
- `coef_path_with_news_controls.csv`
- `fig_irf_interactions_with_news_controls.png`

---

### 5. All macro controls lagged

**Purpose**

This robustness check lags all macroeconomic control variables by one period
to ensure controls are predetermined relative to the regression error.

**Difference from baseline**

- Baseline uses contemporaneous macro controls: `D_*`
- Robustness replaces them with lagged controls: `L1_D_*`
  (`L1_D_CpiAgg`, `L1_D_EPU`, `L1_D_ConsumerSent`, `L1_D_Unemployment`,
   `L1_D_RDI`, `L1_D_Mortgage`)
- Core regressors remain unchanged (lagged attention and interactions).

**Code**

code/ch01/03_expectation_formation/06_robustness_check/05_lag_all_macro_controls.R


**Outputs**

data/output/ch01/local_projection/robustness_check/lag_all_macro_controls/


Files include:
- `irf_lag_all_macro_controls.csv`
- `coef_path_lag_all_macro_controls.csv`
- `fig_irf_interactions_lag_all_macro_controls.png`

---

### 6. Exclude selected categories (After Cleaning)

**Purpose**

This robustness check tests whether the baseline LP results are driven by a few
specific categories by excluding selected categories from the sample.

**Difference from baseline**

- Baseline uses all 11 categories.
- This robustness excludes: transportation, energy, communication.
- LP specification is otherwise identical to the baseline.

**Code**

code/ch01/03_expectation_formation/04_build_panel_data_filtered.R
code/ch01/03_expectation_formation/06_robustness_check/06_exclude_selected_categories.R


**Inputs**

- `data/transformed/ch01/panel/panel_data_filtered_excl_transport_energy_comm.csv`

**Outputs**

data/output/ch01/local_projection/robustness_check/exclude_selected_categories/


Files include:
- 'irf_after_cleaning.csv'
- 'coef_path_after_cleaning.csv'
- 'fig_irf_interactions_after_cleaning.png'

---

## Notes

- Each robustness check has its **own subfolder** containing regression outputs
  and figures.
- When a robustness check requires a **different panel construction**, this
  will be explicitly documented here.
- Additional robustness checks will be appended as new sections in this file.
