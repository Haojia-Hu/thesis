library(tidyverse)
library(lubridate)

### Build formula
combine_index <- function(file_path, weights_table) {
    # file name
    filename <- tools::file_path_sans_ext(basename(file_path))
    
    # Read file
    df <- read_csv(file_path, skip = 2)
    
    # Rearrange timeline
    df_long <- df %>%
        rename(Month = 1) %>%
        pivot_longer(-Month, names_to = "Keyword", values_to = "Value") %>%
        #mutate(Date = parse_date_time(Month, orders = "b-y")) 
        mutate(Date = ym(Month))
    
    # Combined indexes
    index_df <- df_long %>%
        left_join(weights_table, by = "Keyword") %>%
        mutate(weighted_value = Value * Weight) %>%
        group_by(Date) %>%
        summarise(Index = sum(weighted_value, na.rm = TRUE), .groups = "drop")
    
    # Save file
    # output_path <- paste0("C:/Users/huwen/Desktop/Data/Result/index/i", filename, ".csv")
    output_path <- paste0("C:/Users/huwen/Desktop/Data/Result/index/", filename, "_index.csv")
    write_csv(index_df, output_path)
    
    message("Saved: ", output_path)
}

### Apparel
weights_apparel <- tribble(
    ~Keyword,                     ~Weight,
    "Clothing: (United States)",   0.694,
    "Shoes: (United States)",      0.23,
    "Jewellery: (United States)",  0.058,
    "Watch: (United States)",      0.019
)
# Path
file_path_apparel <- "C:/Users/huwen/Desktop/Data/index/GT/apparel.csv"
# Use formula
combine_index(file_path_apparel, weights_apparel)


### Communication
weights_communication <- tribble(
    ~Keyword,                                 ~Weight,
    "Postage stamp: (United States)",          0.25,
    "Delivery: (United States)",               0.25,
    "Computer hardware: (United States)",      0.329,
    "Information technology: (United States)", 0.086,
    "Landline: (United States)",               0.085
)
file_path_communication <- "C:/Users/huwen/Desktop/Data/index/GT/communication.csv"
combine_index(file_path_communication, weights_communication)

### Education
weights_education <- tribble(
    ~Keyword,                             ~Weight,
    "Tuition payments: (United States)",   0.845,
    "Child care: (United States)",         0.109,
    "Textbook: (United States)",           0.046
)
file_path_education <- "C:/Users/huwen/Desktop/Data/index/GT/education.csv"
combine_index(file_path_education, weights_education)


### Energy
weights_energy <- tribble(
    ~Keyword,                          ~Weight,
    "Electricity: (United States)",     0.3553,
    "Fuel: (United States)",            0.0152,
    "Natural gas: (United States)",     0.1011,
    "Propane: (United States)",         0.0017,
    "Gasoline: (United States)",        0.5266
)
file_path_energy <- "C:/Users/huwen/Desktop/Data/index/GT/energy.csv"
combine_index(file_path_energy, weights_energy)


### Food
weights_food <- tribble(
    ~Keyword,                              ~Weight,
    "Bakery: (United States)",              0.0540,
    "Cereal: (United States)",              0.0262,
    "Coffee: (United States)",              0.0136,
    "Meat: (United States)",                0.1050,
    "Fruit: (United States)",               0.0589,
    "Cooking oil: (United States)",         0.0168,
    "Sauce: (United States)",               0.0221,
    "Salad dressing: (United States)",      0.0044,
    "Milk: (United States)",                0.0215,
    "Vegetable: (United States)",           0.0573,
    "Cheese: (United States)",              0.0202,
    "Seafood: (United States)",             0.0196,
    "Egg: (United States)",                 0.0084,
    "Alcoholic beverage: (United States)",  0.0745,
    "Tea: (United States)",                 0.0051,
    "Sugar: (United States)",               0.0029,
    "Butter: (United States)",              0.0042,
    "Snack: (United States)",               0.0257,
    "Margarine: (United States)",           0.0010,
    "Soup: (United States)",                0.0071,
    "Baby food: (United States)",           0.0038,
    "Food delivery: (United States)",       0.4476
)
file_path_food <- "C:/Users/huwen/Desktop/Data/index/GT/food.csv"
combine_index(file_path_food, weights_food)


### Housing
weights_housing <- tribble(
    ~Keyword,                             ~Weight,
    "Home appliance: (United States)",     0.0770,
    "Furniture: (United States)",          0.0794,
    "Home insurance: (United States)",     0.0146,
    "Rent: (United States)",               0.6264,
    "Lodging: (United States)",            0.2026
)
file_path_housing <- "C:/Users/huwen/Desktop/Data/index/GT/housing.csv"
combine_index(file_path_housing, weights_housing)


### Medical care
weights_medical <- tribble(
    ~Keyword,                                    ~Weight,
    "Health insurance: (United States)",          0.6938,
    "Hospital: (United States)",                  0.1779,
    "Medical prescription: (United States)",      0.0330,
    "Pharmaceutical drug: (United States)",       0.0918,
    "Nursing home: (United States)",              0.0035
)
file_path_medical <- "C:/Users/huwen/Desktop/Data/index/GT/medical care.csv"
combine_index(file_path_medical, weights_medical)


### Personal care
weights_personal <- tribble(
    ~Keyword,                                     ~Weight,
    "Personal care products: (United States)",     1
)
file_path_personal <- "C:/Users/huwen/Desktop/Data/index/GT/personal care.csv"
combine_index(file_path_personal, weights_personal)


### Recreation
weights_recreation <- tribble(
    ~Keyword,                       ~Weight,
    "Recreation: (United States)",   1.0
)
file_path_recreation <- "C:/Users/huwen/Desktop/Data/index/GT/recreation.csv"
combine_index(file_path_recreation, weights_recreation)


### tobacco
weights_tobacco <- tribble(
    ~Keyword,                          ~Weight,
    "Cigarette: (United States)",       0.8550,
    "Smoking pipe: (United States)",    0.1272,
    "Tobacco: (United States)",         0.0178
)
file_path_tobacco <- "C:/Users/huwen/Desktop/Data/index/GT/tobacco.csv"
combine_index(file_path_tobacco, weights_tobacco)


# Transportation
weights_transportation <- tribble(
    ~Keyword,                          ~Weight,
    "Bus: (United States)",             0.0015,
    "Airline: (United States)",         0.0587,
    "Train: (United States)",           0.0130,
    "Ship: (United States)",            0.0073,
    "Metro: (United States)",           0.0029,
    "Vehicle: (United States)",         0.5711,
    "Motor: (United States)",           0.0087,
    "Gasoline: (United States)",        0.3368
)
file_path_transportation <- "C:/Users/huwen/Desktop/Data/index/GT/transportation.csv"
combine_index(file_path_transportation, weights_transportation)
