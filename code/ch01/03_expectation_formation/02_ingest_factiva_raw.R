# ==========================================================
#
# Purpose:
#   Ingest raw Factiva news-count exports (annual frequency) and convert them into a monthly series for Chapter 1 analyses.
#
# Inputs:
#   data/raw/*_factiva.csv
#     - Factiva CSV exports with 4 header lines
#     - Year extracted from the trailing 4 digits in DateRange
#
# Outputs:
#   data/derived/news/factiva_monthly/*_factiva_monthly.csv
#
# Notes:
#   Factiva exports are not tracked in git. See data/raw/README.md
#   for source and file format requirements.
# ==========================================================

library(tidyverse)
library(lubridate)
library(readr)

# ===== Paths =====
input_folder  <- "data/raw"
output_folder <- "data/derived/news/factiva_monthly"

dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

# ===== Identify Factiva files =====
file_list <- list.files(
  path = input_folder,
  pattern = "_factiva\\.csv$",
  full.names = TRUE
)

# ===== Processing function =====
process_factiva_file <- function(file_path) {

  raw <- read_csv(
    file_path,
    skip = 4,
    col_names = c("DateRange", "DocumentCount"),
    show_col_types = FALSE
  )

  raw_clean <- raw %>%
    mutate(
      Year = as.numeric(str_extract(DateRange, "\\d{4}$")),
      DocumentCount = as.numeric(DocumentCount),
      NewsCount_Monthly = DocumentCount / 12
    ) %>%
    filter(!is.na(Year)) %>%
    select(Year, NewsCount_Monthly)

  # Expand each year into 12 months (equal allocation)
  monthly <- raw_clean %>%
    uncount(weights = 12) %>%
    group_by(Year) %>%
    mutate(
      Month = 1:12,
      Date = as.Date(sprintf("%d-%02d-01", Year, Month))
    ) %>%
    ungroup() %>%
    relocate(Date, Year, Month, NewsCount_Monthly)

  monthly
}

# ===== Batch processing =====
for (file_path in file_list) {

  product_name <- tools::file_path_sans_ext(basename(file_path))
  out_path <- file.path(output_folder, paste0(product_name, "_monthly.csv"))

  monthly_data <- process_factiva_file(file_path)
  write_csv(monthly_data, out_path)

  message("Saved: ", out_path)
}
