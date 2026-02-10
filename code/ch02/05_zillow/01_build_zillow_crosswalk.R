# ============================================================
# Chapter 2 - Zillow
# Build Zillow RegionID -> CBSA crosswalk
#
# Input (raw):
#   data/raw/ch02/zillow/Raw_zillow_MSA_crosswalk.xlsx
#
# Output (transformed):
#   data/transformed/ch02/zillow/zillow_crosswalk.csv
# ============================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(stringr)
  library(readr)
})

# ----------------------------
# Paths
# ----------------------------
in_file <- file.path("data", "raw", "ch02", "zillow", "Raw_zillow_MSA_crosswalk.xlsx")

out_dir <- file.path("data", "transformed", "ch02", "zillow")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

out_file <- file.path(out_dir, "zillow_crosswalk.csv")

if (!file.exists(in_file)) {
  stop("Missing raw Zillow crosswalk: ", in_file, call. = FALSE)
}

# ----------------------------
# Read
# ----------------------------
raw <- read_excel(in_file)

# Drop empty columns
raw <- raw %>% select(where(~ !all(is.na(.x) | .x == "")))

# Keep only mapping columns (must exist in the raw file)
required_cols <- c("RegionID", "cbsa_code")
missing_cols <- setdiff(required_cols, names(raw))
if (length(missing_cols) > 0) {
  stop(
    "Missing required column(s) in raw crosswalk: ",
    paste(missing_cols, collapse = ", "),
    call. = FALSE
  )
}

df <- raw %>%
  select(RegionID, cbsa_code) %>%
  mutate(
    RegionID  = trimws(gsub("[^[:alnum:][:space:]-]", "", as.character(RegionID))),
    cbsa_code = trimws(gsub("[^[:alnum:][:space:]-]", "", as.character(cbsa_code)))
  ) %>%
  filter(!is.na(RegionID), RegionID != "", !is.na(cbsa_code), cbsa_code != "") %>%
  mutate(
    # enforce 5-digit CBSA as string
    cbsa_code = str_pad(str_extract(cbsa_code, "\\d+"), 5, pad = "0")
  ) %>%
  filter(!is.na(cbsa_code), str_detect(cbsa_code, "^\\d{5}$"))

# Quick duplicate check (informative)
dup <- df %>% count(RegionID) %>% filter(n > 1)
if (nrow(dup) > 0) {
  message("Warning: duplicate RegionID mappings found. Keeping first occurrence. Examples:")
  print(head(dup, 10))
}

# Enforce unique RegionID (keep first occurrence)
df <- df %>% distinct(RegionID, .keep_all = TRUE)

# Write
write_csv(df, out_file)
cat("Wrote:", out_file, "\n",
    "Rows:", nrow(df),
    "| Unique RegionID:", n_distinct(df$RegionID),
    "| Unique CBSA:", n_distinct(df$cbsa_code), "\n")01_build_zillow_crosswalk.R
