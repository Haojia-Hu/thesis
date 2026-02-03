# ==========================================================
# Purpose:
#   Build the monthly category-by-date panel dataset used as input for Chapter 1 regressions (e.g., Local Projections).
#
# Inputs (transformed):
#   1) Attention (first-differenced)
#      - data/transformed/ch01/diff/*_diff.csv
#        Each file contains: Date, diff_index
#
#   2) Category CPI index (level)
#      - data/transformed/ch01/cpi_category/*_cpi.csv
#        Each file contains: Date, Product, CPI
#
#   3) News volume (Factiva monthly)
#      - data/transformed/ch01/controls/news/*_monthly.csv
#        Each file contains: Date, (news measure in 2nd column)
#
#   4) Macro controls (level)
#      - data/transformed/ch01/controls/macro/*.csv
#        Each file contains: Date, Value
#
# Transformations performed here (panel stage):
#   - Macro: first differences (D_<var>)
#   - CPI: PriceChange, Volatility, then Diff_PriceChange and Diff_Volatility
#   - News: HP filter detrending + first difference of cycle (Diff_News)
#
# Output:
#   - data/transformed/ch01/panel/panel_data.csv
# ==========================================================

library(tidyverse)
library(zoo)
library(lubridate)
library(mFilter)
library(tools)

# ========== 1. Setting paths (repo) ==========
diff_path  <- "data/transformed/ch01/diff"
cpi_path   <- "data/transformed/ch01/cpi_category"
news_path  <- "data/transformed/ch01/controls/news"
macro_path <- "data/transformed/ch01/controls/macro"

out_dir  <- "data/transformed/ch01/panel"
out_file <- file.path(out_dir, "panel_data.csv")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ========== 2. File names ==========
file_map <- tibble::tibble(
  category = c("apparel", "communication", "education", "energy", "food",
               "housing", "medical_care", "personal_care", "recreation", "tobacco", "transportation"),
  attention_file = c("apparel_diff.csv", "communication_diff.csv", "education_diff.csv", "energy_diff.csv", "food_diff.csv",
                     "housing_diff.csv", "medical care_diff.csv", "personal care_diff.csv", "recreation_diff.csv", "tobacco_diff.csv", "transportation_diff.csv"),
  cpi_file = c("Apparel_cpi.csv", "Communication_cpi.csv", "Education_cpi.csv", "Energy_cpi.csv", "Food_and_beverages_cpi.csv",
               "Housing_cpi.csv", "Medical_care_cpi.csv", "Personal_care_cpi.csv", "Recreation_cpi.csv", "Tobacco_and_smoking_products_cpi.csv", "Transportation_cpi.csv"),
  news_file = c("apparel_factiva_monthly.csv", "comm_factiva_monthly.csv", "edu_factiva_monthly.csv", "energy_factiva_monthly.csv", "fd_factiva_monthly.csv",
                "house_factiva_monthly.csv", "medical_factiva_monthly.csv", "pc_factiva_monthly.csv", "recreation_factiva_monthly.csv", "tobacco_factiva_monthly.csv", "trans_factiva_monthly.csv")
)

# ========== 3. Macro variables (diff here) ==========
macro_files <- list.files(macro_path, pattern = "\\.csv$", full.names = TRUE)
if (length(macro_files) == 0) stop("No macro files found in: ", macro_path)

macro_list <- map(macro_files, function(path) {
  varname <- tools::file_path_sans_ext(basename(path))

  df <- read_csv(path, col_types = cols()) %>%
    rename(Date = 1, Value = 2) %>%
    mutate(
      Date = as.Date(Date),
      D_value = Value - lag(Value)
    ) %>%
    select(Date, D_value) %>%
    rename(!!paste0("D_", varname) := D_value)

  df
})

macro_df <- reduce(macro_list, full_join, by = "Date") %>%
  arrange(Date)

# ========== 4. Individual categories: attention + CPI + news + macro ==========
build_single_panel <- function(category, att_file, cpi_file, news_file) {

  # -- attention (already differenced upstream) --
  att <- read_csv(file.path(diff_path, att_file), show_col_types = FALSE) %>%
    mutate(Date = as.Date(Date)) %>%
    select(Date, diff_index)

  # -- CPI: build Diff_PriceChange & Diff_Volatility here --
  cpi <- read_csv(file.path(cpi_path, cpi_file), show_col_types = FALSE) %>%
    mutate(Date = as.Date(Date)) %>%
    arrange(Date) %>%
    rename(PriceIndex = 3) %>%
    mutate(
      PriceIndex = as.numeric(gsub(",", "", as.character(PriceIndex))),
      PriceChange = PriceIndex - lag(PriceIndex),
      PriceVolatility = rollapply(PriceIndex, width = 3, FUN = sd, fill = NA, align = "right"),
      Diff_PriceChange = PriceChange - lag(PriceChange),
      Diff_Volatility = PriceVolatility - lag(PriceVolatility)
    ) %>%
    select(Date, Diff_PriceChange, Diff_Volatility)

  # -- News: HP detrend + diff of cycle here --
  news <- read_csv(file.path(news_path, news_file), show_col_types = FALSE) %>%
    mutate(Date = as.Date(Date)) %>%
    arrange(Date)

  hp_result <- hpfilter(news[[2]], freq = 14400)
  news_cycle <- hp_result$cycle

  news_df <- news %>%
    mutate(
      News_Cycle = as.numeric(news_cycle),
      Diff_News = News_Cycle - lag(News_Cycle)
    ) %>%
    select(Date, Diff_News)

  # -- Combine --
  df <- full_join(att, cpi, by = "Date") %>%
    full_join(news_df, by = "Date") %>%
    full_join(macro_df, by = "Date") %>%
    filter(Date >= as.Date("2004-01-01") & Date <= as.Date("2024-12-31")) %>%
    mutate(category = category) %>%
    relocate(Date, category)

  df
}

# ========== 5. Produce panel ==========
panel_data <- pmap_dfr(
  list(
    category = file_map$category,
    att_file = file_map$attention_file,
    cpi_file = file_map$cpi_file,
    news_file = file_map$news_file
  ),
  build_single_panel
)

print(table(panel_data$category))

# ========== 6. Export ==========
write_csv(panel_data, out_file)
