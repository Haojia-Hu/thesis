# Zillow Crosswalk (Transformed)

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
- 
