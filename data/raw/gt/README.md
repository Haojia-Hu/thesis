## Google Trends data

This project uses monthly Google Trends exports
(https://trends.google.com/trends/).

Files should be placed locally under:
- data/raw/gt/

Each CSV file corresponds to one consumption category
(e.g., apparel.csv, food.csv, housing.csv).

Raw Google Trends files are not tracked in this repository.

To construct category-level attention indices, run:
- code/ch01/01_index/01_build_attention_index.R
