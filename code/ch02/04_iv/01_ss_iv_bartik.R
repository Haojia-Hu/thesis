# ============================================================
# Shift-share (Bartik) IV: Exposure_i × NatShock_t
#
# Inputs:
#   data/raw/ch02/rate/historicalweeklydata.xlsx  (PMMS weekly, FRM30)
#   data/raw/ch02/rate/GS10.csv                   (10y Treasury)
#   data/transformed/ch02/hmda/HMDA_30y_clean.csv (HMDA cleaned, 30y loans)
#
# Outputs:
#   data/transformed/ch02/iv/NatShock_monthly.csv
#   data/transformed/ch02/iv/SS_IV.csv
# ============================================================

suppressPackageStartupMessages({
  library(readxl)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(stringr)
})

# ----------------------------
# Paths
# ----------------------------
rate_dir <- file.path("data", "raw", "ch02", "rate")
pmms_file <- file.path(rate_dir, "historicalweeklydata.xlsx")
gs10_file <- file.path(rate_dir, "GS10.csv")

hmda_file <- file.path("data", "transformed", "ch02", "hmda", "HMDA_30y_clean.csv")

out_dir <- file.path("data", "transformed", "ch02", "iv")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

out_shock <- file.path(out_dir, "NatShock_monthly.csv")
out_iv    <- file.path(out_dir, "SS_IV.csv")

# ----------------------------
# Checks
# ----------------------------
for (p in c(pmms_file, gs10_file, hmda_file)) {
  if (!file.exists(p)) stop("Missing required input file: ", p, call. = FALSE)
}

# ----------------------------
# 1) National shock: PMMS residual on GS10 (monthly)
# ----------------------------

# Robust date parsing for mixed formats (ymd, mdy, excel serial)
to_Date_excel_mixed <- function(v) {
  if (is.numeric(v)) return(as.Date(v, origin = "1899-12-30"))
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
    if (any(bad)) tmp[bad] <- suppressWarnings(mdy(v_chr[idx_other][bad]))
    res[idx_other] <- tmp
  }
  res
}

pmms_raw <- read_excel(pmms_file, skip = 4, col_names = TRUE)
names(pmms_raw)[1:2] <- c("Week", "FRM30")

pmms_raw <- pmms_raw %>%
  select(Week, FRM30) %>%
  mutate(
    Week = to_Date_excel_mixed(Week),
    FRM30 = as.numeric(FRM30)
  ) %>%
  filter(!is.na(Week), !is.na(FRM30)) %>%
  filter(Week >= as.Date("2018-01-04"), Week <= as.Date("2024-12-26")) %>%
  mutate(date = floor_date(Week, unit = "month")) %>%
  group_by(date) %>%
  summarise(pmms_30y = mean(FRM30, na.rm = TRUE), .groups = "drop") %>%
  filter(date >= ymd("2018-01-01"), date <= ymd("2024-12-01"))

gs10_monthly <- read_csv(
  gs10_file,
  col_types = cols(observation_date = col_character(), GS10 = col_double())
) %>%
  mutate(date = ymd(observation_date)) %>%
  filter(!is.na(date)) %>%
  mutate(date = floor_date(date, unit = "month")) %>%
  arrange(date) %>%
  filter(date >= ymd("2018-01-01") & date <= ymd("2024-12-01")) %>%
  transmute(date, gs10 = as.numeric(GS10))

shock_data <- pmms_raw %>%
  inner_join(gs10_monthly, by = "date") %>%
  arrange(date)

model_lvl <- lm(pmms_30y ~ gs10, data = shock_data)

shock_monthly <- shock_data %>%
  mutate(
    NatShock_level = resid(model_lvl),
    ym = format(date, "%Y-%m")
  ) %>%
  select(ym, pmms_30y, gs10, NatShock_level) %>%
  distinct(ym, .keep_all = TRUE) %>%
  arrange(ym)

write_csv(shock_monthly, out_shock)

# ----------------------------
# 2) Exposure: HMDA rate distribution (PCA)
# ----------------------------

# Parameters (keep here so repo is explicit)
expo_year_min <- 2018
expo_year_max <- 2021
ref_year <- 2021
half_life_years <- 5

bin_edges  <- c(-Inf, 3, 4, 5, 6, Inf)
bin_labels <- c("lt3", "3to4", "4to5", "5to6", "ge6")
w_cols     <- paste0("w_", bin_labels)

hmda <- read_csv(
  hmda_file,
  col_types = cols(
    activity_year = col_integer(),
    derived_msa_md = col_character(),
    loan_amount = col_double(),
    interest_rate = col_character()
  )
) %>%
  transmute(
    activity_year,
    msa = derived_msa_md,
    loan_amount = as.numeric(loan_amount),
    interest_rate = readr::parse_number(interest_rate)
  ) %>%
  filter(!is.na(msa), !is.na(loan_amount), loan_amount > 0, !is.na(interest_rate))

hmda_expo_base <- hmda %>%
  filter(activity_year >= expo_year_min, activity_year <= expo_year_max) %>%
  mutate(year_weight = 1)

if (!is.na(half_life_years) && is.finite(half_life_years)) {
  hmda_expo_base <- hmda_expo_base %>%
    mutate(year_weight = 0.5 ^ ((ref_year - activity_year) / half_life_years))
}

expo_df <- hmda_expo_base %>%
  mutate(rate_bin = cut(interest_rate, breaks = bin_edges, labels = bin_labels, right = FALSE)) %>%
  filter(!is.na(rate_bin)) %>%
  group_by(msa, rate_bin) %>%
  summarise(amt_w = sum(loan_amount * year_weight, na.rm = TRUE), .groups = "drop_last") %>%
  mutate(msa_total = sum(amt_w, na.rm = TRUE),
         w = ifelse(msa_total > 0, amt_w / msa_total, NA_real_)) %>%
  ungroup() %>%
  select(msa, rate_bin, w) %>%
  pivot_wider(names_from = rate_bin, values_from = w, names_prefix = "w_") %>%
  mutate(across(starts_with("w_"), ~replace_na(.x, 0))) %>%
  rowwise() %>%
  mutate(w_sum = sum(c_across(starts_with("w_")))) %>%
  ungroup() %>%
  mutate(across(starts_with("w_"), ~ ifelse(w_sum > 0, .x / w_sum, 0))) %>%
  select(-w_sum) %>%
  mutate(cbsa_code = str_pad(as.character(msa), 5, pad = "0"))

# PCA on share matrix
W <- expo_df %>% select(all_of(w_cols)) %>% as.matrix()
pca <- prcomp(W, center = TRUE, scale. = TRUE)
Exposure_raw <- pca$x[, 1]

# Direction anchor: higher (w_lt3 - w_ge6) => higher Exposure
anchor <- (expo_df$w_lt3 - expo_df$w_ge6)
if (cor(Exposure_raw, anchor, use = "complete.obs") < 0) {
  Exposure_raw <- -Exposure_raw
}

expo_df$Exposure <- as.numeric(scale(Exposure_raw, center = TRUE, scale = FALSE))

expo_keep <- expo_df %>%
  select(cbsa_code, Exposure) %>%
  distinct()

# ----------------------------
# 3) Bartik IV panel: Exposure × NatShock
# ----------------------------
Z_panel <- tidyr::crossing(
  cbsa_code = unique(expo_keep$cbsa_code),
  ym        = unique(shock_monthly$ym)
) %>%
  left_join(expo_keep, by = "cbsa_code") %>%
  left_join(shock_monthly %>% select(ym, NatShock_level), by = "ym") %>%
  mutate(
    Z_bartik_level = Exposure * NatShock_level
  ) %>%
  arrange(cbsa_code, ym)

# optional cumulative version
shock_monthly_cum <- shock_monthly %>%
  mutate(CumShock = cumsum(coalesce(NatShock_level, 0))) %>%
  select(ym, CumShock)

Z_panel <- Z_panel %>%
  left_join(shock_monthly_cum, by = "ym") %>%
  mutate(Z_bartik_cum = Exposure * CumShock)

Z_out <- Z_panel %>%
  select(cbsa_code, ym, Z_bartik_level, Z_bartik_cum, Exposure, NatShock_level)

write_csv(Z_out, out_iv)
