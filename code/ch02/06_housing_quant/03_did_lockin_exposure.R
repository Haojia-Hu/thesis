# ============================================================
# Chapter 2 - Housing Quant
# DID: High- vs Low-lock-in CBSAs after the 2022 rate shock
#
# PURPOSE
#   Replicate the DID design that compares CBSAs with high vs low ex-ante lock-in exposure
#   before and after the 2022 mortgage-rate hike period (Post >= 2022-03).
#
# INPUTS (repo paths)
#   1) Baseline exposure used to define HighLockedIn (constructed earlier from HMDA):
#      thesis/data/transformed/ch02/rate_gap/msa_outstanding_weighted_rate_monthly.csv
#      Required columns:
#        - derived_msa_md
#        - eval_year, eval_month
#        - weighted_rate
#
#   2) Zillow lock-in proxy outcomes (CBSA-by-month; constructed earlier):
#      thesis/data/transformed/ch02/zillow/
#        - zillow_newlisting.csv
#        - zillow_invt.csv
#        - zillow_newlypending.csv
#        - zillow_daytopending.csv
#        - zillow_sharepricecut.csv
#      Each file must contain:
#        - cbsa_code, yearmon, proxy_value
#
# OUTPUTS (repo paths)
#   Main DID results (both log and level specifications):
#     thesis/data/output/ch02/housing_quant/did_lockin_exposure_results.csv
#
# NOTES
#   - HighLockedIn is defined as the bottom tercile of the 2021 baseline weighted mortgage rate.
#   - Post is defined as ym >= 2022-03.
#   - Regressions include CBSA FE and month FE; SE clustered by CBSA.
#   - "log" spec drops non-positive proxy_value observations.
# ============================================================

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(stringr)
  library(lubridate)
  library(fixest)
  library(broom)
})

# ---------------- Paths (repo) ----------------
# Baseline exposure panel used to define HighLockedIn (2021 baseline)
# (If your file is stored elsewhere, adjust THIS path only.)
w_rate_fp <- file.path("data", "transformed", "ch02", "rate_gap",
                       "msa_outstanding_weighted_rate_monthly.csv")

# Zillow proxies (already transformed to CBSA-by-month with proxy_value)
proxy_dir <- file.path("data", "transformed", "ch02", "zillow")
proxy_files <- c(
  "zillow_newlisting.csv",
  "zillow_invt.csv",
  "zillow_newlypending.csv",
  "zillow_daytopending.csv",
  "zillow_sharepricecut.csv"
)

# Output
out_dir <- file.path("data", "output", "ch02", "housing_quant")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_fp <- file.path(out_dir, "did_lockin_exposure_results.csv")

# ---------------- Checks ----------------
if (!file.exists(w_rate_fp)) {
  stop("Missing baseline exposure input: ", w_rate_fp, call. = FALSE)
}
missing_proxy <- file.path(proxy_dir, proxy_files)[!file.exists(file.path(proxy_dir, proxy_files))]
if (length(missing_proxy) > 0) {
  stop("Missing Zillow proxy input files:\n- ", paste(missing_proxy, collapse = "\n- "), call. = FALSE)
}

# ============================================================
# 1) Construct HighLockedIn using 2021 baseline weighted mortgage rate
# ============================================================

w_rate <- fread(w_rate_fp) %>%
  mutate(
    cbsa_code = str_pad(as.character(derived_msa_md), 5, pad = "0"),
    ym        = sprintf("%d-%02d", as.integer(eval_year), as.integer(eval_month))
  )

lock_exposure <- w_rate %>%
  filter(as.integer(eval_year) == 2021) %>%
  group_by(cbsa_code) %>%
  summarise(
    baseline_rate = mean(as.numeric(weighted_rate), na.rm = TRUE),
    .groups = "drop"
  )

cutoff <- quantile(lock_exposure$baseline_rate, probs = 1/3, na.rm = TRUE)

lock_exposure <- lock_exposure %>%
  mutate(HighLockedIn = ifelse(baseline_rate <= cutoff, 1, 0))

cat("HighLockedIn share:", mean(lock_exposure$HighLockedIn, na.rm = TRUE), "\n")

# ============================================================
# 2) DID runner (for a single proxy file and a chosen transform)
# ============================================================

run_proxy_did <- function(file_name, transform_type = c("log", "level")) {

  transform_type <- match.arg(transform_type)
  proxy_id <- tools::file_path_sans_ext(file_name)

  message("Running DID for: ", proxy_id, " (", transform_type, ")")

  df <- fread(file.path(proxy_dir, file_name)) %>%
    mutate(
      cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
      ym        = as.character(yearmon),
      ym_date   = as.Date(paste0(ym, "-01"))
    ) %>%
    select(cbsa_code, ym, ym_date, proxy_value) %>%
    left_join(lock_exposure, by = "cbsa_code") %>%
    mutate(Post = ifelse(ym_date >= as.Date("2022-03-01"), 1, 0)) %>%
    drop_na(baseline_rate, HighLockedIn)

  # Transform y
  if (transform_type == "log") {
    # Log requires strictly positive values
    df <- df %>%
      filter(!is.na(proxy_value), proxy_value > 0) %>%
      mutate(y = log(proxy_value))
  } else {
    df <- df %>%
      filter(!is.na(proxy_value)) %>%
      mutate(y = as.numeric(proxy_value))
  }

  # 2-way FE DID
  model <- feols(
    y ~ HighLockedIn * Post | cbsa_code + ym,
    cluster = ~ cbsa_code,
    data = df
  )

  coefs <- broom::tidy(model)
  row_hp <- coefs %>% filter(term == "HighLockedIn:Post")

  tibble(
    proxy     = proxy_id,
    spec      = transform_type,   # "log" or "level"
    estimate  = row_hp$estimate,
    std_error = row_hp$std.error,
    t_value   = row_hp$statistic,
    p_value   = row_hp$p.value,
    n_obs     = model$obs
  )
}

# ============================================================
# 3) Run both log + level specs for each proxy and save
# ============================================================

did_results <- bind_rows(
  lapply(proxy_files, run_proxy_did, transform_type = "log")   |> bind_rows(),
  lapply(proxy_files, run_proxy_did, transform_type = "level") |> bind_rows()
) %>%
  arrange(proxy, spec)

fwrite(did_results, out_fp)
cat("Wrote:", out_fp, "\n")
