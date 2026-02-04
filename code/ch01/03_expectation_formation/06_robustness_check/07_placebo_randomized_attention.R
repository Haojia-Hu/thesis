# ==========================================================
# Local Projection: Robustness Check 07
# Robustness: Using placebo randomized attention 
#
# Purpose:
#   Placebo test by randomizing lagged attention within each category.
#   Re-run LP and check whether interaction IRFs disappear.
#
# Input:
#   - data/transformed/ch01/panel/panel_data.csv
#
# Outputs:
#   - data/output/ch01/local_projection/robustness_check/placebo_randomized_attention/
#       - irf_placebo_randomized_attention.csv
#       - coef_path_placebo_randomized_attention.csv
#       - fig_irf_placebo_randomized_attention.png
# ==========================================================

library(tidyverse)
library(lubridate)
library(fixest)
library(broom)
library(ggplot2)
library(purrr)

# ==========================
# 0) Reproducibility
# ==========================
set.seed(12345)

# ==========================
# 1) Paths
# ==========================
in_file <- "data/transformed/ch01/panel/panel_data.csv"

out_dir <- "data/output/ch01/local_projection/robustness_check/placebo_randomized_attention"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_irf  <- file.path(out_dir, "irf_placebo_randomized_attention.csv")
out_coef <- file.path(out_dir, "coef_path_placebo_randomized_attention.csv")
fig_out  <- file.path(out_dir, "fig_irf_placebo_randomized_attention.png")

# ==========================
# 2) Load data
# ==========================
panel_df <- read_csv(in_file, show_col_types = FALSE) %>%
  mutate(Date = ymd(Date))

required_cols <- c(
  "Date","category","diff_index","D_InflationExp",
  "Diff_PriceChange","Diff_Volatility",
  "D_CpiAgg","D_EPU","D_ConsumerSent","D_Unemployment","D_RDI","D_Mortgage"
)
missing_cols <- setdiff(required_cols, names(panel_df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "))

# ==========================
# 3) Construct placebo lagged attention within category
# ==========================
panel_df_placebo <- panel_df %>%
  group_by(category) %>%
  arrange(Date) %>%
  mutate(
    Lag_Att = lag(diff_index),
    Placebo_Lag_Att = sample(Lag_Att),
    Interaction_PC  = Placebo_Lag_Att * Diff_PriceChange,
    Interaction_Vol = Placebo_Lag_Att * Diff_Volatility
  ) %>%
  ungroup()

horizons <- 1:12

# ==========================
# 4) Local Projections (h = 1..12)
#    IMPORTANT: lead computed within category
# ==========================
lp_models_placebo <- map(horizons, function(h) {

  df_h <- panel_df_placebo %>%
    group_by(category) %>%
    arrange(Date) %>%
    mutate(D_InflationExp_lead = lead(D_InflationExp, h)) %>%
    ungroup()

  feols(
    D_InflationExp_lead ~ Placebo_Lag_Att +
      Diff_PriceChange + Diff_Volatility +
      Interaction_PC + Interaction_Vol +
      D_CpiAgg + D_EPU + D_ConsumerSent + D_Unemployment + D_RDI + D_Mortgage |
      category,
    data = df_h,
    cluster = ~category + Date
  )
})

# ==========================
# 5) Extract IRFs
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

irf_pc  <- get_irf_df(lp_models_placebo, "Interaction_PC",  "Placebo: Attention × Price Change")
irf_vol <- get_irf_df(lp_models_placebo, "Interaction_Vol", "Placebo: Attention × Price Volatility")

irf_all <- bind_rows(irf_pc, irf_vol)
write_csv(irf_all, out_irf)

coef_path <- map2_dfr(lp_models_placebo, horizons, function(model, h) tidy(model) %>% mutate(h = h))
write_csv(coef_path, out_coef)

# ==========================
# 6) Plot
# ==========================
p <- ggplot(irf_all, aes(x = h, y = estimate, shape = variable)) +
  geom_line(linewidth = 1.0, color = "black") +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "gray80", alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Impact of Attention × Price Signals on Inflation Expectations\n(Placebo: Randomized Attention)",
    x = "Months Ahead (h)",
    y = "Coefficient Estimate",
    shape = "Variable"
  ) +
  theme_minimal(base_size = 14)

ggsave(fig_out, plot = p, width = 8.2, height = 5.2, dpi = 300)
