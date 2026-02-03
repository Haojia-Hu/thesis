# Raw Data (Macroeconomic Controls)

This directory documents the **raw macroeconomic data inputs** used to construct macro controls for Chapter 1 analyses, including the Local Projection framework for inflation expectations.

Raw data files are **not included in the repository**. Instead, this folder provides documentation on **what data are required**, **where they come from**, and **how they are processed by the codebase**.

---

## Data source

All macroeconomic series used in Chapter 1 are obtained from the  
**Federal Reserve Bank of St. Louis FRED database**:

https://fred.stlouisfed.org/

Each raw file is named **exactly by its FRED series ID**, and stored as a CSV file.

---

## Required raw macro series

The following FRED series are required.  
Each file should be downloaded from FRED and saved as a CSV using the **series ID as the filename**.

| FRED series ID | Variable constructed | Description | Frequency |
|---|---|---|---|
| `DSPIC96` | `RDI` | Real Disposable Personal Income | Monthly |
| `UMCSENT` | `ConsumerSent` | University of Michigan Consumer Sentiment Index | Monthly |
| `UNRATE` | `Unemployment` | Unemployment Rate | Monthly |
| `USEPUINDXM` | `EPU` | Economic Policy Uncertainty Index (U.S.) | Monthly |
| `CPIAUCSL_PC1` | `CpiAgg` | CPI inflation rate (aggregate CPI) | Monthly |
| `MICH` | `InflationExp` | Michigan inflation expectations | Monthly |
| `MORTGAGE30US` | `MortgageRate` | 30-year fixed mortgage rate | Weekly |

---

## Raw file format requirements

### Monthly macro series

Each monthly CSV file should contain two columns:

1. A date column (interpreted as calendar date)
2. The series value

Typical FRED export format:

DATE,value
2000-01-01,...
2000-02-01,...
...


The preprocessing code will:
- rename the first column to `Date`
- parse dates using `YYYY-MM-DD`
- restrict the sample to **2000-01-01 through 2024-12-01**
- drop missing observations

---

### Weekly mortgage rate (`MORTGAGE30US`)

The weekly mortgage rate file typically contains:

- `observation_date`
- `MORTGAGE30US`

Example:

observation_date,MORTGAGE30US
2000-01-07,...
2000-01-14,...
...


This series is converted to a **monthly average mortgage rate** during preprocessing.

---

## How raw macro data are used in the repository

Raw macro data documented here are processed by the script:

code/ch01/03_expectation_formation/01_ingest_macro_raw.R

This script:
1. Cleans and standardizes all monthly macro series
2. Aggregates the weekly mortgage rate into a monthly series
3. Exports cleaned macro variables for downstream analysis

The cleaned outputs are then merged into the analysis-level panel used in:
- Local Projection regressions
- Fixed-effects regressions
- Robustness checks involving macro controls

---

## Version control note

Raw macro CSV files are **publicly available** from FRED but are not tracked in this repository.

The repository includes:
- Complete documentation of required inputs
- Fully reproducible preprocessing code
- Analysis-ready outputs generated from these raw inputs
