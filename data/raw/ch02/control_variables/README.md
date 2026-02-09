# CBSA Population Data 

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
