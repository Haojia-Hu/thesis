# ============================================================
# Purpose:
#   1) Estimate univariate AR(p) models for each category-level
#      first-differenced attention index.
#   2) Use selected AR orders (from BIC-based selection) to
#      generate 12-month-ahead forecasts.
#   3) Export forecast tables and figures for Chapter 1.
#
# Input (not tracked):
#   - First-differenced attention indices:
#     data/transformed/ch01/diff/*_diff.csv
#   - AR orders selected by BIC (from 01_ar_cycle_detection.R):
#     data/transformed/ch01/attention_cycles/ar_cycle_summary.csv
#
# Core Output (not tracked):
#   - Forecast tables (per category):
#     data/transformed/ch01/attention_cycles/forecasts/*_ar_forecast.csv
#   - Forecast figures:
#     data/output/ch01/figures/forecast_*_ar.png
#     data/output/ch01/figures/All_AR_Forecasts.pdf
# ============================================================

library(tidyverse)
library(forecast)
library(gridExtra)
library(lubridate)

# ---- Paths ----
diff_dir <- file.path("data", "transformed", "ch01", "diff")

cycle_dir <- file.path("data", "transformed", "ch01", "attention_cycles")
ar_order_path <- file.path(cycle_dir, "ar_cycle_summary.csv")

forecast_dir <- file.path(cycle_dir, "forecasts")
fig_dir <- file.path("data", "output", "ch01", "figures")

dir.create(forecast_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Read diff series ----
file_list <- list.files(diff_dir, pattern = "_diff\\.csv$", full.names = TRUE)
stopifnot(length(file_list) > 0)

data_diff_list <- lapply(file_list, read_csv, show_col_types = FALSE)
names(data_diff_list) <- gsub("_diff\\.csv$", "", basename(file_list))

# ---- Read AR orders (BIC-selected) ----
stopifnot(file.exists(ar_order_path))

ar_order_tbl <- read_csv(ar_order_path, show_col_types = FALSE) %>%
  select(category, ar_order) %>%
  mutate(
    category = as.character(category),
    ar_order = as.integer(ar_order)
  )

# Keep only categories we actually have data for
ar_order_tbl <- ar_order_tbl %>%
  filter(category %in% names(data_diff_list))

# ---- Forecast function ----
forecast_ar <- function(df, ar_order, h = 12) {
  df_clean <- df %>%
    mutate(Date = as.Date(Date)) %>%
    drop_na(diff_index, Date) %>%
    arrange(Date)

  if (nrow(df_clean) <= ar_order + 1) return(NULL)

  y <- df_clean$diff_index

  tryCatch({
    model <- Arima(y, order = c(ar_order, 0, 0))
    fc <- forecast(model, h = h)

    forecast_dates <- seq(
      max(df_clean$Date) %m+% months(1),
      by = "month",
      length.out = h
    )

    tibble(
      Date = forecast_dates,
      forecast = as.numeric(fc$mean),
      lower_95 = as.numeric(fc$lower[, 2]),
      upper_95 = as.numeric(fc$upper[, 2])
    )
  }, error = function(e) {
    message("Forecast failed for AR(", ar_order, "): ", e$message)
    NULL
  })
}

# ---- Main loop ----
plot_list <- list()

for (i in seq_len(nrow(ar_order_tbl))) {
  cat <- ar_order_tbl$category[i]
  order <- ar_order_tbl$ar_order[i]

  if (is.na(order) || order <= 0) next
  if (is.null(data_diff_list[[cat]])) next

  df <- data_diff_list[[cat]]
  pred <- forecast_ar(df, order)
  if (is.null(pred)) next

  # Save forecast table
  write_csv(pred, file.path(forecast_dir, paste0(cat, "_ar_forecast.csv")))

  # Plot actual + forecast
  df_clean <- df %>%
    mutate(Date = as.Date(Date)) %>%
    drop_na(diff_index, Date) %>%
    arrange(Date)

  p <- ggplot() +
    geom_line(data = df_clean, aes(x = Date, y = diff_index), color = "black") +
    geom_line(data = pred, aes(x = Date, y = forecast), color = "red") +
    geom_ribbon(
      data = pred,
      aes(x = Date, ymin = lower_95, ymax = upper_95),
      alpha = 0.2,
      fill = "pink"
    ) +
    labs(
      title = paste0("AR(", order, ") Forecast of ", str_to_title(cat)),
      x = "Date",
      y = "First-Differenced Attention (diff_index)"
    ) +
    theme_minimal(base_size = 13)

  ggsave(
    filename = file.path(fig_dir, paste0("forecast_", cat, "_ar.png")),
    plot = p,
    width = 8,
    height = 4
  )

  plot_list[[cat]] <- p
}

# ---- Combine plots to PDF ----
if (length(plot_list) > 0) {
  pdf(file.path(fig_dir, "All_AR_Forecasts.pdf"), width = 8, height = 4)
  for (p in plot_list) print(p)
  dev.off()


