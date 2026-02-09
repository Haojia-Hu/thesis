# =============================================================================
# Purpose
#   Convert annual CBSA population levels (July 1 estimates) into a monthly
#   CBSA panel (2018–2024) via linear interpolation, then construct:
#     - net_mig_month  : monthly change in population (proxy)
#     - mig_rate_month : monthly change rate (proxy)
#
# Inputs (raw; not version controlled)
#   data/raw/ch02/control_variables/cbsa_population_18_24.xlsx
#
# Outputs (generated; not version controlled)
#   data/transformed/ch02/control_variables/cbsa_migration_monthly.csv
# =============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(zoo)
  library(stringr)
  library(here)
})

# ---- Paths ----
in_file <- here("data", "raw", "ch02", "control_variables", "cbsa_population_18_24.xlsx")

out_dir  <- here("data", "transformed", "ch02", "control_variables")
out_file <- file.path(out_dir, "cbsa_migration_monthly.csv")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Parameters ----
yrs <- 2018:2024

# The annual population is a July 1 estimate; anchor to July and interpolate monthly
anchor_month <- 7

# ---- Read raw ----
pop_raw <- read_excel(in_file)
names(pop_raw) <- tolower(gsub("\\s+", "_", names(pop_raw)))

# Identify CBSA code column (robust to different headers)
cbsa_col <- if ("cbsa_code" %in% names(pop_raw)) {
  "cbsa_code"
} else {
  cand <- names(pop_raw)[grepl("^cbsa", names(pop_raw))]
  if (length(cand) == 0) stop("Cannot find a CBSA code column. Please check the input file headers.")
  cand[1]
}

# Identify optional name/title column (if present)
name_col <- if ("cbsa_title" %in% names(pop_raw)) {
  "cbsa_title"
} else if ("area" %in% names(pop_raw)) {
  "area"
} else {
  NA_character_
}

# Identify year columns by extracting 20xx from column names
extract_year <- function(x) suppressWarnings(as.integer(str_extract(x, "20\\d{2}")))
nm <- names(pop_raw)
nm_year <- sapply(nm, extract_year)

year_cols <- nm[!is.na(nm_year) & nm_year %in% yrs]
if (length(year_cols) == 0) stop("No year columns found for 2018–2024. Please check the input file.")

# Keep only needed columns + standardize CBSA code to 5 digits
keep_cols <- c(cbsa_col, if (!is.na(name_col)) name_col, year_cols)

pop_clean <- pop_raw %>%
  select(all_of(keep_cols)) %>%
  filter(!is.na(.data[[cbsa_col]])) %>%
  mutate(
    cbsa_code = sprintf("%05d", as.integer(.data[[cbsa_col]]))
  ) %>%
  filter(!is.na(as.integer(cbsa_code)))

# Wide -> long (annual)
pop_long <- pop_clean %>%
  pivot_longer(
    cols = all_of(year_cols),
    names_to  = "year_raw",
    values_to = "population"
  ) %>%
  mutate(
    year       = extract_year(year_raw),
    population = as.numeric(gsub(",", "", as.character(population)))
  ) %>%
  filter(!is.na(year), year %in% yrs)

if (!is.na(name_col)) {
  pop_long <- pop_long %>% select(cbsa_code, all_of(name_col), year, population)
} else {
  pop_long <- pop_long %>% select(cbsa_code, year, population)
}

# Anchor annual levels to July and interpolate to monthly
pop_yearmon <- pop_long %>%
  mutate(yearmon_anchor = as.yearmon(sprintf("%04d-%02d", year, anchor_month))) %>%
  transmute(
    cbsa_code,
    yearmon = yearmon_anchor,
    population
  )

pop_monthly <- pop_yearmon %>%
  group_by(cbsa_code) %>%
  complete(
    yearmon = seq(as.yearmon("2018-01"), as.yearmon("2024-12"), by = 1/12),
    fill = list(population = NA_real_)
  ) %>%
  arrange(cbsa_code, yearmon) %>%
  mutate(
    population = na.approx(population, na.rm = FALSE)
  ) %>%
  ungroup() %>%
  mutate(yearmon = format(yearmon, "%Y-%m"))

# Construct monthly changes (proxy)
pop_monthly <- pop_monthly %>%
  group_by(cbsa_code) %>%
  arrange(yearmon, .by_group = TRUE) %>%
  mutate(
    population_lag = lag(population, 1),
    net_mig_month  = population - population_lag,
    mig_rate_month = net_mig_month / population_lag
  ) %>%
  ungroup() %>%
  select(cbsa_code, yearmon, population, net_mig_month, mig_rate_month)

# ---- Save ----
write_csv(pop_monthly, out_file)

