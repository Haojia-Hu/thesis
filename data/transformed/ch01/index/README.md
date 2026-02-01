# Transformed Data: Attention Index

This directory stores category-level attention indices constructed from raw
Google Trends data for Chapter 1 of the dissertation.

## Data Construction Pipeline

The attention data in this directory are generated as part of a multi-step
transformation pipeline:

1. **Attention Index Construction**

   - Script:
     - `code/ch01/01_index/01_build_attention_index.R`
   - Output:
     - `*_index.csv`

   These files contain category-level attention indices constructed directly
   from raw Google Trends data.

2. **Trend and Seasonality Removal**

   - Script:
     - `code/ch01/01_index/03_detrend_and_difference.R`
   - Outputs:
     - `data/transformed/ch01/residual/*_residual.csv`

   In this step, a quadratic time trend and month fixed effects are removed
   from each category-level attention index. The resulting residual series
   capture short- and medium-run fluctuations in consumer attention.

3. **First Differencing**

   - Script:
     - `code/ch01/01_index/03_detrend_and_difference.R`
   - Outputs:
     - `data/transformed/ch01/diff/*_diff.csv`

   First differences of the residual attention indices are constructed and
   treated as stationary inputs for regression and local projection analyses.

## Notes

- All transformed series are generated locally and are not tracked in the
  repository.
- All outputs are fully reproducible using the scripts in
  `code/ch01/01_index/`.
