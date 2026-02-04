# ==========================================================
# Build filtered panel data (exclude selected categories)
#
# Purpose:
#   Construct a category-level monthly panel dataset for LP robustness checks by excluding selected categories.
#
# Input:
#   - data/transformed/ch01/diff/*_diff.csv
#   - data/transformed/ch01/cpi_category/*_cpi.csv
#   - data/transformed/ch01/controls/news_volume/*_monthly.csv
#   - data/transformed/ch01/controls/macro_controls/*.csv
#
# Output:
#   - data/transformed/ch01/panel/panel_data_filtered.csv
#
# Notes:
#   This script excludes:
#     - transportation
#     - energy
#     - communication
# ==========================================================

library(tidyverse)
library(zoo)
library(lubridate)
library(mFilter)
library(tools)
library(purrr)

# ==========================
# 0) Paths
# ==========================
diff_path  <- "data/transformed/ch01/diff"
cpi_path   <- "data/transformed/ch01/cpi_category"
news_path  <- "data/transformed/ch01/controls/news_volume"
macro_path <- "data/transformed/ch01/controls/macro_controls"

out_file <- "data/transformed/ch01/panel/panel_data_filtered_excl_transport_energy_comm.csv"
dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)

# ==========================
# 1) File map (baseline list)
# ==========================
file_map <- tibble::tibble(
  category = c("apparel", "communication", "education", "energy", "food",
               "housing", "medical_care", "personal_care", "recreation", "tobacco", "transportation"),
  attention_file = c("apparel_diff.csv", "communication_diff.csv", "education_diff.csv", "energy_diff.csv", "food_diff.csv",
                     "housing_diff.csv", "medical_care_diff.csv", "personal_care_diff.csv", "recreation_diff.csv", "tobacco_diff.csv", "transportation_diff.csv"),
  cpi_file = c("Apparel_cpi.csv", "Communication_cpi.csv", "Education_cpi.csv", "Energy_cpi.csv", "Food_and_beverages_cpi.csv",
               "Housing_cpi.csv", "Medical_care_cpi.csv", "Personal_care_cpi.csv", "Recreation_cpi.csv", "Tobacco_and_smoking_products_cpi.csv", "Transportation_cpi.csv"),
  news_file = c("apparel_factiva_monthly.csv", "comm_factiva_monthly.csv", "edu_factiva_monthly.csv", "energy_factiva_monthly.csv", "fd_factiva_monthly.csv",
                "house_factiva_monthly.csv", "medical_factiva_monthly.csv", "pc_factiva_monthly.csv", "recreation_factiva_monthly.csv", "tobacco_factiva_monthly.csv", "trans_factiva_monthly.csv")
)

# Exclude selected categories (robustness design)
excluded <- c("transportation", "energy", "communication")

file_map_filtered <- file_map %>%
  filter(!category %in% excluded)

# ==========================
# 2) Macro variables: first-difference and merge by Date
# ==========================
macro_files <- list.files(macro_path, pattern = "\\.csv$", full.names = TRUE)

macro_list <- map(macro_files, function(path) {
  varname <- tools::file_path_sans_ext(basename(path))
  read_csv(path, show_col_types = FALSE) %>%
    rename(Date = 1, Value = 2) %>%
    mutate(
      Date = as.Date(Date),
      D_value = Value - lag(Value)
    ) %>%
    select(Date, D_value) %>%
    rename(!!paste0("D_", varname) := D_value)
})

macro_df <- reduce(macro_list, full_join, by = "Date") %>%
  arrange(Date)

# ==========================
# 3) Build single-category panel block
# ==========================
build_single_panel <- function(category, att_file, cpi_file, news_file) {

  # Attention: already first-differenced file
  att <- read_csv(file.path(diff_path, att_file), show_col_types = FALSE) %>%
    mutate(Date = as.Date(Date)) %>%
    select(Date, diff_index)

  # CPI: build Diff_PriceChange and Diff_Volatility
  cpi <- read_csv(file.path(cpi_path, cpi_file), show_col_types = FALSE) %>%
    mutate(Date = as.Date(Date)) %>%
    arrange(Date) %>%
    rename(PriceIndex = 3) %>%
    mutate(
      PriceIndex = as.numeric(gsub(",", "", as.character(PriceIndex))),
      PriceChange = PriceIndex - lag(PriceIndex),
      PriceVolatility = rollapply(PriceIndex, width = 3, FUN = sd, fill = NA, align = "right"),
      Diff_PriceChange = PriceChange - lag(PriceChange),
      Diff_Volatility  = PriceVolatility - lag(PriceVolatility)
    ) %>%
    select(Date, Diff_PriceChange, Diff_Volatility)

  # News: HP-filter cycle and first difference
  news <- read_csv(file.path(news_path, news_file), show_col_types = FALSE) %>%
    mutate(Date = as.Date(Date)) %>%
    arrange(Date)

  hp_result <- hpfilter(news[[2]], freq = 14400)
  news_df <- news %>%
    mutate(
      News_Cycle = as.numeric(hp_result$cycle),
      Diff_News  = News_Cycle - lag(News_Cycle)
    ) %>%
    select(Date, Diff_News)

  # Combine
  df <- full_join(att, cpi, by = "Date") %>%
    full_join(news_df, by = "Date") %>%
    full_join(macro_df, by = "Date") %>%
    filter(Date >= as.Date("2004-01-01") & Date <= as.Date("2024-12-31")) %>%
    mutate(category = category) %>%
    relocate(Date, category)

  df
}

# ==========================
# 4) Build filtered panel and export
# ==========================
panel_df_filtered <- pmap_dfr(
  list(
    category = file_map_filtered$category,
    att_file = file_map_filtered$attention_file,
    cpi_file = file_map_filtered$cpi_file,
    news_file = file_map_filtered$news_file
  ),
  build_single_panel
)

write_csv(panel_df_filtered, out_file)

print(table(panel_df_filtered$category))
