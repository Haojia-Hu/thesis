# Raw Data: Category-level CPI

This section documents **raw CPI index data by consumption category** used in Chapter 1 to construct category-level price changes and price volatility.

### Data source

Category-level CPI indices are downloaded from the **U.S. Bureau of Labor Statistics (BLS)**:

https://data.bls.gov/PDQWeb/cu

### Category selection

CPI indices are collected for **11 major consumption categories** (same as before) used throughout
Chapter 1:

- Apparel
- Communication
- Education
- Energy
- Food and beverages
- Housing
- Medical care
- Personal care
- Recreation
- Tobacco and smoking products
- Transportation

### Raw file format and location

Raw CPI data are downloaded from the BLS website as **Excel (`.xlsx`) files**
and placed under:

data/raw/ch01/cpi_categories

Each Excel file corresponds to one CPI category and contains:
- a `Year` column
- monthly CPI index columns (`Jan`–`Dec`)
- additional half-year summary columns (e.g. `HALF1`, `HALF2`) that are ignored
  during preprocessing

The exact filenames are flexible; category identification is based on keywords
in the filename.

### Use in the repository

Raw CPI Excel files are processed by:

code/ch01/03_expectation_formation/03_ingest_category_cpi.R


The script converts the raw Excel tables into **monthly, category-level CPI series**
used as inputs for downstream price-change and volatility construction.
