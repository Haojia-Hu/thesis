# ==============================================================================
# Purpose:
# Construct CBSA-level monthly employment totals (2018–2024) from
# BLS QCEW county-level quarterly "singlefile" data.
#
# Steps:
#   1) Read quarterly county-level QCEW files
#   2) Keep total ownership (0) and total industry (10)
#   3) Expand quarterly data to monthly frequency
#   4) Map counties to CBSA using Census crosswalk
#   5) Aggregate to CBSA × month
#
# Inputs (data/raw/ch02/price_hetero):
#   - QCEW quarterly singlefile CSVs (2018–2024)
#   - list1_2023.xlsx (county → CBSA crosswalk)
#
# Output (data/transformed/ch02/housing_price):
#   - QCEW_cbsa_totalemp.csv
#
# ==============================================================================

library(data.table)
library(readxl)

# === Paths ===
raw_dir   <- "data/raw/ch02/price_hetero"
qcew_dir  <- file.path(raw_dir, "QCEW")
xwalk_path <- file.path(raw_dir, "list1_2023.xlsx")

out_path <- "data/transformed/ch02/housing_price/QCEW_cbsa_totalemp.csv"

years_keep <- 2018:2024

# === Read county → CBSA crosswalk ===
xwalk_raw <- read_excel(xwalk_path, skip = 2)

xwalk <- as.data.table(xwalk_raw)[
  !is.na(`CBSA Code`) & !is.na(`FIPS State Code`) & !is.na(`FIPS County Code`),
  .(
    cbsa_code   = sprintf("%05d", as.integer(`CBSA Code`)),
    county_fips = sprintf("%02d%03d",
                          as.integer(`FIPS State Code`),
                          as.integer(`FIPS County Code`))
  )
]

xwalk <- unique(xwalk)

# === Identify QCEW files ===
files_q <- list.files(qcew_dir,
                      pattern = "singlefile\\.csv$",
                      full.names = TRUE)

files_q <- files_q[grepl(paste(years_keep, collapse="|"), files_q)]

needed_cols <- c(
  "area_fips","own_code","industry_code","year","qtr",
  "month1_emplvl","month2_emplvl","month3_emplvl"
)

safe_fread <- function(path) {
  hdr <- names(fread(path, nrows = 0))
  fread(path, select = intersect(needed_cols, hdr))
}

agg_list <- vector("list", length(files_q))

# === Main Loop ===
for (i in seq_along(files_q)) {
  
  dt <- safe_fread(files_q[i])
  
  dt[, area_fips := sprintf("%05s", as.character(area_fips))]
  dt[, own_code  := as.character(own_code)]
  dt[, industry_code := as.character(industry_code)]
  dt[, year := as.integer(year)]
  dt[, qtr  := as.integer(qtr)]
  
  dt <- dt[own_code == "0" & industry_code == "10"]
  dt <- dt[year %in% years_keep]
  
  to_num <- function(x) suppressWarnings(as.numeric(x))
  
  dt[, emp1 := to_num(month1_emplvl)]
  dt[, emp2 := to_num(month2_emplvl)]
  dt[, emp3 := to_num(month3_emplvl)]
  
  dt <- dt[xwalk, on = .(area_fips = county_fips), nomatch = 0L]
  
  dt_long <- melt(
    dt,
    id.vars = c("cbsa_code","year","qtr"),
    measure.vars = c("emp1","emp2","emp3"),
    variable.name = "mvar",
    value.name = "emp"
  )
  
  dt_long[, m := fifelse(mvar=="emp1",1L,
                         fifelse(mvar=="emp2",2L,3L))]
  
  dt_long[, month := (qtr - 1L)*3L + m]
  dt_long[, ym := sprintf("%04d-%02d", year, month)]
  
  agg <- dt_long[, .(
    emp_total = sum(emp, na.rm = TRUE)
  ), by = .(cbsa_code, year, month, ym)]
  
  agg_list[[i]] <- agg
}

emp_monthly <- rbindlist(agg_list)
setorder(emp_monthly, cbsa_code, year, month)

fwrite(emp_monthly, out_path)

cat("Saved:", out_path, "\n")
