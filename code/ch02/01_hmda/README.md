# Chapter 2 — HMDA Data Preparation

This folder contains scripts that clean and prepare HMDA Loan/Application Records (LAR)
for constructing mortgage-rate measures used in Chapter 2.

All scripts in this folder operate on HMDA public LAR data and generate intermediate
loan-level datasets. Generated data files are not version controlled.

---

## Scripts

### 01_clean_hmda_lar_yearly.R

**Purpose**  
Clean raw HMDA public LAR files by year and retain the subset of loans required
for the mortgage lock-in analysis.

**Inputs (not version controlled)**  
- `data/raw/ch02/hmda_lar/{YEAR}_public_lar_csv.csv`, for YEAR = 2018–2024

**Outputs (generated, not version controlled)**  
- `data/transformed/ch02/01_hmda_clean/hmda_clean_{YEAR}.csv`

**Key operations**  
- Keep originated, first-lien, non-commercial, non-open-end, non-reverse mortgages  
- Restrict to fixed-rate style loans (`intro_rate_period == 0` or NA)  
- Retain only variables needed for rate-gap construction and controls  

---

### 02_combined_hmda.R

**Purpose**  
Combine yearly cleaned HMDA files into pooled loan-level datasets and select
fixed-rate mortgage samples by loan term.

**Inputs (generated, not version controlled)**  
- `data/transformed/ch02/01_hmda_clean/hmda_clean_{YEAR}.csv`, for YEAR = 2018–2024

**Outputs (generated, not version controlled)**  
- `data/transformed/ch02/02_combined_hmda/hmda_30y_clean.csv`  
- `data/transformed/ch02/02_combined_hmda/hmda_15y_clean.csv`

**Key operations**  
- Merge yearly cleaned HMDA files into a single loan-level dataset  
- Select 30-year fixed-rate mortgages (primary sample)  
- Retain 15-year fixed-rate mortgages for reference and robustness checks  

---

## Notes
- Raw HMDA data are never modified.  
- All generated datasets are reproducible using scripts in this folder.  
