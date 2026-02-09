# Home Mortgage Disclosure Act (HMDA) Data

This folder documents the raw HMDA public Loan/Application Records (LAR) data used in Chapter 2.

## Source
HMDA Snapshot: National Loan-Level Dataset (FFIEC/CFPB). Download yearly "Loan/Application Records (LAR)" files.

- File type: Loan/Application Records (LAR) (public CSV), downloaded by year from HMDA offical website: https://ffiec.cfpb.gov/data-publication/snapshot-national-loan-level-dataset/2024
- Coverage used in this project Years: 2018–2024

Expected raw filenames
Place the yearly CSV files here using the naming convention:
- 2018_public_lar_csv.csv
- 2019_public_lar_csv.csv
...
- 2024_public_lar_csv.csv

Notes
- Raw datasets are never modified.
- Large raw files should not be committed to GitHub.

---

# Primary Mortgage Market Survey (PMMS) Data

This folder also documents the raw Freddie Mac Primary Mortgage Market Survey (PMMS) data used in Chapter 2 to obtain the national 30-year fixed-rate mortgage series (weekly), which is aggregated to monthly averages and merged with the HMDA-based MSA-month panel to compute the monthly mortgage rate gap.

## Source
- Freddie Mac PMMS:
https://www.freddiemac.com/pmms
- File type：
Weekly PMMS historical data workbook (Excel)

Expected raw filename
Place the PMMS workbook here using the naming convention: historicalweeklydata.xlsx

Coverage used in this project
- Weekly window used for monthly aggregation: 2018-01-04 to 2024-12-26 (inclusive)

Notes
- Raw datasets are never modified.
- Large raw files should not be committed to GitHub.

---

# 10-Year Treasury Constant Maturity Rate (GS10)

This folder also documents the raw 10-year U.S. Treasury yield series used in Chapter 2.
This series is merged with the monthly PMMS rate to construct the national shock (NatShock)
as the residual from regressing the 30-year FRM rate on the 10-year yield.

## Source
- FRED (Federal Reserve Bank of St. Louis), GS10:
https://fred.stlouisfed.org/series/GS10
- File type
CSV download from FRED

Expected raw filename 
Place the CSV file here using the naming convention: GS10.csv

Coverage used in this project
Monthly observations for 2018–2024 (restricted in code)

Notes
- Raw datasets are never modified.
- Large raw files should not be committed to GitHub.
