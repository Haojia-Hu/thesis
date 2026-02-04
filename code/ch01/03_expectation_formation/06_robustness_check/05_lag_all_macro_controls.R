# ==========================================================
# Local Projection: Robustness Check 05
# Robustness: Lag all macro controls
#
# Purpose:
#   Local Projections where all macro control variables are lagged by one period.
#
# Input:
#   - data/transformed/ch01/panel/panel_data.csv
#
# Differences vs baseline:
#   - Replace contemporaneous macro controls (D_*) with lagged controls (L1_D_*)
#   - Keep lagged attention (L1_diff_index) and interaction terms unchanged
#
# Outputs:
#   - data/output/ch01/local_projection/robustness_check/lag_all_macro_controls/
#       - irf_lag_all_macro_controls.csv
#       - coef_path_lag_all_macro_controls.csv
#       - fig_irf_interactions_lag_all_macro_controls.png
# ==========================================================

library(tidyverse)
library(lubridate)
library(fixest)
library(broom)
library(ggplot2)
library(purrr)

# ==========================
# 0) Paths
# ==========================
in_file <- "data/transformed/ch01/panel/panel_data.csv"

out_dir <- "data/output/ch01/local_projection/robustness_check/lag_all_macro_controls"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_irf  <- file.path(out_dir, "irf_lag_all_macro_controls.csv")
out_coef <- file.path(out_dir, "coef_path_lag_all_macro_controls.csv")
fig_both <- file.path(out_dir, "fig_irf_interactions_lag_all_macro_controls.png")

# ==========================
# 1) Load data
# ==========================
panel_df <- read_csv(in_file, show_col_types = FALSE) %>%
  mutate(Date = ymd(Date))

required_cols <- c(
  "Date", "category",
  "diff_index",
  "Diff_PriceChange", "Diff_Volatility",
  "D_InflationExp",
  "D_CpiAgg", "D_EPU", "D_ConsumerSent", "D_Unemployment", "D_RDI", "D_Mortgage"
)

missing_cols <- setdiff(required_cols, names(panel_df))
if (length(missing_cols) > 0) {
  stop("Missing required columns in panel data: ", paste(missing_cols, collapse = ", "))
}

# ==========================
# 2) Construct lagged macro controls + lagged attention + interactions
# ==========================
panel_df4 <- panel_df %>%
  group_by(category) %>%
  arrange(Date) %>%
  mutate(
    # Lagged macro controls
    L1_D_CpiAgg        = lag(D_CpiAgg),
    L1_D_EPU           = lag(D_EPU),
    L1_D_ConsumerSent  = lag(D_ConsumerSent),
    L1_D_Unemployment  = lag(D_Unemployment),
    L1_D_Mortgage      = lag(D_Mortgage),
    L1_D_RDI           = lag(D_RDI),

    # Lagged attention
    L1_diff_index      = lag(diff_index),

    # Interaction terms
    Interaction_PC     = Diff_PriceChange * L1_diff_index,
    Interaction_Vol    = Diff_Volatility  * L1_diff_index
  ) %>%
  ungroup()

# ==========================
# 3) Local Projections (h = 1..12)
#    IMPORTANT: lead computed within category
# ==========================
horizons <- 1:12

lp_results_lagmacro <- map(horizons, function(h) {

  df_h <- panel_df4 %>%
    group_by(category) %>%
    arrange(Date) %>%
    mutate(D_InflationExp_lead = lead(D_InflationExp, h)) %>%
    ungroup()

  feols(
    D_InflationExp_lead ~
      Diff_PriceChange + Diff_Volatility +
      Interaction_PC + Interaction_Vol + L1_diff_index +
      L1_D_CpiAgg + L1_D_EPU + L1_D_ConsumerSent +
      L1_D_Unemployment + L1_D_Mortgage + L1_D_RDI |
      category,
    data = df_h
  )
})

# ==========================
# 4) Extract IRFs
# ==========================
get_irf_df <- function(models, term_name, label) {
  map2_dfr(models, horizons, function(model, h) {
    tb <- tidy(model)
    row <- tb %>% filter(term == term_name)

    if (nrow(row) == 0) {
      return(tibble(
        h = h,
        estimate = NA_real_,
        std_error = NA_real_,
        conf.low = NA_real_,
        conf.high = NA_real_,
        variable = label
      ))
    }

    tibble(
      h = h,
      estimate = row$estimate,
      std_error = row$std.error,
      conf.low = row$estimate - 1.96 * row$std.error,
      conf.high = row$estimate + 1.96 * row$std.error,
      variable = label
    )
  })
}

irf_pc  <- get_irf_df(lp_results_lagmacro, "Interaction_PC",  "Attention × Price Change")
irf_vol <- get_irf_df(lp_results_lagmacro, "Interaction_Vol", "Attention × Volatility")
irf_att <- get_irf_df(lp_results_lagmacro, "L1_diff_index",   "Attention (L1)")

irf_all <- bind_rows(irf_att, irf_pc, irf_vol)
write_csv(irf_all, out_irf)

coef_path <- map2_dfr(lp_results_lagmacro, horizons, function(model, h) {
  tidy(model) %>% mutate(h = h)
})
write_csv(coef_path, out_coef)

# ==========================
# 5) Plot: two interactions together
# ==========================
irf_interactions <- bind_rows(irf_pc, irf_vol)

p <- ggplot(irf_interactions, aes(x = h, y = estimate, shape = variable)) +
  geom_line(linewidth = 1.0, color = "black") +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "gray80", alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Impact of Attention × Price Signals on Inflation Expectations\n(All Macro Controls Lagged)",
    x = "Months Ahead (h)",
    y = "Coefficient Estimate",
    shape = "Variable"
  ) +
  theme_minimal(base_size = 14)

ggsave(fig_both, plot = p, width = 8.2, height = 5.2, dpi = 300)
