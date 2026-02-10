# Zillow Crosswalk (Raw)

This folder stores the raw crosswalk used to map Zillow metro/region identifiers to
official CBSA codes for Chapter 2.

## Source

The raw crosswalk is obtained from:
Darren Aiello – Data downloads
(Zillow MSA (Metro/Region) to County Crosswalk)

Source page:
https://www.darrenaiello.com/data

## Raw file (not committed to Git)

- `Raw_zillow_MSA_crosswalk.xlsx`

This file is imported as-is and never modified. Large raw files should not be committed to GitHub.

## Notes

- This crosswalk provides a mapping from Zillow MSA/Region identifiers (e.g., `RegionID`)
  to official CBSA codes used throughout Chapter 2.
- The cleaned crosswalk output is written to:
  `data/transformed/ch02/zillow/`

---

# Zillow Housing-Market Outcomes (Raw)

This folder stores raw Zillow housing-market datasets used to construct monthly CBSA-level
outcomes for Chapter 2 (lock-in proxies and house prices).

## Source

All raw Zillow outcomes are downloaded from **Zillow Research Data**:
https://www.zillow.com/research/data/ :contentReference[oaicite:1]{index=1}

These datasets are published by Zillow Research and provide monthly, metro-level (RegionID)
housing market indicators.

## Coverage

We use the **2018–2024** sample window for Chapter 2. In practice, downstream scripts
restrict to the study window and later take the intersection with RateGap/IV/controls.

## Dataset cuts and flags (important)

File names follow Zillow’s conventions:

- `Metro_...`: metro/region-level panel keyed by `RegionID`
- `..._month`: monthly frequency
- `sm`: smoothed series (Zillow “smooth/smoothed” cut)
- `sa`: seasonally adjusted series (only when explicitly included, e.g., ZHVI)
- `uc`: Zillow’s “unadjusted count / core series cut” naming convention used in many for-sale
  listings files; we treat it as part of the dataset identifier and do not alter it.
- `sfrcondo`: single-family residences + condos/co-ops (housing type cut)

**Note:** Not all series are seasonally adjusted. In our raw set, ZHVI explicitly includes `sa`;
the for-sale listing proxies do not necessarily include seasonal adjustment in the file identifier. :contentReference[oaicite:2]{index=2}

## Raw files (not committed to Git)

### Lock-in proxy outcomes (monthly, metro / RegionID)
- `Metro_invt_fs_uc_sfrcondo_sm_month.csv`  
  **For-Sale Inventory**: count of unique listings active at any time during the month. :contentReference[oaicite:3]{index=3}

- `Metro_new_listings_uc_sfrcondo_sm_month.csv`  
  **New Listings**: number of new listings coming onto the market during the month. :contentReference[oaicite:4]{index=4}

- `Metro_new_pending_uc_sfrcondo_sm_month.csv`  
  **Newly Pending Listings / Pending Sales proxy**: count of listings that transitioned
  from for-sale to pending status on Zillow during the period. :contentReference[oaicite:5]{index=5}

- `Metro_mean_doz_pending_uc_sfrcondo_sm_month.csv`  
  **Days to Pending (mean)**: how long it takes homes to change to pending status after first
  being shown as for sale (excludes the in-contract period before closing). :contentReference[oaicite:6]{index=6}

- `Metro_perc_listings_price_cut_uc_sfrcondo_sm_month.csv`  
  **Share of Listings with a Price Cut**: share of active listings that experienced a price cut
  during the period (expressed in percent/share terms depending on the file). :contentReference[oaicite:7]{index=7}

### House price outcome
- `Metro_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv`  
  **ZHVI (middle tier, smoothed & seasonally adjusted)**: “typical” home value for the region,
  reflecting the middle tier (roughly 35th–65th percentile range). :contentReference[oaicite:8]{index=8}

## Notes

- Raw datasets are stored as downloaded and never modified.
- Large raw files should not be committed to GitHub.
- Metro-level series are keyed by `RegionID` and must be mapped to CBSA codes using a crosswalk
  (see `data/raw/ch02/zillow/Raw_zillow_MSA_crosswalk.xlsx` and transformed outputs).
  
