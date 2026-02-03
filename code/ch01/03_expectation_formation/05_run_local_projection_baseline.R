# ==========================================================
# Purpose:
#   Run Local Projections (h = 1..12) on the category panel and produce IRFs for:
#     (1) Attention (lagged): L1_diff_index
#     (2) Attention × Price Change: Interaction_PC
#     (3) Attention × Price Volatility: Interaction_Vol
#   Also save a combined plot of the two interaction IRFs.
#
# Inputs:
#   - data/transformed/ch01/panel/panel_data.csv
#     Required columns:
#       Date, category,
#       diff_index,
#       Diff_PriceChange, Diff_Volatility,
#       D_InflationExp,
#       D_CpiAgg, D_EPU, D_ConsumerSent, D_Unemployment, D_RDI, D_Mortgage
#
# Output directory:
#   - data/output/ch01/local_projection/baseline/
#
# Outputs:
#   - irf_baseline.csv
#   - coef_path_baseline.csv
#   - fig_irf_attention.png
#   - fig_irf_interaction_pc.png
#   - fig_irf_interaction_vol.png
#   - fig_irf_interactions_pc_vs_vol.png
# ==========================================================

library(tidyverse)
library(lubridate)
library(fixest)
library(broom)
library(ggplot2)

# ======== 0) Paths ========
in_file <- "data/transformed/ch01/panel/panel_data.csv"

out_dir <- "data/output/ch01/local_projection/baseline"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_irf   <- file.path(out_dir, "irf_baseline.csv")
out_coef  <- file.path(out_dir, "coef_path_baseline.csv")

fig_att   <- file.path(out_dir, "fig_irf_attention.png")
fig_pc    <- file.path(out_dir, "fig_irf_interaction_pc.png")
fig_vol   <- file.path(out_dir, "fig_irf_interaction_vol.png")
fig_both  <- file.path(out_dir, "fig_irf_interactions_pc_vs_vol.png")

# ======== 1) Load data ========
panel_df <- read_csv(in_file, show_col_types = FALSE) %>%
  mutate(Date = ymd(Date))

# Basic column check (fail fast)
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

# ======== 2) Construct lag + interactions ========
panel_df1 <- panel_df %>%
  group_by(category) %>%
  arrange(Date) %>%
  mutate(
    L1_diff_index   = lag(diff_index),
    Interaction_PC  = Diff_PriceChange * L1_diff_index,
    Interaction_Vol = Diff_Volatility  * L1_diff_index
  ) %>%
  ungroup()

# ======== 3) Local Projections (h = 1..12): IMPORTANT: lead computed within category ========
horizons <- 1:12

lp_results <- map(horizons, function(h) {

  df_h <- panel_df1 %>%
    group_by(category) %>%
    arrange(Date) %>%
    mutate(D_InflationExp_lead = lead(D_InflationExp, h)) %>%
    ungroup()

  feols(
    D_InflationExp_lead ~
      Diff_PriceChange + L1_diff_index + Interaction_PC +
      Diff_Volatility  + Interaction_Vol +
      D_CpiAgg + D_EPU + D_ConsumerSent + D_Unemployment + D_RDI + D_Mortgage |
      category,
    data = df_h
  )
})

# ========= 4) Helper: extract IRF for a term ========
get_irf_df <- function(models, term_name, spec_name = "baseline") {
  map2_dfr(models, horizons, function(model, h) {
    tb <- tidy(model)
    row <- tb %>% filter(term == term_name)

    # If term missing (e.g., collinearity in some horizon), return NA row
    if (nrow(row) == 0) {
      return(tibble(
        spec = spec_name,
        term = term_name,
        h = h,
        estimate = NA_real_,
        std.error = NA_real_,
        conf.low = NA_real_,
        conf.high = NA_real_
      ))
    }

    tibble(
      spec = spec_name,
      term = term_name,
      h = h,
      estimate = row$estimate,
      std.error = row$std.error,
      conf.low = row$estimate - 1.96 * row$std.error,
      conf.high = row$estimate + 1.96 * row$std.error
    )
  })
}

irf_att <- get_irf_df(lp_results, "L1_diff_index")   %>% mutate(type = "Attention (L1)")
irf_pc  <- get_irf_df(lp_results, "Interaction_PC")  %>% mutate(type = "Attention × Price Change")
irf_vol <- get_irf_df(lp_results, "Interaction_Vol") %>% mutate(type = "Attention × Price Volatility")

irf_all <- bind_rows(irf_att, irf_pc, irf_vol)

# Save IRF table
write_csv(irf_all, out_irf)

# Also save full coefficient paths for all terms/horizons (useful for checks)
coef_path <- map2_dfr(lp_results, horizons, function(model, h) {
  tidy(model) %>%
    mutate(h = h)
})
write_csv(coef_path, out_coef)

# ======== 5) Plot helpers ========
plot_single_irf <- function(df_one, title_text, out_path) {
  p <- ggplot(df_one, aes(x = h, y = estimate)) +
    geom_line(linewidth = 1.0) +
    geom_point(size = 2.0) +
    geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.2, color = NA) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      title = title_text,
      x = "Months Ahead (h)",
      y = "Coefficient Estimate"
    ) +
    theme_minimal(base_size = 13)

  ggsave(out_path, plot = p, width = 7.5, height = 4.8, dpi = 300)
}

plot_two_interactions <- function(df_pc, df_vol, out_path) {
  df_both <- bind_rows(df_pc, df_vol)

  p <- ggplot(df_both, aes(x = h, y = estimate, linetype = type, shape = type)) +
    geom_line(linewidth = 1.0) +
    geom_point(size = 2.0) +
    geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, color = NA) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      title = "Interaction IRFs: Attention × Price Signals",
      x = "Months Ahead (h)",
      y = "Coefficient Estimate",
      linetype = "",
      shape = ""
    ) +
    theme_minimal(base_size = 13)

  ggsave(out_path, plot = p, width = 8.2, height = 5.2, dpi = 300)
}

# ==========================
# 6) Produce required figures
#     - 3 single IRFs
#     - 1 combined (two interactions)
# ==========================
plot_single_irf(
  irf_att,
  "IRF: Attention (Lagged) → Inflation Expectations",
  fig_att
)

plot_single_irf(
  irf_pc,
  "IRF: Attention × Price Change → Inflation Expectations",
  fig_pc
)

plot_single_irf(
  irf_vol,
  "IRF: Attention × Price Volatility → Inflation Expectations",
  fig_vol
)

plot_two_interactions(
  irf_pc,
  irf_vol,
  fig_both
)

message("Done. Outputs saved to: ", out_dir)
