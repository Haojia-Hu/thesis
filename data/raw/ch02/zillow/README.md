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
  
