# Chapter 1 – Expectation Formation (Local Projection Analysis)

This folder contains all scripts used to construct control variables, build
analysis-ready panel datasets, and estimate Local Projection (LP) models for
Chapter 1.

The workflow proceeds from raw data ingestion, to panel construction, to
baseline LP estimation, followed by robustness checks and heterogeneity analyses.

---

## 1. Data ingestion and transformation

These scripts ingest raw macroeconomic, news, and CPI data and convert them into
analysis-ready control variables stored under `data/transformed/ch01/`.

### Scripts

- `01_ingest_macro_raw.R`  
  Ingests raw macroeconomic series downloaded from FRED and constructs
  standardized monthly macro controls.

- `02_ingest_factiva_raw.R`  
  Processes raw Factiva news-count exports and converts them into monthly
  category-level news volume measures.

- `03_ingest_cpi_category.R`  
  Processes category-level CPI data downloaded from the BLS and constructs
  monthly CPI indices for each consumption category.

---

## 2. Panel construction

These scripts merge attention measures, price signals, news variables, and
macroeconomic controls into category-level panel datasets.

### Scripts

- `04_build_panel_data.R`  
  Constructs the baseline panel dataset used in the main LP analysis.

  **Output:**  
  - `data/transformed/ch01/panel/panel_data.csv`

- `07_build_panel_data_filtered.R`  
  Constructs a filtered version of the panel dataset by excluding selected
  consumption categories, used for robustness checks.

  **Output:**  
  - `data/transformed/ch01/panel/panel_data_filtered.csv`

---

## 3. Baseline Local Projection analysis

- `05_local_projection_baseline.R`  
  Estimates the baseline Local Projection model of inflation expectations on
  price signals, attention, and their interactions.

  **Inputs:**  
  - `data/transformed/ch01/panel/panel_data.csv`

  **Outputs:**  
  - `data/output/ch01/local_projection/baseline/`

---

## 4. Robustness checks

Robustness checks modify specific modeling assumptions relative to the baseline
LP specification. All robustness checks use the same panel data unless otherwise
noted.

Robustness scripts are stored under:

06_robustness_check/


### Included robustness checks

- `01_no_lag_attention.R`  
  Uses contemporaneous attention instead of lagged attention.

- `02_remove_macro_keep_cpi.R`  
  Removes macroeconomic controls while retaining aggregate CPI.

- `03_add_time_fixed_effects.R`  
  Adds time fixed effects to the LP specification.

- `04_add_news_controls.R`  
  Adds news volume controls to the LP regressions.

- `05_lag_all_macro_controls.R`  
  Uses lagged macroeconomic control variables.

- `06_after_cleaning.R`  
  Re-estimates LPs using a filtered panel that excludes selected categories.

- `07_placebo_randomized_attention.R`  
  Conducts a placebo test by randomizing lagged attention within categories.

Outputs for each robustness check are stored under:

data/output/ch01/local_projection/robustness_check/


---

## 5. Heterogeneity analysis

- `08_lp_hetero_by_fft_cluster.R`  
  Estimates LP models separately for category groups defined by rolling FFT
  clustering of attention dynamics.

  **Inputs:**  
  - `data/transformed/ch01/panel/panel_data.csv`
  - `data/transformed/ch01/attention_cycle/rolling_fft_cluster_results.csv`

  **Outputs:**  
  - `data/output/ch01/local_projection/heterogeneity/`

---

## 6. Recommended execution order

1. Run data ingestion scripts (`01_`–`03_`)
2. Build the baseline panel (`04_build_panel_data.R`)
3. Estimate the baseline LP (`05_local_projection_baseline.R`)
4. Run robustness checks (`06_robustness_check/`)
5. Run heterogeneity analysis (`08_lp_hetero_by_fft_cluster.R`)
