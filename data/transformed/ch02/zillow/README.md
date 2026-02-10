# Zillow Housing-Market Outcomes (Transformed)

This folder contains CBSA-by-month Zillow outcomes used in Chapter 2 regressions.

All outputs are reproducible using scripts in:
- `code/ch02/zillow/`

Key identifiers:
- `cbsa_code` : 5-digit CBSA code (string, padded with leading zeros)
- `yearmon`   : month in "YYYY-MM"

---

## 1) Crosswalk

### zillow_crosswalk.csv

**Purpose**  
Clean and standardize the mapping between Zillow metro `RegionID` and official `cbsa_code`.

**Input (raw)**
- `data/raw/ch02/zillow/Raw_zillow_MSA_crosswalk.xlsx`

**Output (transformed)**
- `zillow_crosswalk.csv`

Built by:
- `code/ch02/zillow/01_build_zillow_crosswalk.R`

---

## 2) CBSA-by-month outcomes (separate files; no merged panel)

Each file below is constructed by:
1) reading a Zillow metro-wide table (RegionID × date columns),
2) reshaping to long format,
3) mapping `RegionID -> cbsa_code` using `zillow_crosswalk.csv`,
4) aggregating to CBSA-by-month.

Built by:
- `code/ch02/zillow/02_build_zillow_proxies.R`

### Outputs

- `zillow_invt.csv`  
  Columns: `cbsa_code`, `yearmon`, `proxy_value`  
  For-sale inventory (stock measure).

- `zillow_newlisting.csv`  
  Columns: `cbsa_code`, `yearmon`, `proxy_value`  
  New listings (flow measure).

- `zillow_newlypending.csv`  
  Columns: `cbsa_code`, `yearmon`, `proxy_value`  
  Newly pending listings (pending-sales proxy).

- `zillow_daytopending.csv`  
  Columns: `cbsa_code`, `yearmon`, `proxy_value`  
  Mean days to pending (days).

- `zillow_sharepricecut.csv`  
  Columns: `cbsa_code`, `yearmon`, `proxy_value`  
  Share of listings with a price cut (percent/share).

- `zillow_zhvi.csv`  
  Columns: `cbsa_code`, `yearmon`, `proxy_value`  
  ZHVI (middle tier; smoothed & seasonally adjusted).

**Time coverage**
- Scripts extract months within 2018–2024 when available in the raw Zillow files.
- Downstream analyses typically use the balanced intersection with RateGap/IV/controls.

## Notes

- File names and schemas are kept consistent with the original exploratory code to minimize
  downstream refactoring.
- These outcomes are later merged (as needed) in the housing-quant estimation scripts by joining on
  (`cbsa_code`, `yearmon`).
