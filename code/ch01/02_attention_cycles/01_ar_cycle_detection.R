# ============================================================
# Purpose:
#   1) Use first-differenced attention indices to estimate
#      univariate AR models for each consumption category.
#   2) Select AR lag length using the Bayesian Information
#      Criterion (BIC).
#   3) Detect cyclical dynamics from AR characteristic roots
#      and compute implied cycle periods.
#
# Input (not tracked):
#   - First-differenced attention indices:
#     data/transformed/ch01/diff/*_diff.csv
#
# Core Output (not tracked):
#   - AR order selected by BIC for each category
#   - Indicator for presence of cyclical dynamics
#   - Implied cycle period (in months)
#
# Notes:
#   - Outputs from this script are used to construct Table 2
#     (AR-based cycle evidence) in Chapter 1.
# ============================================================

library(tidyverse)
library(forecast)

# ---- Paths ----
diff_dir <- file.path("data", "transformed", "ch01", "diff")
out_dir  <- file.path("data", "transformed", "ch01", "attention_cycles")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Read diff attention data ----
file_list <- list.files(diff_dir, pattern = "_diff\\.csv$", full.names = TRUE)
data_diff_list <- lapply(file_list, read_csv, show_col_types = FALSE)
names(data_diff_list) <- gsub("_diff\\.csv$", "", basename(file_list))

# ---- BIC-based AR(p) selection ----
fit_ar_model_bic <- function(df, cat) {
  x <- na.omit(df$diff_index)
  if (length(x) < 10) return(NULL)

  model <- auto.arima(
    x,
    d = 0,
    max.q = 0,
    stationary = TRUE,
    ic = "bic",
    stepwise = FALSE,
    approximation = FALSE
  )

  tibble(
    category = cat,
    ar_order = model$arma[1],
    bic = model$bic
  )
}

ar_bic_summary <- map2_df(
  data_diff_list,
  names(data_diff_list),
  fit_ar_model_bic
)

# ---- Extract AR roots and implied cycle periods ----
extract_ar_roots <- function(df, order, cat) {
  x <- na.omit(df$diff_index)

  if (length(x) < order + 1 || order == 0) {
    return(tibble(
      category = cat,
      has_cycle = FALSE,
      period_months = NA_real_,
      modulus = NA_real_
    ))
  }

  model <- arima(x, order = c(order, 0, 0))
  roots <- polyroot(c(1, -model$coef[1:order]))
  complex_roots <- roots[Im(roots) != 0]

  if (length(complex_roots) == 0) {
    tibble(
      category = cat,
      has_cycle = FALSE,
      period_months = NA_real_,
      modulus = NA_real_
    )
  } else {
    angle   <- Arg(complex_roots[1])
    period  <- 2 * pi / angle
    modulus <- Mod(complex_roots[1])

    tibble(
      category = cat,
      has_cycle = TRUE,
      period_months = round(period, 2),
      modulus = round(modulus, 3)
    )
  }
}

ar_cycle_summary <- map2_df(
  ar_bic_summary$category,
  ar_bic_summary$ar_order,
  ~ extract_ar_roots(data_diff_list[[.x]], .y, .x)
)

ar_final <- left_join(ar_bic_summary, ar_cycle_summary, by = "category")

# ---- Save results ----
write_csv(ar_final, file.path(out_dir, "ar_cycle_summary.csv"))

message("AR-based cycle detection completed.")
