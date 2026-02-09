# Control Variables

This folder contains scripts used to construct control variables for the Chapter 2 empirical analysis.

---

## migration_monthly.R

**Purpose**  
Construct a CBSA-by-month population-based control variable using annual CBSA
population estimates from the U.S. Census Bureau.

**Description**  
This script converts annual CBSA population levels (July 1 estimates) into a
monthly CBSA panel via linear interpolation and computes monthly population
changes and growth rates as proxies for local migration dynamics.

**Output**  
- `cbsa_migration_monthly.csv`  
  (stored in `data/transformed/ch02/controls/`)

**Time coverage**  
- **July 2018 – July 2024** (monthly)

---


