# =============================================================================
# Purpose
#   Clean FFIEC HMDA public Loan/Application Records (LAR) files by year and
#   retain only the subset of observations/columns needed for Chapter 2:
#   - originated loans
#   - first lien
#   - non-business/commercial purpose
#   - non-open-end line of credit (exclude HELOC)
#   - non-reverse mortgages
#   - fixed-rate style loans (intro_rate_period == 0 or NA)
#
# Inputs (NOT version controlled)
#   data/raw/ch02/hmda_lar/{YEAR}_public_lar_csv.csv
#   Years used in this project: 2018–2024
#
# Outputs (generated, NOT version controlled)
#   data/transformed/ch02/01_hmda_clean/{YEAR}_hmda_clean.csv
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(here)
})

# ---- Paths (repo-relative) ----
raw_dir   <- here("data", "raw", "ch02", "hmda_lar")
clean_dir <- here("data", "transformed", "ch02", "hmda_clean")

dir.create(clean_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Columns to keep (minimum needed for Ch2) ----
cols_keep <- c(
  # Location & time
  "activity_year", "state_code", "county_code", "derived_msa_md",

  # Rate-gap core
  "loan_amount", "interest_rate", "loan_term",

  # Filters
  "action_taken", "lien_status", "business_or_commercial_purpose",
  "open_end_line_of_credit", "reverse_mortgage",
  "intro_rate_period", "derived_loan_product_type",
  "loan_purpose", "occupancy_type",

  # Controls / covariates used later
  "debt_to_income_ratio", "loan_to_value_ratio", "property_value",
  "tract_to_msa_income_percentage"
)

# ---- Helpers ----
numify <- function(x) suppressWarnings(as.numeric(x))

extract_year <- function(path) {
  # expects file names like "2018_public_lar_csv.csv"
  bn <- basename(path)
  sub("_public_lar_csv\\.csv$", "", bn)
}

hmda_clean_one_year <- function(file_path) {
  year <- extract_year(file_path)
  message("Processing HMDA LAR year: ", year)

  # Read only required columns for speed/memory
  dt <- fread(
    file_path,
    select = cols_keep,
    na.strings = c("", "NA", "Exempt")
  )

  # Convert key numeric fields
  dt[, interest_rate := numify(interest_rate)]
  dt[, loan_amount   := numify(loan_amount)]
  dt[, loan_term     := numify(loan_term)]

  # ---- Main sample restrictions ----
  # action_taken: 1 = Loan originated
  # lien_status: 1 = First lien
  # business_or_commercial_purpose: 2 = Not primarily for business/commercial purpose
  # open_end_line_of_credit: 2 = Not open-end
  # reverse_mortgage: 2 = Not reverse
  dt <- dt[
    action_taken == 1 &
      lien_status == 1 &
      business_or_commercial_purpose == 2 &
      open_end_line_of_credit == 2 &
      reverse_mortgage == 2
  ]

  # Fixed-rate style screen (closer to PMMS 30Y FRM)
  # keep loans with intro_rate_period == 0 or NA
  dt <- dt[is.na(intro_rate_period) | numify(intro_rate_period) == 0]

  # Keep only valid/positive core variables
  dt <- dt[
    !is.na(interest_rate) & interest_rate > 0 &
      !is.na(loan_amount) & loan_amount > 0 &
      !is.na(loan_term)   & loan_term > 0
  ]

  # Drop filter-only columns after filtering
  cols_drop <- c(
    "action_taken", "lien_status", "business_or_commercial_purpose",
    "open_end_line_of_credit", "reverse_mortgage", "intro_rate_period"
  )
  dt[, (cols_drop) := NULL]

  # Output
  out_csv <- file.path(clean_dir, paste0("hmda_clean_", year, ".csv"))
  fwrite(dt, out_csv)

  message("confirmed", year, " done: ", format(nrow(dt), big.mark = ","), " rows saved -> ", out_csv)
  invisible(out_csv)
}

# ---- Batch over files ----
file_list <- list.files(
  raw_dir,
  pattern = "_public_lar_csv\\.csv$",
  full.names = TRUE
)

if (length(file_list) == 0) {
  stop("No HMDA LAR files found in: ", raw_dir,
       "\nExpected files like: 2018_public_lar_csv.csv ... 2024_public_lar_csv.csv")
}

# Optional: enforce year range 2018–2024 for this project
years <- extract_year(file_list)
keep <- years %in% as.character(2018:2024)
file_list <- file_list[keep]

for (f in file_list) {
  hmda_clean_one_year(f)
}

message("All done.")
