# ==============================================================================
# Purpose: Estimate heterogeneous effects of RateGap on house price growth
#          using 2SLS and Local Projection IV (LP-IV).
#
# This script implements heterogeneity analysis by:
#   1) Local Employment Growth (QCEW-based)
#   2) Housing Supply Elasticity (Saiz 2010)
#
# Baseline specification:
#   price_chg ~ controls | CBSA FE + Month FE | rate_gap ~ Z_bartik
#   SE clustered at CBSA level.
#
# Dynamic specification:
#   price_chg_{t+h} = β_h * rate_gap_t + controls
#   IV: Z_bartik
#   FE: CBSA + Month
#
# Inputs (data/transformed/ch02):
#
# 1) Zillow price index
#   data/transformed/ch02/zillow/zillow_zhvi.csv
#
# 2) Core panel
#   data/transformed/ch02/housing_quant/panel_rategap_hat.csv
#
# 3) Zillow new listings
#   data/transformed/ch02/zillow/zillow_newlisting.csv
#
# 4) CBSA-level employment (QCEW aggregated)
#   data/transformed/ch02/housing_price/QCEW_cbsa_totalemp.csv
#
# 5) Saiz 2010 elasticity mapped to CBSA
#   data/transformed/ch02/housing_price/saiz2010_cbsa.csv
#
# Outputs (data/output/ch02/housing_price):
#
#   lp_price_hetero_employment.csv
#   lp_price_hetero_supply_elasticity.csv
#   lp_price_hetero_employment.png
#   lp_price_hetero_supply_elasticity.png
#
# ==============================================================================

library(data.table)
library(dplyr)
library(stringr)
library(purrr)
library(fixest)
library(ggplot2)

# ==== Load transformed data ====
path_price <- "data/transformed/ch02/zillow/zillow_zhvi.csv"
path_panel <- "data/transformed/ch02/housing_quant/panel_rategap_hat.csv"
path_emp   <- "data/transformed/ch02/housing_price/QCEW_cbsa_totalemp.csv"
path_saiz  <- "data/transformed/ch02/housing_price/saiz2010_cbsa.csv"

price_raw <- fread(path_price)
panel_core <- fread(path_panel)
employment <- fread(path_emp)
saiz <- fread(path_saiz)

# ==== Construct price growth ====
price <- price_raw %>%
  transmute(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym = substr(as.character(yearmon), 1, 7),
    price = as.numeric(proxy_value)
  ) %>%
  arrange(cbsa_code, ym) %>%
  group_by(cbsa_code) %>%
  mutate(price_chg = 100 * (log(price) - log(lag(price)))) %>%
  ungroup() %>%
  select(cbsa_code, ym, price_chg)

# ==== Merge panel ====
panel <- panel_core %>%
  left_join(price, by = c("cbsa_code","ym")) %>%
  left_join(employment, by = c("cbsa_code","ym")) %>%
  left_join(saiz, by = "cbsa_code") %>%
  filter(!is.na(price_chg),
         !is.na(rate_gap),
         !is.na(Z_bartik))

# =========================================================
# 1) Heterogeneity by Employment Growth
# =========================================================

panel <- panel %>%
  group_by(cbsa_code) %>%
  mutate(avg_emp_growth = mean(employment_growth, na.rm = TRUE)) %>%
  ungroup()

median_emp <- median(panel$avg_emp_growth, na.rm = TRUE)

panel_high_emp <- panel %>% filter(avg_emp_growth > median_emp)
panel_low_emp  <- panel %>% filter(avg_emp_growth <= median_emp)

# ---- Local Projection ----
horizons <- 0:12

run_lp <- function(data, label){

  map_dfr(horizons, function(h){

    data_lp <- data %>%
      group_by(cbsa_code) %>%
      arrange(ym) %>%
      mutate(y_h = lead(price_chg, h)) %>%
      ungroup()

    model <- feols(
      y_h ~ unemployment_rate + mig_rate_month + bps_total |
        cbsa_code + ym |
        rate_gap ~ Z_bartik,
      cluster = ~ cbsa_code,
      data = data_lp
    )

    tibble(
      group = label,
      horizon = h,
      coef = coef(model)["fit_rate_gap"],
      se = se(model)["fit_rate_gap"]
    )
  })
}

results_emp <- bind_rows(
  run_lp(panel_high_emp, "High Employment Growth"),
  run_lp(panel_low_emp,  "Low Employment Growth")
) %>%
  mutate(
    ci_lower = coef - 1.96 * se,
    ci_upper = coef + 1.96 * se
  )

# Save
write.csv(results_emp,
          "data/output/ch02/housing_price/lp_price_hetero_employment.csv",
          row.names = FALSE)

# Plot
p1 <- ggplot(results_emp,
             aes(x = horizon, y = coef, color = group, fill = group)) +
  geom_line(size = 1.1) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              alpha = 0.15, color = NA) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  theme_minimal()

ggsave("data/output/ch02/housing_price/lp_price_hetero_employment.png",
       p1, width = 10, height = 6)

# =========================================================
# 2) Heterogeneity by Supply Elasticity (Saiz 2010)
# =========================================================

median_elast <- median(panel$elasticity, na.rm = TRUE)

panel_high_elast <- panel %>% filter(elasticity > median_elast)
panel_low_elast  <- panel %>% filter(elasticity <= median_elast)

results_elast <- bind_rows(
  run_lp(panel_high_elast, "High Supply Elasticity"),
  run_lp(panel_low_elast,  "Low Supply Elasticity")
) %>%
  mutate(
    ci_lower = coef - 1.96 * se,
    ci_upper = coef + 1.96 * se
  )

write.csv(results_elast,
          "data/output/ch02/housing_price/lp_price_hetero_supply_elasticity.csv",
          row.names = FALSE)

p2 <- ggplot(results_elast,
             aes(x = horizon, y = coef, color = group, fill = group)) +
  geom_line(size = 1.1) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              alpha = 0.15, color = NA) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  theme_minimal()

ggsave("data/output/ch02/housing_price/lp_price_hetero_supply_elasticity.png",
       p2, width = 10, height = 6)

# ==============================================================================
