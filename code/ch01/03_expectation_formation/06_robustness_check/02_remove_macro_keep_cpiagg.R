# ==========================================================
# Local Projection — Robustness Check 02
# Robustness: Remove macro variables
#
# Purpose:
#   Local Projections with macro controls removed, keeping only D_CpiAgg.
#   (Lagged attention and interaction terms remain as in baseline.)
#
# Input:
#   - data/transformed/ch01/panel/panel_data.csv
#
# Differences vs baseline:
#   - Drop macro controls: D_EPU, D_ConsumerSent, D_Unemployment, D_RDI, D_Mortgage
#   - Keep only D_CpiAgg
#   - Clustered SEs by category and Date
#
# Outputs:
#   - data/output/ch01/local_projection/robustness_check/remove_macro_keep_cpiagg/
#       - irf_remove_macro_keep_cpiagg.csv
#       - coef_path_remove_macro_keep_cpiagg.csv
#       - fig_irf_interactions_remove_macro_keep_cpiagg.png
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

out_dir <- "data/output/ch01/local_projection/robustness_check/remove_macro_keep_cpiagg"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_irf  <- file.path(out_dir, "irf_remove_macro_keep_cpiagg.csv")
out_coef <- file.path(out_dir, "coef_path_remove_macro_keep_cpiagg.csv")
fig_both <- file.path(out_dir, "fig_irf_interactions_remove_macro_keep_cpiagg.png")

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
  "D_CpiAgg"
)
missing_cols <- setdiff(required_cols, names(panel_df))
if (length(missing_cols) > 0) {
  stop("Missing required columns in panel data: ", paste(missing_cols, collapse = ", "))
}

# ==========================
# 2) Construct lagged attention + interactions (within category)
# ==========================
panel_df3 <- panel_df %>%
  group_by(category) %>%
  arrange(Date) %>%
  mutate(
    L1_diff_index   = lag(diff_index),
    Interaction_PC  = L1_diff_index * Diff_PriceChange,
    Interaction_Vol = L1_diff_index * Diff_Volatility
  ) %>%
  ungroup()

# ==========================
# 3) Local Projections (h = 1..12)
#    IMPORTANT: lead computed within category
# ==========================
horizons <- 1:12

lp_results <- map(horizons, function(h) {

  df_h <- panel_df3 %>%
    group_by(category) %>%
    arrange(Date) %>%
    mutate(D_InflationExp_lead = lead(D_InflationExp, n = h)) %>%
    ungroup()

  feols(
    D_InflationExp_lead ~
      Diff_PriceChange + L1_diff_index + Interaction_PC +
      Diff_Volatility  + Interaction_Vol +
      D_CpiAgg |
      category,
    data = df_h,
    cluster = ~ category + Date
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

irf_att <- get_irf_df(lp_results, "L1_diff_index", "Attention (L1)")
irf_pc  <- get_irf_df(lp_results, "Interaction_PC", "Attention × Price Change")
irf_vol <- get_irf_df(lp_results, "Interaction_Vol", "Attention × Price Volatility")

irf_all <- bind_rows(irf_att, irf_pc, irf_vol)
write_csv(irf_all, out_irf)

coef_path <- map2_dfr(lp_results, horizons, function(model, h) {
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
    title = "Impact of Attention × Price Signals on Inflation Expectations\n(Macro Controls Removed: Aggregate CPI Kept)",
    x = "Months Ahead (h)",
    y = "Coefficient Estimate",
    shape = "Variable"
  ) +
  theme_minimal(base_size = 14)

ggsave(fig_both, plot = p, width = 8.2, height = 5.2, dpi = 300)
