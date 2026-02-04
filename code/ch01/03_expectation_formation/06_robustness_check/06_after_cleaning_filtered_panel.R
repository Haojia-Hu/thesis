# ==========================================================
# Local Projection: Robustness Check 06
# Robustness: Using filtered panel
#
# Purpose:
#   Re-run baseline LP specification on a cleaned/filtered panel dataset.
#
# Input:
#   - data/transformed/ch01/panel/panel_data_filtered.csv
#
# Outputs:
#   - data/output/ch01/local_projection/robustness_check/after_cleaning/
#       - irf_after_cleaning.csv
#       - coef_path_after_cleaning.csv
#       - fig_irf_interactions_after_cleaning.png
# ==========================================================

library(tidyverse)
library(lubridate)
library(fixest)
library(broom)
library(ggplot2)
library(purrr)

in_file <- "data/transformed/ch01/panel/panel_data_filtered.csv"

out_dir <- "data/output/ch01/local_projection/robustness_check/after_cleaning"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_irf  <- file.path(out_dir, "irf_after_cleaning.csv")
out_coef <- file.path(out_dir, "coef_path_after_cleaning.csv")
fig_both <- file.path(out_dir, "fig_irf_interactions_after_cleaning.png")

panel_df <- read_csv(in_file, show_col_types = FALSE) %>%
  mutate(Date = ymd(Date))

required_cols <- c(
  "Date","category","diff_index","D_InflationExp",
  "Diff_PriceChange","Diff_Volatility",
  "D_CpiAgg","D_EPU","D_ConsumerSent","D_Unemployment","D_RDI","D_Mortgage"
)
missing_cols <- setdiff(required_cols, names(panel_df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "))

panel_df1 <- panel_df %>%
  group_by(category) %>%
  arrange(Date) %>%
  mutate(
    L1_diff_index   = lag(diff_index),
    Interaction_PC  = Diff_PriceChange * L1_diff_index,
    Interaction_Vol = Diff_Volatility  * L1_diff_index
  ) %>%
  ungroup()

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

get_irf_df <- function(models, term_name, label) {
  map2_dfr(models, horizons, function(model, h) {
    tb <- tidy(model)
    row <- tb %>% filter(term == term_name)

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

irf_pc  <- get_irf_df(lp_results, "Interaction_PC",  "Attention × Price Change")
irf_vol <- get_irf_df(lp_results, "Interaction_Vol", "Attention × Price Volatility")
irf_att <- get_irf_df(lp_results, "L1_diff_index",   "Attention (L1)")

irf_all <- bind_rows(irf_att, irf_pc, irf_vol)
write_csv(irf_all, out_irf)

coef_path <- map2_dfr(lp_results, horizons, function(model, h) tidy(model) %>% mutate(h = h))
write_csv(coef_path, out_coef)

irf_interactions <- bind_rows(irf_pc, irf_vol)

p <- ggplot(irf_interactions, aes(x = h, y = estimate, shape = variable)) +
  geom_line(linewidth = 1.0, color = "black") +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "gray80", alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Impact of Attention × Price Signals on Inflation Expectations\n(After Cleaning)",
    x = "Months Ahead (h)",
    y = "Coefficient Estimate",
    shape = "Variable"
  ) +
  theme_minimal(base_size = 14)

ggsave(fig_both, plot = p, width = 8.2, height = 5.2, dpi = 300)

message("Done. Outputs saved to: ", out_dir)
