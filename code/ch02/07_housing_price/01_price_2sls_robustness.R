# ==============================================================================
# Chapter 2 — Housing Price (2SLS) + Robustness Checks
#
# Purpose
# -------
# Estimate 2SLS models of CBSA-level monthly house price growth on the local
# mortgage rate gap (RateGap). The endogenous regressor is `rate_gap`, instrumented
# by `Z_bartik`. All specifications include CBSA fixed effects and month fixed
# effects, with standard errors clustered at the CBSA level.
#
# This script implements:
#   1) Baseline 2SLS
#   2) Baseline + lagged dependent variable (semi-dynamic)
#   3) Trimmed sample (5–95 pct) of rate_gap *within CBSA* (as in your code)
#   4) High-gap vs Low-gap subsamples (split at median of rate_gap)
#   5) COVID vs Hike-period subsamples (as in your code cutoffs)
#
# Inputs (from thesis/data/transformed/ch02)
# -----------------------------------------
# 1) Zillow ZHVI (CBSA-month)
#   data/transformed/ch02/zillow/zillow_zhvi.csv
#   Required columns: cbsa_code, yearmon, proxy_value
#
# 2) Core panel with RateGap, IV, and controls
#   data/transformed/ch02/housing_quant/panel_rategap_hat.csv
#   Required columns: cbsa_code, ym, rate_gap, Z_bartik, unemployment_rate,
#                     mig_rate_month, bps_total
#
# 3) Zillow New Listings (CBSA-month)
#   data/transformed/ch02/zillow/zillow_newlisting.csv
#   Required columns: cbsa_code, yearmon, proxy_value
#
# Outputs (to thesis/data/output/ch02/housing_price)
# -------------------------------------------------
# 1) housing_price_2sls_baseline_and_robustness.csv
#   Tidy summary table for all models
#
# 2) housing_price_2sls_models.rds (optional)
#   Saved fixest model objects for reproducibility
#
# Notes
# -----
# - Month FE uses `ym` (YYYY-MM) to align with "Month FE = Yes" in the paper table.
# - The "Trimmed" definition here follows your code: CBSA-within 5–95 pct trimming.
# - Period split follows your code:
#     COVID: 2018-08 to 2022-03
#     Hike:  2022-03 onward
# ==============================================================================

# ==== Packages ====
suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(stringr)
  library(fixest)
  library(broom)
})

# ==== Paths (repo-relative; run from thesis/ root) ====
path_price   <- "data/transformed/ch02/zillow/zillow_zhvi.csv"
path_panel   <- "data/transformed/ch02/housing_quant/panel_rategap_hat.csv"
path_newlist <- "data/transformed/ch02/zillow/zillow_newlisting.csv"

out_dir <- "data/output/ch02/housing_price"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_csv <- file.path(out_dir, "housing_price_2sls_baseline_and_robustness.csv")
out_rds <- file.path(out_dir, "housing_price_2sls_models.rds")

# ==== 1) Read New Listings (lock-in proxy; logged) ====
newl <- fread(path_newlist) %>%
  transmute(
    cbsa_code     = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym            = substr(as.character(yearmon), 1, 7),
    proxy_newlist = as.numeric(proxy_value)
  ) %>%
  distinct(cbsa_code, ym, .keep_all = TRUE) %>%
  group_by(cbsa_code) %>%
  mutate(proxy_newlist = log(pmax(proxy_newlist, 1))) %>%
  ungroup()

# ==== 2) Read core panel (RateGap + IV + controls) ====
panel_core <- fread(path_panel) %>%
  mutate(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym        = as.character(ym)
  )

# Basic sanity checks (fail fast)
need_cols_core <- c("cbsa_code","ym","rate_gap","Z_bartik",
                    "unemployment_rate","mig_rate_month","bps_total")
missing_core <- setdiff(need_cols_core, names(panel_core))
if (length(missing_core) > 0) {
  stop("panel_rategap_hat.csv is missing columns: ", paste(missing_core, collapse = ", "))
}

# ==== 3) Read ZHVI price & build price growth ====
price_raw <- fread(path_price)
need_cols_price <- c("cbsa_code","yearmon","proxy_value")
missing_price <- setdiff(need_cols_price, names(price_raw))
if (length(missing_price) > 0) {
  stop("zillow_zhvi.csv is missing columns: ", paste(missing_price, collapse = ", "))
}

price <- price_raw %>%
  transmute(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym        = substr(as.character(yearmon), 1, 7),
    price     = as.numeric(proxy_value)
  ) %>%
  arrange(cbsa_code, ym) %>%
  group_by(cbsa_code) %>%
  mutate(price_chg = 100 * (log(price) - log(dplyr::lag(price)))) %>%
  ungroup() %>%
  select(cbsa_code, ym, price_chg)

# ==== 4) Merge analysis dataset ====
panel <- panel_core %>%
  left_join(newl,  by = c("cbsa_code","ym")) %>%
  left_join(price, by = c("cbsa_code","ym")) %>%
  filter(
    !is.na(rate_gap),
    !is.na(Z_bartik),
    !is.na(proxy_newlist),
    !is.na(price_chg),
    !is.na(unemployment_rate),
    !is.na(mig_rate_month),
    !is.na(bps_total)
  ) %>%
  mutate(
    cbsa_code = factor(cbsa_code),
    ym        = factor(ym)
  )

# Quick coverage summary
cat("\n=== Housing price 2SLS sample coverage ===\n")
cat("Obs:", nrow(panel), "\n")
cat("CBSAs:", n_distinct(panel$cbsa_code), "\n")
cat("Months:", n_distinct(panel$ym), "\n\n")

# ==== Helper: run a standard 2SLS spec ====
run_2sls <- function(df, add_lag_y = FALSE){
  if (add_lag_y) {
    # semi-dynamic: add lagged dependent variable
    df2 <- df %>%
      group_by(cbsa_code) %>%
      arrange(ym) %>%
      mutate(price_chg_lag = dplyr::lag(as.numeric(price_chg))) %>%
      ungroup() %>%
      filter(!is.na(price_chg_lag))

    m <- feols(
      price_chg ~ price_chg_lag + unemployment_rate + mig_rate_month + bps_total |
        cbsa_code + ym |
        rate_gap ~ Z_bartik,
      cluster = ~ cbsa_code,
      data = df2
    )
    return(list(model = m, data = df2))
  } else {
    m <- feols(
      price_chg ~ unemployment_rate + mig_rate_month + bps_total |
        cbsa_code + ym |
        rate_gap ~ Z_bartik,
      cluster = ~ cbsa_code,
      data = df
    )
    return(list(model = m, data = df))
  }
}

# ==== 5) Baseline 2SLS ====
res_baseline <- run_2sls(panel, add_lag_y = FALSE)
m_baseline <- res_baseline$model

# ==== 6) Robustness (1): add lagged dependent variable ====
res_lag <- run_2sls(panel, add_lag_y = TRUE)
m_lag <- res_lag$model

# ==== 7) Robustness (2): remove extremes by CBSA (rate_gap 5–95 pct within CBSA) ====
panel_trim_cbsa <- panel %>%
  group_by(cbsa_code) %>%
  filter(
    rate_gap > quantile(rate_gap, 0.05, na.rm = TRUE) &
      rate_gap < quantile(rate_gap, 0.95, na.rm = TRUE)
  ) %>%
  ungroup()

m_trim_cbsa <- run_2sls(panel_trim_cbsa, add_lag_y = FALSE)$model

# ==== 8) Robustness (3): High vs Low rate_gap regions (median split) ====
med_gap <- median(as.numeric(panel$rate_gap), na.rm = TRUE)

panel_high <- panel %>% filter(as.numeric(rate_gap) >  med_gap)
panel_low  <- panel %>% filter(as.numeric(rate_gap) <= med_gap)

m_high <- run_2sls(panel_high, add_lag_y = FALSE)$model
m_low  <- run_2sls(panel_low,  add_lag_y = FALSE)$model

# ==== 9) Robustness (4): COVID vs Hike period (as implemented in your code) ====
panel_covid <- panel %>% filter(as.character(ym) >= "2018-08" & as.character(ym) <= "2022-03")
panel_hike  <- panel %>% filter(as.character(ym) >= "2022-03")

m_covid <- run_2sls(panel_covid, add_lag_y = FALSE)$model
m_hike  <- run_2sls(panel_hike,  add_lag_y = FALSE)$model

# ==== 10) Collect results into one tidy output table ====
# We focus on the coefficient on `rate_gap`, plus key summary stats.

extract_one <- function(m, model_name){
  td <- broom::tidy(m)
  tg <- td %>% filter(term == "rate_gap") %>% slice(1)

  # First-stage F-stat (fixest stores some IV diagnostics; if unavailable, return NA)
  # Using tryCatch to be robust across fixest versions.
  ivf <- tryCatch({
    as.numeric(fitstat(m, "ivf")[[1]])
  }, error = function(e) NA_real_)

  tibble(
    model = model_name,
    term  = "rate_gap",
    estimate = tg$estimate,
    std_error = tg$std.error,
    statistic = tg$statistic,
    p_value   = tg$p.value,
    nobs      = nobs(m),
    n_cbsa    = n_distinct(m$model$cbsa_code),
    n_month   = n_distinct(m$model$ym),
    first_stage_F = ivf
  )
}

results_tbl <- bind_rows(
  extract_one(m_baseline, "Baseline 2SLS"),
  extract_one(m_lag,      "Baseline + lag(price_chg)"),
  extract_one(m_trim_cbsa,"Trimmed (CBSA 5–95 pct of rate_gap)"),
  extract_one(m_high,     "High Gap (above median)"),
  extract_one(m_low,      "Low Gap (below median)"),
  extract_one(m_covid,    "COVID period (2018-08 to 2022-03)"),
  extract_one(m_hike,     "Hike period (>= 2022-03)")
)

# Write outputs
write.csv(results_tbl, out_csv, row.names = FALSE)

# Save model objects (optional but useful)
models_list <- list(
  baseline = m_baseline,
  lag_y    = m_lag,
  trim_cbsa= m_trim_cbsa,
  high_gap = m_high,
  low_gap  = m_low,
  covid    = m_covid,
  hike     = m_hike
)
saveRDS(models_list, out_rds)

cat("\nSaved outputs:\n")
cat("- ", out_csv, "\n")
cat("- ", out_rds, "\n\n")

# Optional: print a quick etable to console
etable(m_baseline, m_trim_cbsa, m_high, m_low, m_covid, m_hike,
       se.below = TRUE, fitstat = ~ n + ivf, tex = FALSE)
