# =============================================================================
# Purpose
#   Construct a monthly shift-share IV for mortgage lock-in analysis:
#     1) NatShock_level: residual from regressing monthly PMMS 30Y FRM on GS10
#     2) Exposure (CBSA-level): PCA-based index from HMDA rate-bin shares
#        using an exposure window with optional half-life decay
#     3) Z_bartik_level = Exposure × NatShock_level
#        (optional) Z_bartik_cum = Exposure × CumShock
#
# Inputs (not version controlled)
#   Raw:
#     data/raw/ch02/pmms/historicalweeklydata.xlsx      (PMMS weekly workbook)
#     data/raw/ch02/gs10/GS10.csv                       (10Y Treasury yield, FRED)
#   Transformed:
#     data/transformed/ch02/hmda/hmda_30y_clean.csv     (HMDA 30Y loan-level sample)
#
# Outputs
#   data/transformed/ch02/rate_gap/ss_iv.csv
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(stringr)
})

# Optional but nice for repo-relative paths
suppressPackageStartupMessages({
  library(here)
})

# ---- Paths ----
pmms_file <- here("data", "raw", "ch02", "pmms", "historicalweeklydata.xlsx")
gs10_file <- here("data", "raw", "ch02", "gs10", "GS10.csv")
hmda_file <- here("data", "transformed", "ch02", "hmda", "hmda_30y_clean.csv")

out_dir <- here("data", "transformed", "ch02", "rate_gap")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "ss_iv.csv")

# ---- Parameters (match your draft defaults) ----
expo_year_min   <- 2018
expo_year_max   <- 2021
half_life_years <- 5
ref_year        <- 2021

bin_edges  <- c(-Inf, 3, 4, 5, 6, Inf)
bin_labels <- c("lt3", "3to4", "4to5", "5to6", "ge6")

# Weekly PMMS window (as used elsewhere)
pmms_start <- as.Date("2018-01-04")
pmms_end   <- as.Date("2024-12-26")

# ---- Helper: robust date parsing for PMMS "Week" ----
to_Date_excel_mixed <- function(v) {
  if (is.numeric(v)) {
    return(as.Date(v, origin = "1899-12-30"))
  }
  v_chr <- as.character(v)
  res <- as.Date(rep(NA_real_, length(v_chr)), origin = "1970-01-01")

  idx_serial <- grepl("^\\d{5,}$", v_chr)
  if (any(idx_serial)) {
    res[idx_serial] <- as.Date(as.numeric(v_chr[idx_serial]), origin = "1899-12-30")
  }

  idx_other <- which(!idx_serial)
  if (length(idx_other)) {
    tmp <- suppressWarnings(ymd(v_chr[idx_other]))
    bad <- is.na(tmp)
    if (any(bad)) {
      tmp[bad] <- suppressWarnings(mdy(v_chr[idx_other][bad]))
    }
    res[idx_other] <- tmp
  }
  res
}

# =============================================================================
# 1) NatShock: PMMS monthly residual after controlling for GS10
# =============================================================================

# Read PMMS weekly (header starts at row 5)
pmms_raw <- read_excel(path = pmms_file, skip = 4, col_names = TRUE)
names(pmms_raw)[1:2] <- c("Week", "FRM30")

pmms_raw <- as.data.table(pmms_raw[, c("Week", "FRM30")])
pmms_raw <- pmms_raw[!(is.na(Week) & is.na(FRM30))]

pmms_raw[, Week := to_Date_excel_mixed(Week)]
pmms_raw <- pmms_raw[!is.na(Week)]
pmms_raw[, FRM30 := as.numeric(FRM30)]
pmms_raw <- pmms_raw[!is.na(FRM30)]

pmms_raw <- pmms_raw[Week >= pmms_start & Week <= pmms_end]

# Weekly -> Monthly average
pmms_raw[, `:=`(eval_year = year(Week), eval_month = month(Week))]
pmms_monthly <- pmms_raw[
  eval_year >= 2018 & eval_year <= 2024,
  .(pmms_30y = mean(FRM30, na.rm = TRUE)),
  by = .(eval_year, eval_month)
][order(eval_year, eval_month)]

pmms_monthly[, date := as.Date(sprintf("%d-%02d-01", eval_year, eval_month))]

# Read GS10 (FRED)
gs10_raw <- read_csv(
  gs10_file,
  col_types = cols(
    observation_date = col_character(),
    GS10 = col_double()
  )
)

gs10_monthly <- gs10_raw %>%
  mutate(date = ymd(observation_date)) %>%
  mutate(date = floor_date(date, unit = "month")) %>%
  arrange(date) %>%
  filter(date >= ymd("2018-01-01") & date <= ymd("2024-12-31")) %>%
  transmute(date, gs10 = as.numeric(GS10))

# Merge & regress: pmms_30y ~ gs10
shock_data <- pmms_monthly %>%
  inner_join(gs10_monthly, by = "date") %>%
  arrange(date)

model_lvl <- lm(pmms_30y ~ gs10, data = shock_data)

shock_monthly <- shock_data %>%
  mutate(NatShock_level = resid(model_lvl)) %>%
  transmute(
    date = as.Date(date),
    ym   = format(date, "%Y-%m"),
    NatShock_level = NatShock_level
  ) %>%
  distinct(ym, .keep_all = TRUE) %>%
  arrange(ym)

# Optional cumulative shock
shock_monthly_cum <- shock_monthly %>%
  mutate(CumShock = cumsum(coalesce(NatShock_level, 0)))

# =============================================================================
# 2) Exposure: CBSA-level PCA index from HMDA (2018–2021 window, half-life decay)
# =============================================================================

# HMDA 30Y loan-level sample (generated upstream)
hmda_raw <- read_csv(
  hmda_file,
  col_types = cols(
    activity_year = col_integer(),
    derived_msa_md = col_character(),
    loan_amount = col_double(),
    interest_rate = col_double()
  )
)

hmda <- hmda_raw %>%
  transmute(
    activity_year,
    msa = derived_msa_md,
    loan_amount = as.numeric(loan_amount),
    interest_rate = as.numeric(interest_rate)
  ) %>%
  filter(!is.na(msa), !is.na(loan_amount), loan_amount > 0, !is.na(interest_rate))

hmda_expo_base <- hmda %>%
  filter(activity_year >= expo_year_min, activity_year <= expo_year_max) %>%
  mutate(year_weight = 1)

if (!is.na(half_life_years) && is.finite(half_life_years)) {
  hmda_expo_base <- hmda_expo_base %>%
    mutate(year_weight = 0.5 ^ ((ref_year - activity_year) / half_life_years))
}

hmda_binned <- hmda_expo_base %>%
  mutate(rate_bin = cut(interest_rate, breaks = bin_edges,
                        labels = bin_labels, right = FALSE)) %>%
  filter(!is.na(rate_bin))

expo_df <- hmda_binned %>%
  group_by(msa, rate_bin) %>%
  summarise(amt_w = sum(loan_amount * year_weight, na.rm = TRUE), .groups = "drop_last") %>%
  mutate(msa_total = sum(amt_w, na.rm = TRUE),
         w = ifelse(msa_total > 0, amt_w / msa_total, NA_real_)) %>%
  ungroup() %>%
  select(msa, rate_bin, w) %>%
  pivot_wider(names_from = rate_bin, values_from = w, names_prefix = "w_") %>%
  mutate(across(starts_with("w_"), ~replace_na(., 0))) %>%
  rowwise() %>%
  mutate(w_sum = sum(c_across(starts_with("w_")))) %>%
  ungroup() %>%
  mutate(across(starts_with("w_"), ~ ifelse(w_sum > 0, .x / w_sum, 0))) %>%
  select(-w_sum)

# Unified 5-digit CBSA code
expo_df <- expo_df %>%
  mutate(cbsa_code = str_pad(as.character(msa), 5, pad = "0"))

# PCA compression
w_cols <- c("w_lt3", "w_3to4", "w_4to5", "w_5to6", "w_ge6")
W <- expo_df %>% select(all_of(w_cols)) %>% as.matrix()

pca <- prcomp(W, center = TRUE, scale. = TRUE)
Exposure_raw <- pca$x[, 1]

# Direction anchor: ensure "more low-rate share => higher exposure"
anchor <- (expo_df$w_lt3 - expo_df$w_ge6)
if (cor(Exposure_raw, anchor, use = "complete.obs") < 0) {
  Exposure_raw <- -Exposure_raw
}

# Demean only (no variance scaling)
expo_df$Exposure <- as.numeric(scale(Exposure_raw, center = TRUE, scale = FALSE))

expo_keep <- expo_df %>%
  select(cbsa_code, Exposure)

# =============================================================================
# 3) Build MSA × Month Z panel and export
# =============================================================================

Z_panel <- crossing(
  cbsa_code = unique(expo_keep$cbsa_code),
  ym        = unique(shock_monthly$ym)
) %>%
  left_join(expo_keep, by = "cbsa_code") %>%
  left_join(shock_monthly, by = "ym") %>%
  mutate(
    Z_bartik_level = Exposure * NatShock_level
  ) %>%
  left_join(shock_monthly_cum %>% select(ym, CumShock), by = "ym") %>%
  mutate(
    Z_bartik_cum = Exposure * CumShock
  ) %>%
  arrange(cbsa_code, ym)

Z_out <- Z_panel %>%
  select(cbsa_code, ym,
         Z_bartik_level, Z_bartik_cum,
         Exposure, NatShock_level, CumShock)

write_csv(Z_out, out_file)

