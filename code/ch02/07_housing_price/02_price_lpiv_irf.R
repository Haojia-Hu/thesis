# ==============================================================================
# Purpose: Estimate Local Projection IV (LP-IV) impulse responses of CBSA-level
#          monthly house price growth to the local mortgage rate gap (RateGap).
#          The endogenous regressor is `rate_gap`, instrumented by `Z_bartik`.
#          All specifications include CBSA fixed effects and month fixed effects,
#          with standard errors clustered at the CBSA level.
#
# This script implements:
#   1) Baseline LP-IV (non-cumulative, month-by-month response)
#   2) Horizons h = 0..12 (including contemporaneous effect at h=0)
#
# Inputs (data/transformed/ch02):
# 1) Zillow ZHVI (CBSA-month)
#   data/transformed/ch02/zillow/zillow_zhvi.csv
#   Required columns: cbsa_code, yearmon, proxy_value
#
# 2) Core panel with RateGap, IV, and controls  (NOTE: PATH UNCHANGED)
#   data/transformed/ch02/housing_quant/panel_rategap_hat.csv
#   Required columns: cbsa_code, ym, rate_gap, Z_bartik, unemployment_rate,
#                     mig_rate_month, bps_total
#
# 3) Zillow New Listings (CBSA-month)
#   data/transformed/ch02/zillow/zillow_newlisting.csv
#   Required columns: cbsa_code, yearmon, proxy_value
#
# Outputs (data/output/ch02/housing_price):
# 1) lp_price_irf_non_cum.csv
#   Horizon-by-horizon LP-IV estimates (coef, SE, 95% CI, N)
#
# 2) lp_price_irf_non_cum.png
#   IRF plot with 95% confidence band
#
# Notes
# -----
# - Month FE uses `ym` (YYYY-MM) to align with "Month FE = Yes" in the paper.
# - Dependent variable is monthly house price growth:
#     price_chg = 100 * (log(ZHVI_t) - log(ZHVI_{t-1}))
# - LP is non-cumulative: y_h = lead(price_chg, h).
# - proxy_newlist is NOT used as a regressor here; it is used to keep the sample
#   consistent with the broader Chapter 2 pipeline (and future mechanism parts).
# ==============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(stringr)
  library(purrr)
  library(fixest)
  library(ggplot2)
})

# ---- Paths (repo) ----
# (Keep panel path unchanged per your pipeline.)
path_price   <- file.path("data", "transformed", "ch02", "zillow", "zillow_zhvi.csv")
path_panel   <- file.path("data", "transformed", "ch02", "housing_quant", "panel_rategap_hat.csv")
path_newlist <- file.path("data", "transformed", "ch02", "zillow", "zillow_newlisting.csv")

out_dir <- file.path("data", "output", "ch02", "housing_price")
out_csv <- file.path(out_dir, "lp_price_irf_non_cum.csv")
out_png <- file.path(out_dir, "lp_price_irf_non_cum.png")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- 1) Read new listings (sample alignment) ----
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

# ---- 2) Read core panel: RateGap + IV + controls ----
panel_core <- fread(path_panel) %>%
  mutate(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym        = as.character(ym)
  )

# ---- 3) Read prices and construct monthly growth ----
price <- fread(path_price) %>%
  transmute(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym        = substr(as.character(yearmon), 1, 7),
    zhvi      = as.numeric(proxy_value)
  ) %>%
  arrange(cbsa_code, ym) %>%
  group_by(cbsa_code) %>%
  mutate(price_chg = 100 * (log(zhvi) - log(dplyr::lag(zhvi)))) %>%
  ungroup() %>%
  select(cbsa_code, ym, price_chg)

# ---- 4) Combine into estimation panel ----
panel <- panel_core %>%
  left_join(newl,  by = c("cbsa_code", "ym")) %>%
  left_join(price, by = c("cbsa_code", "ym")) %>%
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
    cbsa_code = as.factor(cbsa_code),
    ym        = as.character(ym)
  )

cat("LP-IV sample coverage:\n")
cat("  Observations:", nrow(panel), "\n")
cat("  CBSAs:", n_distinct(panel$cbsa_code), "\n")
cat("  Months:", n_distinct(panel$ym), "\n\n")

# ---- 5) LP-IV estimation: horizons 0..12 (non-cumulative) ----
horizons <- 0:12

results_lp <- map_dfr(horizons, function(h) {

  panel_h <- panel %>%
    group_by(cbsa_code) %>%
    arrange(ym) %>%
    mutate(y_h = dplyr::lead(price_chg, h)) %>%
    ungroup() %>%
    filter(!is.na(y_h))

  model_h <- feols(
    y_h ~ unemployment_rate + mig_rate_month + bps_total |
      cbsa_code + ym |
      rate_gap ~ Z_bartik,
    cluster = ~ cbsa_code,
    data    = panel_h
  )

  # In fixest, coefficient name is typically "rate_gap"
  b  <- unname(coef(model_h)[["rate_gap"]])
  se <- unname(se(model_h)[["rate_gap"]])

  tibble(
    horizon  = h,
    coef     = b,
    se       = se,
    ci_lower = b - 1.96 * se,
    ci_upper = b + 1.96 * se,
    n_obs    = nobs(model_h)
  )
})

print(results_lp, n = Inf)

# ---- 6) Save results table ----
fwrite(as.data.table(results_lp), out_csv)

# ---- 7) Plot IRF ----
p <- ggplot(results_lp, aes(x = horizon, y = coef)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.8) +
  labs(
    title    = "Dynamic Effect of Rate Gap on House Prices (LP-IV)",
    subtitle = "Non-cumulative response of monthly price growth (h = 0..12)",
    x        = "Months after shock (h)",
    y        = "Effect on monthly house price growth (pp)",
    caption  = "Controls: unemployment rate, migration rate, bps_total. FE: CBSA + Month. SE clustered by CBSA."
  ) +
  theme_minimal(base_size = 12)

ggsave(out_png, plot = p, width = 10, height = 6, dpi = 300)

cat("\nSaved outputs:\n")
cat("  -", out_csv, "\n")
cat("  -", out_png, "\n")
