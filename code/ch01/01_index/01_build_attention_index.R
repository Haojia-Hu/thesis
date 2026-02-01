library(tidyverse)
library(lubridate)

# =========================
# Purpose:
#   1) Build category-level attention indices from raw Google Trends exports.
#
#   2) Input (not tracked):
#   - data/raw/ch01/gt/*.csv
#     Each file is a Google Trends export with monthly data.
#
#   3) Output (not tracked):
#   - data/transformed/ch01/index/*_index.csv
#
# Notes:
# - Raw files are not modified.
# - Weights are defined below for each category.
# =========================

# ---- Repo-relative paths ----
gt_dir    <- file.path("data", "raw", "gt")
out_dir   <- file.path("data", "transformed", "index")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Core function ----
combine_index <- function(file_path, weights_table, out_dir) {

  filename <- tools::file_path_sans_ext(basename(file_path))

  # Google Trends exports often have 2 header rows
  df <- read_csv(file_path, skip = 2, show_col_types = FALSE)

  df_long <- df %>%
    rename(Month = 1) %>%
    pivot_longer(-Month, names_to = "Keyword", values_to = "Value") %>%
    mutate(Date = ym(Month))

  index_df <- df_long %>%
    left_join(weights_table, by = "Keyword") %>%
    mutate(weighted_value = Value * Weight) %>%
    group_by(Date) %>%
    summarise(Index = sum(weighted_value, na.rm = TRUE), .groups = "drop")

  output_path <- file.path(out_dir, paste0(filename, "_index.csv"))
  write_csv(index_df, output_path)

  message("Saved: ", output_path)
  invisible(index_df)
}

# ---- Category weights + file paths ----
# Note: file names here must match what you place under data/raw/gt/
# e.g., data/raw/gt/apparel.csv, data/raw/gt/communication.csv, etc.

weights_apparel <- tribble(
  ~Keyword,                      ~Weight,
  "Clothing: (United States)",    0.694,
  "Shoes: (United States)",       0.23,
  "Jewellery: (United States)",   0.058,
  "Watch: (United States)",       0.019
)
combine_index(file.path(gt_dir, "apparel.csv"), weights_apparel, out_dir)

weights_communication <- tribble(
  ~Keyword,                                  ~Weight,
  "Postage stamp: (United States)",           0.25,
  "Delivery: (United States)",                0.25,
  "Computer hardware: (United States)",       0.329,
  "Information technology: (United States)",  0.086,
  "Landline: (United States)",                0.085
)
combine_index(file.path(gt_dir, "communication.csv"), weights_communication, out_dir)

weights_education <- tribble(
  ~Keyword,                              ~Weight,
  "Tuition payments: (United States)",    0.845,
  "Child care: (United States)",          0.109,
  "Textbook: (United States)",            0.046
)
combine_index(file.path(gt_dir, "education.csv"), weights_education, out_dir)

weights_energy <- tribble(
  ~Keyword,                           ~Weight,
  "Electricity: (United States)",      0.3553,
  "Fuel: (United States)",             0.0152,
  "Natural gas: (United States)",      0.1011,
  "Propane: (United States)",          0.0017,
  "Gasoline: (United States)",         0.5266
)
combine_index(file.path(gt_dir, "energy.csv"), weights_energy, out_dir)

weights_food <- tribble(
  ~Keyword,                               ~Weight,
  "Bakery: (United States)",               0.0540,
  "Cereal: (United States)",               0.0262,
  "Coffee: (United States)",               0.0136,
  "Meat: (United States)",                 0.1050,
  "Fruit: (United States)",                0.0589,
  "Cooking oil: (United States)",          0.0168,
  "Sauce: (United States)",                0.0221,
  "Salad dressing: (United States)",       0.0044,
  "Milk: (United States)",                 0.0215,
  "Vegetable: (United States)",            0.0573,
  "Cheese: (United States)",               0.0202,
  "Seafood: (United States)",              0.0196,
  "Egg: (United States)",                  0.0084,
  "Alcoholic beverage: (United States)",   0.0745,
  "Tea: (United States)",                  0.0051,
  "Sugar: (United States)",                0.0029,
  "Butter: (United States)",               0.0042,
  "Snack: (United States)",                0.0257,
  "Margarine: (United States)",            0.0010,
  "Soup: (United States)",                 0.0071,
  "Baby food: (United States)",            0.0038,
  "Food delivery: (United States)",        0.4476
)
combine_index(file.path(gt_dir, "food.csv"), weights_food, out_dir)

weights_housing <- tribble(
  ~Keyword,                              ~Weight,
  "Home appliance: (United States)",      0.0770,
  "Furniture: (United States)",           0.0794,
  "Home insurance: (United States)",      0.0146,
  "Rent: (United States)",                0.6264,
  "Lodging: (United States)",             0.2026
)
combine_index(file.path(gt_dir, "housing.csv"), weights_housing, out_dir)

weights_medical <- tribble(
  ~Keyword,                                     ~Weight,
  "Health insurance: (United States)",           0.6938,
  "Hospital: (United States)",                   0.1779,
  "Medical prescription: (United States)",       0.0330,
  "Pharmaceutical drug: (United States)",        0.0918,
  "Nursing home: (United States)",               0.0035
)
combine_index(file.path(gt_dir, "medical care.csv"), weights_medical, out_dir)

weights_personal <- tribble(
  ~Keyword,                                     ~Weight,
  "Personal care products: (United States)",     1.0
)
combine_index(file.path(gt_dir, "personal care.csv"), weights_personal, out_dir)

weights_recreation <- tribble(
  ~Keyword,                        ~Weight,
  "Recreation: (United States)",    1.0
)
combine_index(file.path(gt_dir, "recreation.csv"), weights_recreation, out_dir)

weights_tobacco <- tribble(
  ~Keyword,                           ~Weight,
  "Cigarette: (United States)",        0.8550,
  "Smoking pipe: (United States)",     0.1272,
  "Tobacco: (United States)",          0.0178
)
combine_index(file.path(gt_dir, "tobacco.csv"), weights_tobacco, out_dir)

weights_transportation <- tribble(
  ~Keyword,                           ~Weight,
  "Bus: (United States)",              0.0015,
  "Airline: (United States)",          0.0587,
  "Train: (United States)",            0.0130,
  "Ship: (United States)",             0.0073,
  "Metro: (United States)",            0.0029,
  "Vehicle: (United States)",          0.5711,
  "Motor: (United States)",            0.0087,
  "Gasoline: (United States)",         0.3368
)
combine_index(file.path(gt_dir, "transportation.csv"), weights_transportation, out_dir)
