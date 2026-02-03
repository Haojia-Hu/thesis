# Raw Data: Factiva News Volume
This section documents the **raw Factiva exports** used to construct monthly news-volume measures for Chapter 1 analyses (including robustness checks that control for news volume).

### Data source

News counts are obtained from **Factiva (Dow Jones)**:
https://www.dowjones.com/business-intelligence/factiva/products/factiva/

The raw inputs are exported from Factiva as CSV files containing **annual document counts** for keyword queries.

### Keyword construction

Factiva queries use the **same keyword lists and category mapping** as the Google Trends attention index construction. For each consumption category, a corresponding set of category keywords is used to retrieve document counts.

### Required raw files

Place the exported Factiva CSV files under:

data/raw/


Each file should follow the naming convention:

- `CATEGORY_factiva.csv` (e.g., `apparel_factiva.csv`)

The ingestion script identifies Factiva inputs using the filename pattern:

- `*_factiva.csv`

### Raw file format requirements

Raw Factiva exports used in this project have the following structure:

- The first 4 lines are non-data headers (skipped by the script).
- Data begin at line 5 and contain two fields:
  1) a date range label ending in a 4-digit year (e.g., "... 2015")
  2) an annual document count.

The script extracts:
- `Year` from the trailing 4 digits of the date-range label
- `DocumentCount` as numeric

### Processing logic (annual → monthly)

The raw Factiva output is annual. The ingestion script converts it to monthly frequency by:

1. Converting annual document counts into a monthly average:
   - `NewsCount_Monthly = DocumentCount / 12`
2. Expanding each year into 12 rows (months 1–12).
3. Constructing a monthly `Date` as the first day of each month.

This produces a monthly series with columns:
- `Date`, `Year`, `Month`, `NewsCount_Monthly`

### How raw Factiva data are used in the repository

Raw Factiva exports are processed by:
- code/ch01/03_expectation_formation/02_ingest_factiva_raw.R
