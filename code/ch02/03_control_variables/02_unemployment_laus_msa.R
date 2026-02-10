# ============================================================
# Construct monthly CBSA-level unemployment rates from BLS LAUS
# Output: data/transformed/ch02/control_variables/laus_unemployment_msa.csv
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(tidyr)
})

# ----------------------------
# Paths (edit only this block)
# ----------------------------
# Raw LAUS folder (NOT committed to Git)
# Expected files:
#   la.area.txt
#   la.series.txt
#   la.measure.txt
#   la.data.60.Metro.txt
raw_dir <- file.path("data", "raw", "laus")

# Output folder
out_dir <- file.path("data", "transformed", "ch02", "control_variables")
out_file <- file.path(out_dir, "laus_unemployment_msa.csv")

# Create output directory if missing
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ----------------------------
# Helper: safe file existence
# ----------------------------
required_files <- c("la.area.txt", "la.series.txt", "la.measure.txt", "la.data.60.Metro.txt")
missing_files <- required_files[!file.exists(file.path(raw_dir, required_files))]
if (length(missing_files) > 0) {
  stop(
    "Missing required raw LAUS files in: ", raw_dir, "\n",
    "Missing:\n - ", paste(missing_files, collapse = "\n - "), "\n\n",
    "Download from BLS LAUS time-series repository and place them in data/raw/laus/."
  )
}

# ----------------------------
# Read raw LAUS files (all as character)
# ----------------------------
laus_area <- read_tsv(file.path(raw_dir, "la.area.txt"), col_types = cols(.default = "c"))
laus_series <- read_tsv(file.path(raw_dir, "la.series.txt"), col_types = cols(.default = "c"))
laus_measure <- read_tsv(file.path(raw_dir, "la.measure.txt"), col_types = cols(.default = "c"))
laus_data <- read_tsv(file.path(raw_dir, "la.data.60.Metro.txt"), col_types = cols(.default = "c"))

# ----------------------------
# 1) Keep MSA areas and extract CBSA
# ----------------------------
# area_type_code == "B" corresponds to Metropolitan Statistical Areas (MSAs) in LAUS.
# CBSA code is embedded in area_code; we extract digits 5-9 (5-digit CBSA).
laus_area_b <- laus_area %>%
  filter(area_type_code == "B") %>%
  mutate(
    cbsa_code = substr(area_code, 5, 9),
    msa_name  = area_text
  ) %>%
  select(area_code, cbsa_code, msa_name)

# ----------------------------
# 2) Identify unemployment rate measure_code
# ----------------------------
measure_unemp <- laus_measure %>%
  filter(str_detect(tolower(measure_text), "unemployment rate")) %>%
  select(measure_code) %>%
  distinct()

if (nrow(measure_unemp) == 0) {
  stop("No LAUS measure_code matched 'unemployment rate' in la.measure.txt.")
}

# ----------------------------
# 3) Filter series: unemployment rate + (seasonal == "U")
# ----------------------------
# NOTE: This keeps series where seasonal == "U" as in the user's original script.
# If you intend seasonally adjusted series, verify LAUS seasonal codes and modify here.
laus_series_sel <- laus_series %>%
  filter(seasonal == "U") %>%
  semi_join(measure_unemp, by = "measure_code") %>%
  select(series_id, seasonal, area_code, measure_code) %>%
  distinct()

if (nrow(laus_series_sel) == 0) {
  stop("No LAUS series matched the filters (seasonal == 'U' AND unemployment rate).")
}

# ----------------------------
# 4) Merge and construct CBSA-by-month unemployment rate
# ----------------------------
dat_unemp <- laus_data %>%
  semi_join(laus_series_sel, by = "series_id") %>%
  left_join(laus_series_sel, by = "series_id") %>%
  left_join(laus_area_b, by = "area_code") %>%
  # Keep monthly M01-M12 only, exclude annual average (M13)
  filter(str_detect(period, "^M\\d{2}$"), period != "M13") %>%
  mutate(
    year  = as.integer(year),
    month = as.integer(str_remove(period, "M")),
    value = suppressWarnings(as.numeric(value))
  ) %>%
  filter(year >= 2018, year <= 2024) %>%
  filter(!is.na(value)) %>%
  mutate(yearmon = sprintf("%04d-%02d", year, month)) %>%
  select(yearmon, cbsa_code, msa_name, unemployment_rate = value) %>%
  arrange(yearmon, cbsa_code)

# ----------------------------
# QA checks
# ----------------------------
# (i) CBSA extraction check
chk_missing_cbsa <- dat_unemp %>% filter(is.na(cbsa_code) | cbsa_code == "")
if (nrow(chk_missing_cbsa) > 0) {
  warning(
    "Some rows have missing/empty cbsa_code after extraction from area_code.\n",
    "Showing first 10 problematic rows:"
  )
  print(head(chk_missing_cbsa, 10))
}

# (ii) uniqueness check: one obs per CBSA-month
dup_check <- dat_unemp %>%
  count(yearmon, cbsa_code) %>%
  filter(n > 1)

if (nrow(dup_check) > 0) {
  warning(
    "Duplicate CBSA-month observations found. Showing first 10 duplicates:"
  )
  print(head(dup_check, 10))
}

# ----------------------------
# Write output
# ----------------------------
write_csv(dat_unemp, out_file)
message("Wrote: ", out_file)
message("Rows: ", nrow(dat_unemp), " | Unique CBSAs: ", n_distinct(dat_unemp$cbsa_code))
