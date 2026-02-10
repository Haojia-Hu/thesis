# CBSA Population Data 

This folder documents the raw CBSA-level population data used as a control variable
in Chapter 2.

## Source

CBSA population data are obtained from the **U.S. Census Bureau’s Population Estimates Program (PEP)**,
which provides annual population estimates for Core-Based Statistical Areas (CBSAs).
Annual population estimates are reported as **July 1 population levels**.

Official source:
https://www.census.gov/programs-surveys/popest.html

## Coverage and vintages

To cover the full study period, CBSA population data are compiled from **multiple Census
publication vintages** and merged into a single raw file:

- Late-2010s CBSA population estimates
- Early-2020s CBSA population estimates

The merged raw data provide **annual CBSA population levels for 2018–2024**.

## Geographic identifiers and alignment

The raw population data are reported at the **CBSA (Metropolitan Statistical Area) level**
and identified by official **5-digit CBSA codes** as defined by the Office of Management and Budget (OMB).

CBSA identifiers are standardized and validated using the OMB/Census metropolitan area
delineations (e.g., *List 2: Principal Cities of Metropolitan and Micropolitan Statistical Areas*),
to ensure consistency with other datasets used in Chapter 2.

This alignment allows the population data to be cleanly matched to HMDA loan-level data,
which also use 5-digit CBSA identifiers.

## Raw files (not committed to Git)

The merged raw population data are stored as:
- `cbsa_population_18_24.xlsx`

## Notes

- Raw population data report **total population levels**, not migration flows.
- Raw datasets are never modified.
- Large raw files should not be committed to GitHub.

---

# CBSA Unemployment Rate Data (LAUS)

This folder also documents the raw CBSA-level unemployment rate data used as a local
labor market control variable in Chapter 2.

## Source

CBSA-level unemployment rate data are obtained from the **U.S. Bureau of Labor Statistics (BLS)**
through the **Local Area Unemployment Statistics (LAUS)** program.

The LAUS program provides monthly labor market statistics for metropolitan areas,
including unemployment rates, employment levels, and labor force measures.

Official source:
https://www.bls.gov/lau/

Raw time-series files are downloaded from the BLS public data repository:
https://download.bls.gov/pub/time.series/la/

## Coverage and vintages

The analysis uses **monthly unemployment rate data** for **Metropolitan Statistical Areas (MSAs)**,
reported at the CBSA level.

To match the study period in Chapter 2, the raw LAUS data are restricted to:

- Geographic coverage: **Metropolitan Statistical Areas (CBSA / MSA)**
- Time coverage: **January 2018 – December 2024**
- Frequency: **Monthly**

The data are compiled from the standard LAUS text files provided by BLS and merged
into a single raw dataset prior to transformation.

## Geographic identifiers and alignment

LAUS geographic units are identified using official **BLS area codes**, from which
the corresponding **5-digit CBSA codes** are extracted.

CBSA identifiers follow the Office of Management and Budget (OMB) metropolitan area
definitions and are aligned with:

- CBSA population data from the U.S. Census Bureau
- HMDA loan-level data, which also use 5-digit CBSA codes

This alignment ensures consistent geographic matching across all Chapter 2 datasets.

## Raw files (not committed to Git)

The raw LAUS data consist of the following text files:

- `la.area.txt`
- `la.series.txt`
- `la.measure.txt`
- `la.data.60.Metro.txt`

These files are downloaded directly from the BLS website and are **not committed to GitHub**.

## Notes

- The unemployment rate is reported as a **percentage of the labor force**.
- Only Metropolitan Statistical Areas (MSAs) are retained; micropolitan areas are excluded.
- Raw LAUS files are never modified.
- All transformations and variable construction are performed in reproducible scripts
  located in the `code/ch02/` directory.

  ---

  # CBSA Building Permits Data (BPS)

This section documents the raw CBSA-level building permits data used as a local
housing supply / construction activity control variable in Chapter 2.

## Source

Building permits data are obtained from the **U.S. Census Bureau’s Building Permits Survey (BPS)**.
The BPS provides monthly permit counts for geographic areas including CBSAs (MSAs).

## Coverage and formats

To cover the full Chapter 2 study period, CBSA-level monthly permits are compiled from
two raw formats provided by the Census Bureau:

- **TXT tables (early period)**: `tb3uYYYYMM.txt` (CBSA table)
- **Excel tables (later period)**: `msamonthly_YYYYMM.xls` / `msamonthly_YYYYMM.xlsx`

The unified panel targets **January 2018 – December 2024** at monthly frequency.

## Raw files (not committed to Git)

Place raw inputs under:

- `data/raw/ch02/control_variables/bps/txt/`:
  - `tb3u201801.txt`, `tb3u201802.txt`, ... (one file per month)

- `data/raw/ch02/control_variables/bps/excel/`:
  - `msamonthly_201911.xls`, `msamonthly_201912.xls`, ... (one file per month)

Raw datasets are never modified and should not be committed to GitHub.

## Notes

- The series used is **Total permits** for each CBSA-month.
- CBSA identifiers are standardized as official **5-digit CBSA codes** to match HMDA and other CBSA-level controls.
