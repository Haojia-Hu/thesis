## Google Trends data

This project uses monthly Google Trends exports
(https://trends.google.com/trends/).

Files should be placed locally under:
- data/raw/gt/

Each CSV file corresponds to a consumption category and contains
monthly search intensity for multiple keywords, downloaded directly
from Google Trends (overall 11 main categories).

Examples (not included):
- apparel.csv
- food.csv
- housing.csv

Raw Google Trends files are not tracked in this repository.

To construct category-level attention indices, run:
- code/ch01/01_index/01_build_attention_index.R
