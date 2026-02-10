# Zillow Crosswalk

This folder contains analysis-ready Zillow crosswalk outputs used to align Zillow housing-market
series with CBSA-level panels in Chapter 2.

All files in this folder are reproducible using:
- `code/ch02/zillow/01_build_zillow_crosswalk.R`

Key identifiers:
- `RegionID` (Zillow metro/region identifier)
- `cbsa_code` (5-digit CBSA code)

---

## zillow_crosswalk.csv

**Purpose**  
Provide a clean one-to-one mapping between Zillow `RegionID` and official 5-digit `cbsa_code`
to support merges between Zillow outcomes and CBSA-by-month datasets.

**Input (raw)**  
- `data/raw/ch02/zillow/Raw_zillow_MSA_crosswalk.xlsx`

**Output (transformed)**  
- `zillow_crosswalk.csv` (stored in this folder)

**Columns**
- `RegionID`
- `cbsa_code`

**Cleaning rules**
- Drop empty columns and rows.
- Keep only `RegionID` and `cbsa_code`.
- Trim whitespace and remove non-alphanumeric "dirty" characters.
- Enforce unique `RegionID` by keeping the first observed mapping if duplicates exist.

---

## Notes

- This transformed crosswalk is upstream of any Zillow outcome panel construction.
- `cbsa_code` is stored as a 5-character string with leading zeros if needed.

---

# Zillow Outcomes (Transformed/Proxies)

This folder contains analysis-ready CBSA-by-month Zillow outcomes for Chapter 2.
All outputs are reproducible using scripts in `code/ch02/zillow/`.

Key identifiers:
- `cbsa_code`: 5-digit CBSA (string with leading zeros)
- `ym`: month in "YYYY-MM" format

---

## 1) zillow_crosswalk.csv

**Purpose**  
Map Zillow metro/region identifiers (`RegionID`) to official CBSA codes.

**Input (raw)**  
- `data/raw/ch02/zillow/Raw_zillow_MSA_crosswalk.xlsx` (downloaded from darrenaiello.com/data)

**Output**  
- `zillow_crosswalk.csv`

**Columns**
- `RegionID`
- `cbsa_code` (5-digit)

Built by:
- `code/ch02/zillow/01_build_zillow_crosswalk.R`

---

## 2) CBSA-by-month outcomes (lock-in proxies + prices)

These files convert Zillow metro-wide tables into long panels, map `RegionID -> cbsa_code`,
then aggregate to CBSA-by-month.

Built by:
- `code/ch02/zillow/02_build_zillow_cbsa_monthly.R`

### Outputs (CBSA-by-month)

- `zillow_invt_cbsa_monthly.csv`  
  For-sale inventory (units): count of unique active listings in the month.

- `zillow_new_listings_cbsa_monthly.csv`  
  New listings (units): listings newly coming onto the market during the month.

- `zillow_pending_sales_cbsa_monthly.csv`  
  Newly pending listings (units): listings switching from for-sale to pending during the month.

- `zillow_days_to_pending_cbsa_monthly.csv`  
  Mean days to pending (days): time from first being listed to pending status.

- `zillow_price_cut_share_cbsa_monthly.csv`  
  Share of listings with a price cut (percent/share).

- `zillow_zhvi_cbsa_monthly.csv`  
  ZHVI (USD): typical home value, middle tier (smoothed & seasonally adjusted).

**Common columns**
- `cbsa_code`
- `ym`
- `value`

**Time coverage**
- Script extracts 2018-01 to 2024-12 from raw files (when available), then downstream analyses
  typically use the balanced intersection with RateGap/IV/controls (often 2018-08 to 2024-07).
