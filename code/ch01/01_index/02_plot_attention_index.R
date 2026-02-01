# =========================
# Purpose:
#   1) Plot category-level attention indices for Chapter 1.
#
#   2) Input (not tracked):
#   - data/transformed/ch01/index/*_index.csv
#
#   3) Output (not tracked):
#   - data/output/ch01/figures/fig_index_overlay.png
#   - data/output/ch01/figures/fig_index_facets.png
# =========================

library(tidyverse)
library(lubridate)

# ---- Paths ----
index_dir <- file.path("data", "transformed", "ch01", "index")
fig_dir   <- file.path("data", "output", "ch01", "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

index_files <- list.files(index_dir, pattern = "_index\\.csv$", full.names = TRUE)

# ---- Read & combine ----
index_data <- bind_rows(lapply(index_files, function(file) {
  df <- read_csv(file, show_col_types = FALSE)

  # standardize column names across files
  names(df)[names(df) == "Index"] <- "index_value"

  df$category <- tools::file_path_sans_ext(basename(file)) %>%
    gsub("_index$", "", .)

  df
}))

index_data <- index_data %>%
  mutate(Date = as.Date(Date))

# ---- Min-max scaling within category ----
index_data_scaled <- index_data %>%
  group_by(category) %>%
  mutate(
    scaled_index = (index_value - min(index_value, na.rm = TRUE)) /
      (max(index_value, na.rm = TRUE) - min(index_value, na.rm = TRUE))
  ) %>%
  ungroup()

# ---- Figure 1: overlay ----
p1 <- ggplot(index_data_scaled, aes(x = Date, y = scaled_index, color = category)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Google Trends: Scaled Attention Index across Categories",
    x = "Month",
    y = "Scaled Index",
    color = "Category"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")

ggsave(
  filename = file.path(fig_dir, "fig_index_overlay.png"),
  plot = p1,
  width = 10,
  height = 6,
  dpi = 300
)

# ---- Figure 2: facets ----
p2 <- ggplot(index_data_scaled, aes(x = Date, y = scaled_index)) +
  geom_line(linewidth = 0.6) +
  facet_wrap(~ category, scales = "free_y") +
  labs(
    title = "Google Trends: Attention Index (Scaled, by Category)",
    x = "Month",
    y = "Scaled Index"
  ) +
  theme_minimal(base_size = 13)

ggsave(
  filename = file.path(fig_dir, "fig_index_facets.png"),
  plot = p2,
  width = 11,
  height = 7,
  dpi = 300
)
