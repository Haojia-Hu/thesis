# ==========================================================
# Purpose:
#   Ingest raw CPI index data by consumption category downloaded from the BLS website and convert them into monthly, analysis-ready CPI series.
#
# Inputs:
#   data/raw/ch01/cpi_category/
#     - CPI category Excel files downloaded from:
#       https://data.bls.gov/PDQWeb/cu
#
# Outputs:
#   data/transformed/ch01/cpi_category/
#     - <Category>_cpi.csv
#
# Notes:
#   Raw CPI Excel files are not tracked in git.
#   Category identification is based on filename keywords.
############################################################

library(tidyverse)
library(lubridate)
library(readxl)

# ===== Paths =====
input_folder  <- "data/raw/ch01/cpi_category"
output_folder <- "data/transformed/ch01/cpi_category"

dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

# ===== Category mapping (filename keyword -> category label) =====
product_map <- c(
  "Apparel"        = "Apparel",
  "Communication"  = "Communication",
  "Education"      = "Education",
  "Energy"         = "Energy",
  "Food"           = "Food and beverages",
  "Housing"        = "Housing",
  "Medical"        = "Medical care",
  "Personal"       = "Personal care",
  "Recreation"     = "Recreation",
  "Tobacco"        = "Tobacco and smoking products",
  "Transportation" = "Transportation"
)

# ===== Identify CPI Excel files =====
cpi_files <- list.files(
  path = input_folder,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

# ===== Processing function =====
process_and_save <- function(file_path) {

  matched_key <- names(product_map)[
    str_detect(basename(file_path), names(product_map))
  ]

  if (length(matched_key) == 0) {
    message("Skipping (no category match): ", basename(file_path))
    return(NULL)
  }

  if (length(matched_key) > 1) {
    stop("Multiple category matches for file: ", basename(file_path))
  }

  product <- product_map[matched_key]
  product_clean <- str_replace_all(product, " ", "_")

  df <- read_excel(file_path, skip = 11) %>%
    select(-starts_with("HALF")) %>%
    pivot_longer(
      -Year,
      names_to  = "Month",
      values_to = "CPI"
    ) %>%
    mutate(
      Month   = match(Month, month.abb),
      Date    = as.Date(sprintf("%d-%02d-01", Year, Month)),
      Product = product
    ) %>%
    filter(!is.na(Date), Date <= as.Date("2024-12-01")) %>%
    select(Date, Product, CPI)

  out_path <- file.path(
    output_folder,
    paste0(product_clean, "_cpi.csv")
  )

  write_csv(df, out_path)
  message("Saved: ", out_path)
}

# ===== Batch processing =====
walk(cpi_files, process_and_save)
