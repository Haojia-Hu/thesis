# ============================================================
# Purpose:
#   1) Read category-level attention indices for Chapter 1.
#   2) Remove smooth time trends and seasonal components from
#      each category-level attention index using a quadratic
#      time trend and month fixed effects.
#   3) Construct analysis-ready attention series by taking
#      first differences of the residual indices.
#
# Input (not tracked):
#   - Category-level attention indices
#     (data/transformed/ch01/index/*_index.csv)
#
# Core Output (not tracked):
#   - Detrended attention residual series
#     (stored as *_residual.csv under data/transformed/ch01/index/)
#   - First-differenced residual attention series
#     (stored as *_diff.csv under data/transformed/ch01/index/)
#
# Notes:
#   - Detailed file names and storage locations are documented
#     in data/transformed/ch01/index/README.md.
#
# ============================================================

library(tidyverse)
library(lubridate)
library(tseries)

# ---- Paths ----
index_dir <- file.path("data", "transformed", "ch01", "index")
resid_dir <- file.path("data", "transformed", "ch01", "residual")
diff_dir  <- file.path("data", "transformed", "ch01", "diff")
fig_dir   <- file.path("data", "output", "ch01", "figures")

dir.create(resid_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(diff_dir,  recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir,   recursive = TRUE, showWarnings = FALSE)

adf_out_path      <- file.path("data", "transformed", "ch01", "adf_residual_results.csv")
adf_diff_out_path <- file.path("data", "transformed", "ch01", "adf_diff_results.csv")

# ---- 1) Read & combine index files ----
index_files <- list.files(index_dir, pattern = "_index\\.csv$", full.names = TRUE)
stopifnot(length(index_files) > 0)

index_data <- bind_rows(lapply(index_files, function(file) {
  df <- read_csv(file, show_col_types = FALSE)

  # Find the column ending with "_index" and standardize to "index_value"
  index_col <- grep("_index$", names(df), value = TRUE)
  if (length(index_col) != 1) {
    stop(paste0("File must contain exactly one *_index column: ", file))
  }

  df <- df %>%
    rename(index_value = all_of(index_col)) %>%
    mutate(category = gsub("_index\\.csv$", "", basename(file)))

  df
}))

# ---- 2) Build trend terms ----
index_data <- index_data %>%
  mutate(
    Date = as.Date(Date),
    time_trend = as.numeric(Date),
    time_trend2 = time_trend^2,
    month_factor = factor(month(Date))
  )

# ---- 3) Detrend & deseasonalize by category (residual) ----
index_detrended <- index_data %>%
  group_by(category) %>%
  group_modify(~{
    m <- lm(index_value ~ time_trend + time_trend2 + month_factor, data = .x)
    .x %>% mutate(detrended_index = resid(m))
  }) %>%
  ungroup()

# ---- 4) Output residual CSVs (one per category) ----
for (cat in unique(index_detrended$category)) {
  cat_data <- index_detrended %>% filter(category == cat)
  write_csv(cat_data, file.path(resid_dir, paste0(cat, "_residual.csv")))
}

# ---- 5) Figure: detrended residual series (faceted) ----
p_resid <- ggplot(index_detrended, aes(x = Date, y = detrended_index)) +
  geom_line() +
  facet_wrap(~ category, scales = "free_y") +
  labs(
    title = "Attention Residual (Trend & Seasonality Removed)",
    x = "Month",
    y = "Residual Attention Index"
  ) +
  theme_minimal(base_size = 13)

print(p_resid)
ggsave(
  filename = file.path(fig_dir, "ch01_residual_by_category.png"),
  plot = p_resid,
  width = 12, height = 7, dpi = 300
)

# ---- Helper: safe ADF test ----
adf_safe <- function(x) {
  x <- na.omit(x)
  if (length(x) < 10) return(NA_real_)
  tryCatch(adf.test(x, alternative = "stationary")$p.value,
           error = function(e) NA_real_)
}

# ---- 6) ADF test for residual ----
adf_resid <- index_detrended %>%
  group_by(category) %>%
  summarise(adf_pvalue = adf_safe(detrended_index), .groups = "drop")

print(adf_resid)
write_csv(adf_resid, adf_out_path)

# ---- 7) First difference of residual ----
index_diff <- index_detrended %>%
  group_by(category) %>%
  arrange(Date) %>%
  mutate(diff_index = detrended_index - lag(detrended_index)) %>%
  ungroup()

# ---- 8) Figures: differenced residual ----
p_diff_all <- ggplot(index_diff, aes(x = Date, y = diff_index, color = category)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "First Difference of Residual Attention Index (All Categories)",
    x = "Month",
    y = "Δ Residual Attention Index"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")

print(p_diff_all)
ggsave(
  filename = file.path(fig_dir, "ch01_diff_residual_all_categories.png"),
  plot = p_diff_all,
  width = 12, height = 7, dpi = 300
)

p_diff_facet <- ggplot(index_diff, aes(x = Date, y = diff_index)) +
  geom_line() +
  facet_wrap(~ category, scales = "free_y") +
  labs(
    title = "First Difference of Residual Attention Index (By Category)",
    x = "Month",
    y = "Δ Residual Attention Index"
  ) +
  theme_minimal(base_size = 13)

print(p_diff_facet)
ggsave(
  filename = file.path(fig_dir, "ch01_diff_residual_by_category.png"),
  plot = p_diff_facet,
  width = 12, height = 7, dpi = 300
)

# ---- 9) Output diff CSVs (one per category) ----
for (cat in unique(index_diff$category)) {
  cat_data <- index_diff %>%
    filter(category == cat) %>%
    select(Date, diff_index)

  write_csv(cat_data, file.path(diff_dir, paste0(cat, "_diff.csv")))
}

# ---- 10) ADF test for differenced residual ----
adf_diff <- index_diff %>%
  group_by(category) %>%
  summarise(adf_pvalue = adf_safe(diff_index), .groups = "drop")

print(adf_diff)
write_csv(adf_diff, adf_diff_out_path)

message("Done. Outputs written to:",
        "\n- ", resid_dir,
        "\n- ", diff_dir,
        "\n- ", fig_dir,
        "\n- ", adf_out_path,
        "\n- ", adf_diff_out_path)
