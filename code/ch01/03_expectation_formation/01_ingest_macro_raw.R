############################################################
# Purpose:
#   Ingest and clean raw macroeconomic series used as controls
#   in Chapter 1 analyses (including Local Projections).
#
#   - Reads raw macro CSV files downloaded from FRED
#   - Standardizes variable names and date formats
#   - Restricts the sample period
#   - Aggregates weekly mortgage rates to monthly frequency
#
# Inputs:
#   data/raw/ (CSV files named by FRED series ID)
#
# Outputs:
#   data/derived/macro/*.csv
#
# Notes:
#   Raw macro data are not included in the repository.
#   See data/raw/README.md for required series and sources.
############################################################

# ===== Packages =====
library(tidyverse)
library(lubridate)

# ===== Paths (modify if needed) =====
input_folder  <- "data/raw"
output_folder <- "data/derived/macro"

dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

# ===== Mapping: FRED filename -> cleaned variable name =====
rename_map <- list(
  "DSPIC96.csv"      = "RDI",
  "UMCSENT.csv"      = "ConsumerSent",
  "UNRATE.csv"       = "Unemployment",
  "USEPUINDXM.csv"   = "EPU",
  "CPIAUCSL_PC1.csv" = "CpiAgg",
  "MICH.csv"         = "InflationExp"
)

# ===== Helper function: clean monthly macro series =====
clean_macro_file <- function(file_path) {

  file_name <- basename(file_path)
  var_name  <- rename_map[[file_name]]

  if (is.null(var_name)) return(NULL)

  df <- read_csv(file_path, show_col_types = FALSE) %>%
    rename(Date = 1) %>%
    mutate(Date = ymd(Date)) %>%
    filter(
      Date >= as.Date("2000-01-01"),
      Date <= as.Date("2024-12-01")
    ) %>%
    drop_na() %>%
    rename(!!var_name := 2)

  out_path <- file.path(output_folder, paste0(var_name, ".csv"))
  write_csv(df, out_path)
}

# ===== Process all monthly macro files =====
file_list <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)
walk(file_list, clean_macro_file)

# ===== Weekly mortgage rate: aggregate to monthly =====
mortgage_path <- file.path(input_folder, "MORTGAGE30US.csv")

if (file.exists(mortgage_path)) {

  mortgage_raw <- read_csv(mortgage_path, show_col_types = FALSE) %>%
    mutate(Date = as.Date(observation_date)) %>%
    rename(Rate = MORTGAGE30US)

  mortgage_monthly <- mortgage_raw %>%
    mutate(YearMonth = floor_date(Date, "month")) %>%
    group_by(YearMonth) %>%
    summarise(MortgageRate = mean(Rate, na.rm = TRUE), .groups = "drop") %>%
    rename(Date = YearMonth)

  write_csv(
    mortgage_monthly,
    file.path(output_folder, "Mortgage.csv")
  )
}
