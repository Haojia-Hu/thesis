# =============================================================================
# Purpose
#   Combine yearly cleaned HMDA LAR files (2018–2024) into a single loan-level
#   dataset and select fixed-rate mortgage samples by loan term.
#   This step prepares pooled HMDA samples for constructing the monthly
#   outstanding mortgage rate panel.
#
# Inputs
#   data/transformed/ch02/hmda/hmda_clean_{YEAR}.csv
#   where YEAR ∈ {2018, …, 2024}
#
# Outputs
#   data/transformed/ch02/hmda/hmda_30y_clean.csv
#   data/transformed/ch02/hmda/hmda_15y_clean.csv
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(here)
})

# ---- Paths (repo-relative) ----
input_dir  <- here("data", "transformed", "ch02", "hmda_clean")
output_dir <- here("data", "transformed", "ch02", "combined_hmda")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Locate yearly cleaned files ----
file_list <- list.files(
  input_dir,
  pattern = "^hmda_clean_[0-9]{4}\\.csv$",
  full.names = TRUE
)

if (length(file_list) == 0) {
  stop("No yearly HMDA clean files found in: ", input_dir)
}

message("Merging ", length(file_list), " yearly HMDA clean files...")

# ---- Read and combine ----
hmda_all <- rbindlist(
  lapply(file_list, fread),
  fill = TRUE
)

message("Total loan-level observations: ",
        format(nrow(hmda_all), big.mark = ","))

# ---- Select loan terms ----
# 30-year fixed-rate mortgages (approx. 360 months)
hmda_30y <- hmda_all[loan_term >= 350 & loan_term <= 370]

# 15-year fixed-rate mortgages (kept for reference / robustness)
hmda_15y <- hmda_all[loan_term >= 170 & loan_term <= 190]

# ---- Output ----
out_30y <- file.path(output_dir, "hmda_30y_clean.csv")
out_15y <- file.path(output_dir, "hmda_15y_clean.csv")

fwrite(hmda_30y, out_30y)
fwrite(hmda_15y, out_15y)
