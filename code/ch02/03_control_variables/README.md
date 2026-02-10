# Chapter 2 – Control Variable Construction

This folder contains scripts used to construct CBSA-level control variables for
the Chapter 2 empirical analysis. Each script reads raw data stored under
`data/raw/ch02/control_variables/` (not committed to Git) and produces a clean,
analysis-ready CBSA-by-month panel stored under
`data/transformed/ch02/control_variables/`.

All scripts are designed to be fully reproducible and independent of local
machine-specific paths.

---

## 01_migration_monthly.R

**Purpose**  
Construct a monthly CBSA-level population-based control variable capturing local
migration dynamics.

**Description**  
This script converts annual CBSA population estimates (July 1 levels) from the
U.S. Census Bureau into a monthly CBSA panel via linear interpolation. Monthly
population changes and growth rates are computed as proxies for local migration
and demographic dynamics.

**Input (raw)**  
- CBSA population estimates from the U.S. Census Bureau Population Estimates Program (PEP)  
  (`data/raw/ch02/control_variables/population/`)

**Output (transformed)**  
- `cbsa_migration_monthly.csv`  
  (stored in `data/transformed/ch02/control_variables/`)

**Time coverage**  
- **July 2018 – July 2024** (monthly)

**Geographic level**  
- Core-Based Statistical Areas (CBSA)

---

## 02_unemployment_laus_msa.R

**Purpose**  
Construct a monthly CBSA-level unemployment rate control variable capturing local
labor market conditions.

**Description**  
This script extracts Metropolitan Statistical Area (MSA) unemployment rates from
the U.S. Bureau of Labor Statistics Local Area Unemployment Statistics (LAUS)
time-series files. Raw LAUS data are filtered to retain MSA observations only,
mapped to official 5-digit CBSA codes, and restricted to the Chapter 2 study
period.

**Input (raw)**  
- BLS LAUS time-series files  
  (`data/raw/ch02/control_variables/laus/`)

**Output (transformed)**  
- `laus_unemployment_msa.csv`  
  (stored in `data/transformed/ch02/control_variables/`)

**Time coverage**  
- **January 2018 – December 2024** (monthly)

**Geographic level**  
- Metropolitan Statistical Areas (CBSA level)

---

## 03_bps_cbsa_monthly.R

**Purpose**  
Construct a monthly CBSA-level building permits control variable capturing local
housing supply and construction activity.

**Description**  
This script compiles CBSA-level monthly total building permits from the U.S.
Census Bureau’s Building Permits Survey (BPS). To ensure full coverage of the
study period, the script combines early-period BPS TXT tables and later-period
BPS Excel releases, standardizes CBSA identifiers, and produces a unified
CBSA-by-month panel.

**Input (raw)**  
- BPS TXT tables (`tb3uYYYYMM.txt`)  
- BPS Excel releases (`msamonthly_YYYYMM.xls[x]`)  
  (`data/raw/ch02/control_variables/bps/`)

**Output (transformed)**  
- `bps_cbsa_monthly.csv`  
  (stored in `data/transformed/ch02/control_variables/`)

**Time coverage**  
- **January 2018 – December 2024** (monthly)

**Geographic level**  
- Core-Based Statistical Areas (CBSA)

---

## Notes

- Raw input files are not committed to GitHub.
- All outputs are standardized to **CBSA × month** panels and are designed to be
  directly merged with HMDA aggregates and other CBSA-level datasets used in
  Chapter 2.
