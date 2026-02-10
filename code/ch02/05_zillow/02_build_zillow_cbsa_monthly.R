# ============================================================
# Build CBSA-by-month Zillow outcomes (separate files; keep original names)
#
# Raw inputs:
#   data/raw/ch02/zillow/*.csv (Zillow metro wide tables)
# Transformed input:
#   data/transformed/ch02/zillow/zillow_crosswalk.csv
#
# Outputs (transformed; keep original filenames):
#   data/transformed/ch02/zillow/zillow_invt.csv
#   data/transformed/ch02/zillow/zillow_newlisting.csv
#   data/transformed/ch02/zillow/zillow_newlypending.csv
#   data/transformed/ch02/zillow/zillow_daytopending.csv
#   data/transformed/ch02/zillow/zillow_sharepricecut.csv
#   data/transformed/ch02/zillow/zillow_zhvi.csv
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(lubridate)
})

raw_dir  <- file.path("data", "raw", "ch02", "zillow")
out_dir  <- file.path("data", "transformed", "ch02", "zillow")
xwalk_fp <- file.path(out_dir, "zillow_crosswalk.csv")

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
if (!file.exists(xwalk_fp)) stop("Missing crosswalk: ", xwalk_fp, call. = FALSE)

# ---- crosswalk (RegionID -> cbsa_code) ----
cw <- read_csv(xwalk_fp, show_col_types = FALSE) %>%
  rename_with(tolower) %>%
  transmute(
    regionid  = as.character(regionid),
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0")
  ) %>%
  filter(!is.na(regionid), regionid != "", !is.na(cbsa_code), str_detect(cbsa_code, "^\\d{5}$"))

# ---- robust date parsing for Zillow column names ----
to_date_safe <- function(nm_vec) {
  nm <- tolower(nm_vec)
  nm <- gsub("^x", "", nm)              # X2018.3.31 -> 2018.3.31
  nm <- gsub("[./]", "-", nm)           # 2018.3.31 -> 2018-3-31
  nm <- gsub("[^0-9-]", "", nm)         # strip weird chars

  dt <- suppressWarnings(ymd(nm, quiet = TRUE))
  bad <- is.na(dt)
  if (any(bad)) {
    dt2 <- suppressWarnings(mdy(nm[bad], quiet = TRUE))
    dt[bad] <- dt2
  }
  dt
}

# ---- core converter: wide (RegionID x dates) -> CBSA-month ----
build_proxy <- function(zillow_file, out_file) {

  in_fp  <- file.path(raw_dir, zillow_file)
  out_fp <- file.path(out_dir, out_file)

  if (!file.exists(in_fp)) stop("Missing raw Zillow file: ", in_fp, call. = FALSE)

  message("Processing: ", zillow_file, " -> ", out_file)

  zraw <- read_csv(in_fp, show_col_types = FALSE) %>%
    rename_with(tolower)

  if (!("regionid" %in% names(zraw))) stop("Missing RegionID column in: ", in_fp, call. = FALSE)

  zraw <- zraw %>% mutate(regionid = as.character(regionid))

  nm_all    <- names(zraw)
  dt_try    <- to_date_safe(nm_all)
  date_cols <- nm_all[!is.na(dt_try)]
  if (length(date_cols) == 0) stop("No date columns detected in: ", in_fp, call. = FALSE)

  z_long <- zraw %>%
    select(regionid, all_of(date_cols)) %>%
    pivot_longer(cols = all_of(date_cols), names_to = "date_raw", values_to = "value") %>%
    mutate(
      date    = to_date_safe(date_raw),
      yearmon = format(date, "%Y-%m")
    ) %>%
    filter(!is.na(date)) %>%
    select(regionid, yearmon, value)

  z_cbsa <- z_long %>%
    left_join(cw, by = "regionid") %>%
    filter(!is.na(cbsa_code) & cbsa_code != "") %>%
    group_by(cbsa_code, yearmon) %>%
    summarise(proxy_value = mean(value, na.rm = TRUE), .groups = "drop") %>%
    filter(yearmon >= "2018-01", yearmon <= "2024-12") %>%
    arrange(cbsa_code, yearmon)

  write_csv(z_cbsa, out_fp)
  message("Wrote: ", out_fp, " | rows=", nrow(z_cbsa))
  invisible(z_cbsa)
}

# ---- run all proxies (keep your original output names) ----
build_proxy("Metro_invt_fs_uc_sfrcondo_sm_month.csv",                 "zillow_invt.csv")
build_proxy("Metro_new_listings_uc_sfrcondo_sm_month.csv",            "zillow_newlisting.csv")
build_proxy("Metro_new_pending_uc_sfrcondo_sm_month.csv",             "zillow_newlypending.csv")
build_proxy("Metro_mean_doz_pending_uc_sfrcondo_sm_month.csv",        "zillow_daytopending.csv")
build_proxy("Metro_perc_listings_price_cut_uc_sfrcondo_sm_month.csv", "zillow_sharepricecut.csv")
build_proxy("Metro_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv",   "zillow_zhvi.csv")
