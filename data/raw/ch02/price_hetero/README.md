# Price Heterogeneity related Data

This folder contains raw external datasets used for heterogeneity analysis
in the Chapter 2 housing price module.

These data are NOT modified and should remain identical to the original
downloaded files from official sources.

---
## 1) BLS QCEW – County-Level Employment

Source:
U.S. Bureau of Labor Statistics (BLS)
Quarterly Census of Employment and Wages (QCEW)

Official website:
https://www.bls.gov/cew/downloadable-data-files.htm

Data used:
Quarterly "singlefile" CSV files at the county level,
covering 2018–2024.

File naming format (example):
    2018.q4.singlefile.csv
    2019.q4.singlefile.csv
    ...
    2024.q4.singlefile.csv

Content:
County × Quarter employment data including:
- own_code
- industry_code
- monthly employment levels (month1_emplvl, month2_emplvl, month3_emplvl)

In our processing:
- own_code = 0  (all ownership)
- industry_code = 10 (total, all industries)

These data are later aggregated from County → CBSA level
using Census crosswalk files.

--- 
## 2) Census County-to-CBSA Crosswalk (List 1)

Source:
U.S. Census Bureau
Metropolitan and Micropolitan Statistical Areas – Delineation Files

Official website:
https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/delineation-files.html

File used:
    list1_2023.xlsx

Purpose:
Provides mapping from:
    County FIPS → CBSA code

Used to aggregate county-level QCEW employment data
into CBSA-level monthly employment totals.

--- 
## 3) Saiz (2010) Housing Supply Elasticity

Source:
Saiz, Albert (2010)
"The Geographic Determinants of Housing Supply"

Official data page:
https://urbaneconomics.mit.edu/research/data

File used:
    saiz2010.csv

Original geographic identifier:
    msanecma (1999 MSA code)

--- 
## 4) MSA-to-CBSA Crosswalk (1999 → 2003)

Source:
U.S. Census Bureau

File used:
    cbsa03_msa99.xls

Purpose:
Maps old 1999 MSA codes to 2003 CBSA codes,
allowing Saiz (2010) elasticity measures
to be merged with modern CBSA-level datasets.

---

These raw datasets are processed into CBSA-level heterogeneity variables
using scripts located in:

    thesis/code/ch02/07_housing_price/
