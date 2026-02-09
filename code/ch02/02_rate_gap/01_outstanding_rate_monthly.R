# =============================================================================
# Purpose
#   Construct a CBSA-by-month panel of outstanding-weighted mortgage rates
#   using loan-level HMDA data for 30-year fixed-rate mortgages.
#   This script converts annual originations into a monthly stock measure by:
#     1) assuming uniform origination across months,
#     2) applying standard amortization schedules, and
#     3) incorporating exponential decay to approximate prepayment.
#
# Inputs (generated, not version controlled)
#   data/transformed/ch02/hmda/hmda_30y_clean.csv
#
# Outputs (generated, not version controlled)
#   data/transformed/ch02/rate_gap/msa_outstanding_rate_monthly.csv
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(here)
})

# ---- Paths ----
input_file <- here(
  "data", "transformed", "ch02", "hmda", "hmda_30y_clean.csv"
)

output_dir <- here(
  "data", "transformed", "ch02", "rate_gap"
)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Parameters ----
lambda_prepay <- 0.005  # monthly exponential decay parameter

# ---- Load data ----
hmda <- fread(input_file)

# Required variables check
req_vars <- c("activity_year", "derived_msa_md",
              "loan_amount", "interest_rate", "loan_term")
stopifnot(all(req_vars %in% names(hmda)))

# Convert interest rate to monthly decimal
hmda[, r_month := interest_rate / 100 / 12]

# ---- Monthly amortization functions ----
monthly_payment <- function(P, r, N) {
  P * r * (1 + r)^N / ((1 + r)^N - 1)
}

remaining_balance <- function(P, r, N, k) {
  # k: months since origination
  P * ((1 + r)^N - (1 + r)^k) / ((1 + r)^N - 1)
}

# ---- Evaluation grid: monthly panel ----
eval_grid <- CJ(
  eval_year  = 2018:2024,
  eval_month = 1:12
)

# ---- Core computation ----
results <- list()

for (i in seq_len(nrow(eval_grid))) {

  ty <- eval_grid$eval_year[i]
  tm <- eval_grid$eval_month[i]

  # Months since origination assuming origination month m ∈ {1,…,12}
  hmda_expanded <- hmda[, {
    k_raw <- 12 * (ty - activity_year) + (tm - orig_month)
    k     <- pmax(0, pmin(k_raw, loan_term))

    bal <- remaining_balance(
      loan_amount, r_month, loan_term, k
    ) * exp(-lambda_prepay * k)

    list(
      msa   = derived_msa_md,
      rate  = interest_rate,
      bal   = bal
    )
  }, by = .(activity_year),
     allow.cartesian = TRUE,
     env = list(orig_month = 1:12)
  ][bal > 0]

  # Aggregate to MSA-month
  agg <- hmda_expanded[, .(
    outstanding_rate = sum(rate * bal) / sum(bal),
    total_balance    = sum(bal),
    n_loans_alive    = .N
  ), by = msa]

  agg[, `:=`(
    eval_year  = ty,
    eval_month = tm
  )]

  results[[i]] <- agg
}

# ---- Combine all months ----
out <- rbindlist(results, use.names = TRUE)

# ---- Save output ----
out_file <- file.path(
  output_dir, "msa_outstanding_rate_monthly.csv"
)

fwrite(out, out_file)
