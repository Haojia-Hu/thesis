# Raw Data: Google Trends

This project uses **monthly Google Trends exports**:
https://trends.google.com/trends/

Raw Google Trends CSV files should be placed under:

data/raw/ch01/gt/


Each CSV file corresponds to one consumption category and contains monthly search intensity for **multiple keywords** (overall 11 main categories), downloaded directly from Google Trends.

### Time coverage

All Google Trends series used in this project span:

- **January 2004 to December 2024** (monthly)

### Examples (not included)

- `apparel.csv`
- `food.csv`
- `housing.csv`

Raw Google Trends files are not tracked in this repository.

### Use in the repository

To construct category-level attention indices, run:

code/ch01/01_index/01_build_attention_index.R

Appendix:
<img width="1039" height="953" alt="fig1" src="https://github.com/user-attachments/assets/7f35807e-48ce-4dce-8664-cb4970a47be3" />
