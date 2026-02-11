# Chapter 2 - Zillow Data Construction (CBSA Monthly)

This folder contains scripts that transform raw Zillow metro/region time series into
a CBSA-by-month panel used as housing-market activity outcomes in Chapter 2.

The workflow has two steps:
1) build a RegionID → CBSA crosswalk,
2) aggregate Zillow metro outcomes to the CBSA-month level.

---

## Scripts

### 01_build_zillow_crosswalk.R

**Purpose**  
Create a clean `RegionID`–`cbsa_code` mapping used to translate Zillow metro series
into CBSA identifiers consistent with HMDA and other Chapter 2 datasets.

**Input (raw)**  
- `thesis/data/raw/ch02/zillow/Raw_zillow_MSA_crosswalk.xlsx`  
  Source: *Zillow MSA (Metro/Region) to County Crosswalk* compiled by Darren Aiello  
  (downloaded from: https://www.darrenaiello.com/data)

**Processing**  
- Keeps only `RegionID` and `cbsa_code`
- Cleans characters/whitespace
- Drops empty rows
- Removes duplicate `RegionID` entries (keeps first occurrence)

**Output (transformed)**  
- `thesis/data/transformed/ch02/zillow/Zillow_crosswalk.csv`

---

### 02_build_zillow_cbsa_monthly.R

**Purpose**  
Convert Zillow metro time-series files (wide date columns) into a CBSA-by-month panel
for each housing-market outcome used as lock-in proxies.

**Inputs**
1) Crosswalk  
- `thesis/data/transformed/ch02/zillow/Zillow_crosswalk.csv`

2) Zillow outcome files (raw)  
Stored in: `thesis/data/raw/ch02/zillow/`  
Downloaded from Zillow Research Data: https://www.zillow.com/research/data/  
(Series are monthly and seasonally adjusted, covering 2018–2024 in this project.)

Expected raw files include:
- `Metro_invt_fs_uc_sfrcondo_sm_month.csv` (for-sale inventory)
- `Metro_new_listings_uc_sfrcondo_sm_month.csv` (new listings)
- `Metro_new_pending_uc_sfrcondo_sm_month.csv` (new pending sales)
- `Metro_mean_doz_pending_uc_sfrcondo_sm_month.csv` (days to pending)
- `Metro_perc_listings_price_cut_uc_sfrcondo_sm_month.csv` (share of price cuts)
- `Metro_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv` (ZHVI, optional for price analysis)

**Processing (high level)**
- Detects date columns robustly from column names (handles `XYYYY.MM.DD`, etc.)
- Reshapes each series from wide to long
- Converts dates to `yearmon` = `YYYY-MM`
- Maps `RegionID → cbsa_code` using the crosswalk
- Aggregates to CBSA-month level (mean across regions mapped to the same CBSA)
- Restricts sample window to the project period (2018–2024)

**Outputs (transformed)**  
Written to: `thesis/data/transformed/ch02/zillow/`

Current outputs (one file per outcome; names are kept consistent with downstream code):
- `zillow_invt.csv`
- `zillow_newlisting.csv`
- `zillow_newlypending.csv`
- `zillow_daytopending.csv`
- `zillow_sharepricecut.csv`
- `zillow_zhvi.csv` (if constructed)

Each output has the same schema:
- `cbsa_code` : 5-digit CBSA identifier (string, zero-padded)
- `yearmon`   : month identifier (`YYYY-MM`)
- `proxy_value` : outcome value (numeric)

---

## Notes

- Raw Zillow files are large and should not be edited in place.
- This pipeline preserves the original series naming conventions used in the project
  to avoid breaking downstream scripts.
- If a CBSA maps to multiple Zillow RegionIDs, the CBSA-month value is computed as
  the mean across matched regions for that month.
