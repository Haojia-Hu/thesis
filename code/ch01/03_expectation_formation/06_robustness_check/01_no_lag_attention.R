# ==========================================================
# Local Projection — Robustness Check 01
# Robustness: No Lag on Attention
#
# Purpose:
#   Assess the sensitivity of baseline Local Projection results to the timing of household attention by replacing lagged attention with contemporaneous attention.
#
# Key modification relative to baseline:
#   - Baseline specification uses lagged attention (L1_diff_index)
#   - This robustness uses current attention (diff_index)
#   - Interaction terms are redefined as:
#       * diff_index × Diff_PriceChange
#       * diff_index × Diff_Volatility
#   - Standard errors are clustered by category and date
#
# Input:
#   - data/transformed/ch01/panel/panel_data.csv
#
# Output directory:
#   - data/output/ch01/local_projection/robustness_check/no_lag_attention/
#
# Outputs:
#   - irf_no_lag_attention.csv
#   - coef_path_no_lag_attention.csv
#   - fig_irf_interactions_no_lag_attention.png
# ==========================================================

library(tidyverse)
library(lubridate)
library(fixest)
library(broom)
library(ggplot2)
library(purrr)

# ======== 0) Paths ========
in_file <- "data/transformed/ch01/panel/panel_data.csv"

out_dir <- "data/output/ch01/local_projection/no_lag_attention"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_irf  <- file.path(out_dir, "irf_no_lag_attention.csv")
out_coef <- file.path(out_dir, "coef_path_no_lag_attention.csv")
fig_both <- file.path(out_dir, "fig_irf_interactions_no_lag_attention.png")

# ======== 1) Load data ========
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

# ======== 2) Current attention interactions ========
panel_df2 <- panel_df %>%
  mutate(
    Interaction_PC_now  = diff_index * Diff_PriceChange,
    Interaction_Vol_now = diff_index * Diff_Volatility
  )

# ==========================
# 3) Local Projections (h = 1..12)
#    IMPORTANT: lead computed within category
# ==========================
horizons <- 1:12

lp_results_now <- map(horizons, function(h) {

  df_h <- panel_df2 %>%
    group_by(category) %>%
    arrange(Date) %>%
    mutate(D_InflationExp_lead = lead(D_InflationExp, n = h)) %>%
    ungroup()

  feols(
    D_InflationExp_lead ~
      Diff_PriceChange + diff_index +
      Interaction_PC_now + Interaction_Vol_now +
      D_CpiAgg + D_EPU + D_ConsumerSent + D_Unemployment + D_RDI + D_Mortgage |
      category,
    data = df_h,
    cluster = ~ category + Date
  )
})

# ======== 4) Extract IRFs ========
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

irf_att_now <- get_irf_df(lp_results_now, "diff_index", "Attention (current)")
irf_pc_now  <- get_irf_df(lp_results_now, "Interaction_PC_now", "Attention × Price Change")
irf_vol_now <- get_irf_df(lp_results_now, "Interaction_Vol_now", "Attention × Price Volatility")

irf_all <- bind_rows(irf_att_now, irf_pc_now, irf_vol_now)

write_csv(irf_all, out_irf)

coef_path <- map2_dfr(lp_results_now, horizons, function(model, h) {
  tidy(model) %>% mutate(h = h)
})
write_csv(coef_path, out_coef)

# ==========================
# 5) Plot: two interactions together (matches your original intent)
# ==========================
irf_now_interactions <- bind_rows(irf_pc_now, irf_vol_now)

p <- ggplot(irf_now_interactions, aes(x = h, y = estimate, shape = variable)) +
  geom_line(linewidth = 1.0, color = "black") +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "gray80", alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Impact of Attention × Price Signals on Inflation Expectations (No Lag on Attention)",
    x = "Months Ahead (h)",
    y = "Coefficient Estimate",
    shape = "Variable"
  ) +
  theme_minimal(base_size = 14)

ggsave(fig_both, plot = p, width = 8.2, height = 5.2, dpi = 300)
