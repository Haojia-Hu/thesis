# Control Variables

This folder contains scripts used to construct control variables for the Chapter 2 empirical analysis.

---

## migration_monthly.R

**Purpose**  
Construct a CBSA-by-month population-based control variable using annual CBSA
population estimates from the U.S. Census Bureau.

**Description**  
This script converts annual CBSA population levels (July 1 estimates) into a
monthly CBSA panel via linear interpolation and computes monthly population
changes and growth rates as proxies for local migration dynamics.

**Output**  
- `cbsa_migration_monthly.csv`  
  (stored in `data/transformed/ch02/controls/`)

**Time coverage**  
- **July 2018 – July 2024** (monthly)

---

## unemployment_laus_msa.R

**Purpose**  
Construct a monthly CBSA-level unemployment rate control variable using raw
Local Area Unemployment Statistics (LAUS) data from the U.S. Bureau of Labor
Statistics (BLS).

**Description**  
This script extracts monthly unemployment rates for Metropolitan Statistical
Areas (MSAs) from the BLS LAUS time-series files. The raw LAUS data are filtered
to retain only MSA-level observations, matched to official 5-digit CBSA codes,
and restricted to the study period used in Chapter 2.

The resulting dataset provides a clean CBSA-by-month panel of local labor
market conditions that can be merged with HMDA loan-level aggregates and
other CBSA-level controls.

**Output**  
- `laus_unemployment_msa.csv`  
  (stored in `data/transformed/ch02/control_variables/`)

**Time coverage**  
- **January 2018 – December 2024** (monthly)

**Geographic coverage**  
- **Metropolitan Statistical Areas (CBSA level)**

**Notes**  
- Unemployment rates are expressed as percentages.
- Only MSA observations are retained; micropolitan areas are excluded.
- CBSA identifiers are aligned with Census and HMDA geographic definitions.

