# ============================================================
# Purpose: First stage - instrument RateGap with Bartik IV (SS_IV) and controls
#
# Inputs (transformed):
#   data/transformed/ch02/rate_gap/Rate_gap_monthly.csv
#   data/transformed/ch02/iv/SS_IV.csv
#   data/transformed/ch02/control_variables/laus_unemployment_msa.csv
#   data/transformed/ch02/control_variables/cbsa_migration_monthly.csv
#   data/transformed/ch02/control_variables/bps_cbsa_monthly.csv
#
# Outputs:
#   data/transformed/ch02/housing_quant/Rategap_hat_singleIV.csv
#   data/transformed/ch02/housing_quant/Panel_rategap_hat.csv
# ============================================================

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(stringr)
  library(fixest)
  library(readr)
})

# ----------------------------
# Paths
# ----------------------------
rg_file <- file.path("data", "transformed", "ch02", "rate_gap", "Rate_gap_monthly.csv")
iv_file <- file.path("data", "transformed", "ch02", "iv", "SS_IV.csv")

unemp_file <- file.path("data", "transformed", "ch02", "control_variables", "laus_unemployment_msa.csv")
mig_file   <- file.path("data", "transformed", "ch02", "control_variables", "cbsa_migration_monthly.csv")
bps_file   <- file.path("data", "transformed", "ch02", "control_variables", "bps_cbsa_monthly.csv")

out_dir <- file.path("data", "transformed", "ch02", "housing_quant")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

out_file_hat   <- file.path(out_dir, "Rategap_hat_singleIV.csv")
out_file_panel <- file.path(out_dir, "Panel_rategap_hat.csv")

# ----------------------------
# Checks
# ----------------------------
required <- c(rg_file, iv_file, unemp_file, mig_file, bps_file)
missing <- required[!file.exists(required)]
if (length(missing) > 0) {
  stop("Missing required input(s):\n - ", paste(missing, collapse = "\n - "), call. = FALSE)
}

# ----------------------------
# Read and standardize keys
# ----------------------------

# 1) Rate Gap
rg <- fread(rg_file) %>%
  transmute(
    cbsa_code = str_pad(as.character(derived_msa_md), 5, pad = "0"),
    ym        = sprintf("%04d-%02d", as.integer(eval_year), as.integer(eval_month)),
    rate_gap  = as.numeric(rate_gap)
  )

# 2) SS-IV (use level by default)
iv <- fread(iv_file) %>%
  transmute(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym        = as.character(ym),
    Z_bartik  = as.numeric(Z_bartik_level)  # switch to Z_bartik_cum if needed
  )

# 3) Unemployment
unemp <- fread(unemp_file) %>%
  transmute(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym        = as.character(yearmon),
    unemployment_rate = as.numeric(unemployment_rate)
  )

# 4) Migration
mig <- fread(mig_file) %>%
  transmute(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym        = as.character(yearmon),
    mig_rate_month = as.numeric(mig_rate_month)
  )

# 5) Building Permits (BPS)
bps <- fread(bps_file) %>%
  transmute(
    cbsa_code = str_pad(as.character(cbsa), 5, pad = "0"),
    ym        = as.character(yearmon),
    bps_total = as.numeric(total)
  )

# ----------------------------
# Merge (panel for first stage)
# ----------------------------
panel <- rg %>%
  left_join(iv,    by = c("cbsa_code", "ym")) %>%
  left_join(unemp, by = c("cbsa_code", "ym")) %>%
  left_join(mig,   by = c("cbsa_code", "ym")) %>%
  left_join(bps,   by = c("cbsa_code", "ym")) %>%
  filter(
    ym >= "2018-01", ym <= "2024-12",
    !is.na(rate_gap),
    !is.na(Z_bartik),
    !is.na(unemployment_rate),
    !is.na(mig_rate_month),
    !is.na(bps_total)
  )

cat("First-stage sample:\n",
    "Rows:", nrow(panel),
    "| CBSAs:", n_distinct(panel$cbsa_code),
    "| Months:", n_distinct(panel$ym), "\n")

# ----------------------------
# First-stage regression (FE + cluster)
# ----------------------------
fsm <- feols(
  rate_gap ~ Z_bartik + unemployment_rate + mig_rate_month + bps_total | cbsa_code + ym,
  data = panel,
  cluster = ~ cbsa_code
)

print(summary(fsm))

# Quick strength check (t^2)
t_val <- summary(fsm)$coeftable["Z_bartik", "t value"]
F_stat <- t_val^2
cat("First-stage t^2 (quick F):", F_stat, "\n")

# ----------------------------
# Output: fitted + residual (diagnostics)
# ----------------------------
panel$rategap_hat   <- fitted(fsm)
panel$rategap_resid <- resid(fsm)

fwrite(panel %>% select(cbsa_code, ym, rategap_hat), out_file_hat)
fwrite(panel, out_file_panel)

cat("Wrote:\n - ", out_file_hat, "\n - ", out_file_panel, "\n")
