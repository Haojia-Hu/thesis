# ==============================================================================
# Purpose: Build CBSA-level Saiz (2010) housing supply elasticity measure
#          for Chapter 2 heterogeneity analysis.
#
# Background:
# - Saiz (2010) reports housing supply elasticity by (legacy) MSA code (msanecma).
# - Our empirical panel is CBSA-based (5-digit CBSA codes).
# - This script crosswalks Saiz's 1999 MSA codes to 2003 CBSA codes using the
#   Census crosswalk file and outputs a CBSA-level Saiz elasticity file.
#
# Inputs (data/raw/ch02/price_hetero):
# 1) saiz2010.csv
#    Source: https://urbaneconomics.mit.edu/research/data
#    Required column: msanecma (old MSA code), elasticity (Saiz elasticity)
#
# 2) cbsa03_msa99.xls
#    Source: US Census crosswalk (1999 MSA -> 2003 CBSA)
#    https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2003/99-msa-to-03-cbsa/cbsa03_msa99.xls
#    Required columns (names vary): 1999 MSA code, 2003 CBSA code
#
# Output (data/transformed/ch02/housing_price):
# 1) saiz2010_cbsa.csv
#    Columns include:
#      cbsa_code (5-digit), msanecma (4-digit), elasticity, inv_elast (= 1/elasticity)
#
# Notes:
# - When one 1999 MSA maps to multiple 2003 CBSAs (county-level splits),
#   we assign the "primary CBSA" defined as the CBSA containing the largest
#   number of counties in that MSA (ties broken by CBSA code).
# - This output is used in heterogeneity analysis by supply elasticity.
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(readxl)
})

# ---- Paths (repo-relative) ----
path_saiz <- "data/raw/ch02/saiz2010/saiz2010.csv"
path_xls  <- "data/raw/ch02/saiz2010/cbsa03_msa99.xls"
out_csv   <- "data/transformed/ch02/housing_price/saiz2010_cbsa.csv"

# ---- 1) Read Saiz (MSA-level) ----
saiz <- read_csv(path_saiz, show_col_types = FALSE) %>%
  mutate(
    msanecma   = str_pad(as.character(msanecma), 4, pad = "0"),
    elasticity = as.numeric(elasticity),
    inv_elast  = 1 / elasticity
  )

stopifnot(all(c("msanecma","elasticity") %in% names(saiz)))

# ---- 2) Read Census crosswalk (county-level mapping) ----
xw_raw <- read_excel(path_xls)

# Attempt to detect the needed columns even if headers differ slightly
xw <- xw_raw %>%
  rename(
    C_MSA_1999_Code = matches("C/?MSA_?1999_?Code",  ignore.case = TRUE),
    CBSA_2003_Code  = matches("CBSA_?2003_?Code",    ignore.case = TRUE)
  ) %>%
  mutate(
    C_MSA_1999_Code = str_pad(as.character(C_MSA_1999_Code), 4, pad = "0"),
    CBSA_2003_Code  = str_pad(as.character(CBSA_2003_Code),  5, pad = "0")
  ) %>%
  filter(!is.na(C_MSA_1999_Code), !is.na(CBSA_2003_Code))

stopifnot(all(c("C_MSA_1999_Code","CBSA_2003_Code") %in% names(xw)))

# ---- 3) Choose a "primary CBSA" for each legacy MSA (most counties) ----
msa_to_cbsa <- xw %>%
  count(C_MSA_1999_Code, CBSA_2003_Code, name = "n_counties") %>%
  group_by(C_MSA_1999_Code) %>%
  arrange(desc(n_counties), CBSA_2003_Code) %>%
  slice(1L) %>%
  ungroup() %>%
  transmute(
    msanecma  = C_MSA_1999_Code,
    cbsa_code = CBSA_2003_Code
  )

# ---- 4) Merge & keep matched CBSAs ----
saiz_cbsa <- saiz %>%
  left_join(msa_to_cbsa, by = "msanecma") %>%
  filter(!is.na(cbsa_code)) %>%
  distinct(cbsa_code, .keep_all = TRUE) %>%
  select(cbsa_code, msanecma, elasticity, inv_elast)

# ---- 5) Diagnostics ----
cat("Saiz rows (input):", nrow(saiz), "\n")
cat("Matched CBSAs:", n_distinct(saiz_cbsa$cbsa_code), "\n")
cat("Unmatched MSAs:", n_distinct(setdiff(saiz$msanecma, msa_to_cbsa$msanecma)), "\n")

# ---- 6) Write output ----
dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)
write_csv(saiz_cbsa, out_csv)
message("Exported: ", out_csv)
