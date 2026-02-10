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

# Zillow Housing-Market Data (Raw)

This folder stores raw Zillow metro-level datasets used to construct monthly CBSA-level
housing-market outcomes for Chapter 2.

## Source

All Zillow outcome series are downloaded from **Zillow Research Data**:
https://www.zillow.com/research/data/

We use metro-level (`Metro_...`) monthly series keyed by Zillow `RegionID`, and map them to
official CBSA codes using a crosswalk (see `Raw_zillow_MSA_crosswalk.xlsx` in this folder and
the cleaned `zillow_crosswalk.csv` in `data/transformed/ch02/zillow/`).

## Study period

Chapter 2 analyses focus on the **2018–2024** period. Downstream scripts may further restrict
the window to the balanced intersection with RateGap/IV/controls (often 2018-08 to 2024-07).

## Series flags in filenames (important)

Zillow filenames include metadata:

- `Metro_...` : metro/region-level series (RegionID)
- `_month` : monthly frequency
- `sm` : smoothed series (Zillow-provided smoothed cut)
- `sa` : seasonally adjusted series (only when explicitly included; e.g., ZHVI file includes `sa`)
- `sfrcondo` : single-family residences + condos/co-ops cut

**Note:** Not all series are seasonally adjusted. Only files explicitly labeled `sa` should be
described as seasonally adjusted.

## Raw files (not committed to Git)

### Crosswalk (Metro/Region -> CBSA)
- `Raw_zillow_MSA_crosswalk.xlsx`  
  Zillow MSA (Metro/Region) to County Crosswalk (downloaded from https://www.darrenaiello.com/data)

### Lock-in proxy outcomes (monthly, metro-level)
- `Metro_invt_fs_uc_sfrcondo_sm_month.csv`  
  For-sale inventory: number of active for-sale listings (stock measure).

- `Metro_new_listings_uc_sfrcondo_sm_month.csv`  
  New listings: number of listings newly entering the market during the month (flow measure).

- `Metro_new_pending_uc_sfrcondo_sm_month.csv`  
  Newly pending listings: number of listings transitioning to pending status during the month
  (proxy for pending sales/transaction flow).

- `Metro_mean_doz_pending_uc_sfrcondo_sm_month.csv`  
  Days to pending (mean): average time from listing to pending status (market tightness / liquidity).

- `Metro_perc_listings_price_cut_uc_sfrcondo_sm_month.csv`  
  Share of listings with a price cut: percent/share of active listings with a price cut (pricing margin).

### House price outcome
- `Metro_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv`  
  ZHVI (middle tier): typical home value index for the middle tier; smoothed and seasonally adjusted.

## Notes

- Raw datasets are stored as downloaded and never modified.
- Large raw files should not be committed to GitHub.
