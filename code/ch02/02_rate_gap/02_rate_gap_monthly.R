# =============================================================================
# Purpose
#   1) Convert PMMS weekly 30Y FRM rates to monthly averages (2018–2024).
#   2) Merge monthly PMMS with the HMDA-based MSA-by-month outstanding
#       mortgage rate panel and compute:
#         rate_gap_{m,t} = pmms_30y_t - weighted_rate_{m,t}.
#   3) Produce a national monthly average rate gap figure.
#
# Inputs (generated / raw; not version controlled)
#   Generated input (HMDA-based panel):
#     data/transformed/ch02/rate_gap/msa_outstanding_rate_monthly.csv
#     Expected columns: eval_year, eval_month, derived_msa_md, weighted_rate
#     (Compatibility: also accepts columns msa/outstanding_rate.)
#
#   Raw input (PMMS weekly workbook):
#     data/raw/ch02/pmms/historicalweeklydata.xlsx
#     (Reads Week and FRM30 columns; weekly window 2018-01-04 to 2024-12-26)
#
# Outputs (generated; not version controlled)
#   Transformed:
#     data/transformed/ch02/rate_gap/pmms_30y_monthly.csv
#     data/transformed/ch02/rate_gap/rate_gap_monthly.csv
#
#   Output figures:
#     data/output/ch02/figures/fig_rate_gap_national_monthly.pdf
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
  library(lubridate)
  library(ggplot2)
  library(here)
})

# ---- Paths ----
hmda_panel_file <- here("data", "transformed", "ch02", "rate_gap",
                        "msa_outstanding_rate_monthly.csv")
pmms_file <- here("data", "raw", "ch02", "pmms", "historicalweeklydata.xlsx")

out_trans_dir <- here("data", "transformed", "ch02", "rate_gap")
out_fig_dir   <- here("data", "output", "ch02", "figures")

dir.create(out_trans_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(out_fig_dir,   recursive = TRUE, showWarnings = FALSE)

# ---- Read HMDA-based monthly MSA panel ----
MSA_panel <- fread(hmda_panel_file, na.strings = c("", "NA"))

# Compatibility layer for earlier naming conventions:
# - accept msa/outstanding_rate and rename to derived_msa_md/weighted_rate
if ("msa" %in% names(MSA_panel) && !"derived_msa_md" %in% names(MSA_panel)) {
  setnames(MSA_panel, "msa", "derived_msa_md")
}
if ("outstanding_rate" %in% names(MSA_panel) && !"weighted_rate" %in% names(MSA_panel)) {
  setnames(MSA_panel, "outstanding_rate", "weighted_rate")
}

stopifnot(all(c("eval_year", "eval_month", "derived_msa_md", "weighted_rate") %in% names(MSA_panel)))

# Coerce types and restrict window
MSA_panel[, eval_year := as.integer(eval_year)]
MSA_panel[, eval_month := as.integer(eval_month)]
MSA_panel[, weighted_rate := as.numeric(weighted_rate)]
MSA_panel <- MSA_panel[eval_year >= 2018 & eval_year <= 2024]

# ---- Read PMMS weekly workbook ----
# Header starts at row 5; take first two columns only.
PMMS_raw <- read_excel(
  path      = pmms_file,
  skip      = 4,
  col_names = TRUE
)

# Standardize column names (first two columns)
names(PMMS_raw)[1:2] <- c("Week", "FRM30")

PMMS_raw <- as.data.table(PMMS_raw[, c("Week", "FRM30")])
PMMS_raw <- PMMS_raw[!(is.na(Week) & is.na(FRM30))]

# Robust date parsing (handles ymd, mdy, Excel serial)
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

PMMS_raw[, Week := to_Date_excel_mixed(Week)]
PMMS_raw <- PMMS_raw[!is.na(Week)]
PMMS_raw[, FRM30 := as.numeric(FRM30)]
PMMS_raw <- PMMS_raw[!is.na(FRM30)]

# Restrict weekly window (as specified)
PMMS_raw <- PMMS_raw[
  Week >= as.Date("2018-01-04") & Week <= as.Date("2024-12-26")
]

# ---- Weekly -> Monthly average ----
PMMS_raw[, `:=`(eval_year = year(Week), eval_month = month(Week))]

pmms_monthly <- PMMS_raw[
  eval_year >= 2018 & eval_year <= 2024,
  .(pmms_30y = mean(FRM30, na.rm = TRUE)),
  by = .(eval_year, eval_month)
][order(eval_year, eval_month)]

# Save PMMS monthly series (useful intermediate)
pmms_outfile <- file.path(out_trans_dir, "pmms_30y_monthly.csv")
fwrite(pmms_monthly, pmms_outfile)

# ---- Merge + Rate gap ----
Rate_gap_monthly <- merge(
  MSA_panel,
  pmms_monthly,
  by = c("eval_year", "eval_month"),
  all.x = TRUE
)

Rate_gap_monthly[, rate_gap := pmms_30y - weighted_rate]

# Save rate gap panel
rate_gap_outfile <- file.path(out_trans_dir, "rate_gap_monthly.csv")
fwrite(Rate_gap_monthly, rate_gap_outfile)


# ---- National monthly average plot ----
DT <- copy(Rate_gap_monthly)

DT[, eval_date := as.Date(paste0(eval_year, "-", sprintf("%02d", eval_month), "-01"))]

agg_month <- DT[, .(
  avg_rate_gap = mean(rate_gap, na.rm = TRUE)
), by = eval_date][order(eval_date)]

p <- ggplot(agg_month, aes(x = eval_date, y = avg_rate_gap)) +
  geom_line(linewidth = 1.1) +
  labs(
    title = "National Monthly Average Rate Gap",
    x = "Date",
    y = "Rate Gap (%)"
  ) +
  theme_minimal(base_size = 14)

fig_outfile <- file.path(out_fig_dir, "fig_rate_gap_national_monthly.pdf")
ggsave(filename = fig_outfile, plot = p, width = 8, height = 4.5)
