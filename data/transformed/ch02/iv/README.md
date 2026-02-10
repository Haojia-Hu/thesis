# Instrumental Variables (IV)

This folder contains analysis-ready IV objects used in the Chapter 2 identification strategy.
All files here are generated reproducibly from raw interest-rate series and transformed HMDA data.

Key identifiers:
- `cbsa_code` (5-digit CBSA)
- `ym` (YYYY-MM)

---

## SS_IV.csv

**Purpose**  
Provide a monthly CBSA-level shift-share (Bartik) instrument constructed as:

- `Z_bartik_level_{i,t} = Exposure_i × NatShock_level_t`

where `NatShock_level_t` is a national mortgage-rate shock and `Exposure_i` is a time-invariant
CBSA exposure index derived from HMDA interest-rate distributions.

**Construction summary**
1. **National shock (`NatShock_level`)** is obtained from a monthly regression residual:
   - Aggregate weekly PMMS 30-year FRM rates to monthly averages.
   - Regress monthly PMMS rates on monthly 10-year Treasury yields (GS10).
   - Define `NatShock_level` as the regression residual.

2. **Exposure (`Exposure`)** is constructed from HMDA 30-year loan originations:
   - Use an exposure window (2018–2021) and loan-amount weights (optionally time-decayed).
   - Bin loan interest rates into predefined buckets.
   - Compress the bucket shares into a single index using PCA (first principal component),
     oriented such that higher low-rate share implies higher exposure.
   - Center the exposure index (demean) for compatibility with time fixed effects.

3. Combine `Exposure_i` and `NatShock_level_t` to obtain the Bartik instrument.

**Output file**
- `SS_IV.csv`

**Columns**
- `cbsa_code` : 5-digit CBSA code
- `ym` : month identifier (YYYY-MM)
- `Z_bartik_level` : exposure × monthly national shock
- `Z_bartik_cum` : exposure × cumulative national shock (optional diagnostic variant)
- `Exposure` : time-invariant CBSA exposure index (demeaned)
- `NatShock_level` : monthly national shock series (demeaned residual)

**Time coverage**
- **January 2018 – December 2024** (monthly)

**Geographic coverage**
- **Metropolitan Statistical Areas (CBSA level)**

---

## NatShock_monthly.csv

**Purpose**  
Store the monthly national mortgage-rate shock series used to construct the Bartik instrument.

**Output file**
- `NatShock_monthly.csv`

**Columns**
- `ym` : month identifier (YYYY-MM)
- `pmms_30y` : monthly average of weekly PMMS 30-year FRM rate
- `gs10` : monthly 10-year Treasury yield
- `NatShock_level` : residual from `pmms_30y ~ gs10`

**Time coverage**
- **January 2018 – December 2024** (monthly)

---

## Notes

- All objects are intended to merge cleanly on (`cbsa_code`, `ym`) with Chapter 2 panels.
- `SS_IV.csv` is an identification input and should be treated as upstream of any final panel.
