# Home Mortgage Disclosure Act (HMDA) Data

This folder documents the raw HMDA public Loan/Application Records (LAR) data used in Chapter 2.

## Source
HMDA Snapshot: National Loan-Level Dataset (FFIEC/CFPB). Download yearly "Loan/Application Records (LAR)" files.

- File type: Loan/Application Records (LAR) (public CSV), downloaded by year from HMDA offical website: https://ffiec.cfpb.gov/data-publication/snapshot-national-loan-level-dataset/2024
- Coverage used in this project Years: 2018–2024

Expected raw filenames (not committed to Git)
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
Freddie Mac PMMS:
```text
https://www.freddiemac.com/pmms
File type
Weekly PMMS historical data workbook (Excel)

Expected raw filename (not committed to Git)
Place the PMMS workbook here using the naming convention:

historicalweeklydata.xlsx

Coverage used in this project
Weekly window used for monthly aggregation: 2018-01-04 to 2024-12-26 (inclusive)

Notes
Raw datasets are never modified.

Large raw files should not be committed to GitHub.
