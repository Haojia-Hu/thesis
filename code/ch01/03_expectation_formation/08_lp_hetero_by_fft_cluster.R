# ==========================================================
# Purpose:
#   Use rolling FFT clustering results to split categories into groups, then estimate LP IRFs separately by group and compare interaction IRFs.
#
# Inputs:
#   - data/transformed/ch01/panel/panel_data.csv
#   - data/transformed/ch01/attention_cycle/rolling_fft_cluster_results.csv
#
# Outputs:
#   - data/output/ch01/local_projection/heterogeneity/rolling_fft_clusters/
#       - cluster_map_used.csv
#       - irf_group_pc.csv
#       - irf_group_vol.csv
#       - fig_irf_group_pc.png
#       - fig_irf_group_vol.png
# ==========================================================

library(tidyverse)
library(lubridate)
library(fixest)
library(broom)
library(ggplot2)
library(purrr)

# ==========================
# 0) Paths
# ==========================
panel_file <- "data/transformed/ch01/panel/panel_data.csv"
cluster_file <- "data/transformed/ch01/attention_cycle/rolling_fft_cluster_results.csv"

out_dir <- "data/output/ch01/local_projection/heterogeneity/rolling_fft_clusters"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_map <- file.path(out_dir, "cluster_map_used.csv")
out_pc  <- file.path(out_dir, "irf_group_pc.csv")
out_vol <- file.path(out_dir, "irf_group_vol.csv")
fig_pc  <- file.path(out_dir, "fig_irf_group_pc.png")
fig_vol <- file.path(out_dir, "fig_irf_group_vol.png")

# ==========================
# 1) Load data
# ==========================
panel_df <- read_csv(panel_file, show_col_types = FALSE) %>%
  mutate(Date = ymd(Date))

cluster_raw <- read_csv(cluster_file, show_col_types = FALSE)

# ==========================
# 2) Extract (category, cluster) mapping
#    Try to auto-detect the cluster column name
# ==========================
if (!("category" %in% names(cluster_raw))) {
  stop("rolling_fft_cluster_results.csv must contain a 'category' column.")
}

candidate_cluster_cols <- c("cluster", "Cluster", "cluster_id", "group", "Group", "final_cluster")
cluster_col <- candidate_cluster_cols[candidate_cluster_cols %in% names(cluster_raw)][1]

if (is.na(cluster_col)) {
  stop(
    "Cannot find a cluster column in rolling_fft_cluster_results.csv. ",
    "Expected one of: ", paste(candidate_cluster_cols, collapse = ", "),
    ". Found columns: ", paste(names(cluster_raw), collapse = ", ")
  )
}

cluster_map <- cluster_raw %>%
  select(category, cluster = all_of(cluster_col)) %>%
  distinct() %>%
  mutate(
    category = as.character(category),
    cluster = as.character(cluster)
  ) %>%
  drop_na(category, cluster)

# Optional: enforce only 2 groups (if your clustering is 2-cluster)
# If you have more clusters, the script will still run but will create
# separate outputs for each cluster label (and plots will overlay multiple groups).
cluster_levels <- sort(unique(cluster_map$cluster))

write_csv(cluster_map, out_map)

message("Using cluster column: ", cluster_col)
message("Cluster labels found: ", paste(cluster_levels, collapse = ", "))

# ==========================
# 3) Merge cluster labels into panel and build interactions
# ==========================
required_cols <- c(
  "Date","category","diff_index","D_InflationExp",
  "Diff_PriceChange","Diff_Volatility",
  "D_CpiAgg","D_EPU","D_ConsumerSent","D_Unemployment","D_RDI","D_Mortgage"
)
missing_cols <- setdiff(required_cols, names(panel_df))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "))

panel_df2 <- panel_df %>%
  left_join(cluster_map, by = "category") %>%
  filter(!is.na(cluster)) %>%
  group_by(category) %>%
  arrange(Date) %>%
  mutate(
    L1_diff_index   = lag(diff_index),
    Interaction_PC  = Diff_PriceChange * L1_diff_index,
    Interaction_Vol = Diff_Volatility  * L1_diff_index
  ) %>%
  ungroup()

# ==========================
# 4) LP runner (IMPORTANT: lead computed within category)
# ==========================
run_lp_models <- function(data, interaction_var, y_var = "D_InflationExp", h_max = 12) {

  horizons <- 1:h_max

  map(horizons, function(h) {

    df_h <- data %>%
      group_by(category) %>%
      arrange(Date) %>%
      mutate(y_lead = lead(.data[[y_var]], h)) %>%
      ungroup()

    feols(
      as.formula(
        paste0("y_lead ~ Diff_PriceChange + Diff_Volatility + L1_diff_index + ",
               interaction_var,
               " + D_CpiAgg + D_EPU + D_ConsumerSent + D_Unemployment + D_RDI + D_Mortgage | category")
      ),
      data = df_h
    )
  })
}

get_irf_df <- function(models, term_name, group_label) {
  horizons <- seq_along(models)
  map2_dfr(models, horizons, function(model, h) {
    tb <- tidy(model)
    row <- tb %>% filter(term == term_name)
    tibble(
      h = h,
      estimate = row$estimate,
      std_error = row$std.error,
      conf.low = row$estimate - 1.96 * row$std.error,
      conf.high = row$estimate + 1.96 * row$std.error,
      cluster = group_label
    )
  })
}

# ==========================
# 5) Estimate by cluster and collect IRFs
# ==========================
h_max <- 12

irf_pc_all <- map_dfr(cluster_levels, function(cl) {
  df_g <- panel_df2 %>% filter(cluster == cl)
  models <- run_lp_models(df_g, "Interaction_PC", h_max = h_max)
  get_irf_df(models, "Interaction_PC", cl)
})

irf_vol_all <- map_dfr(cluster_levels, function(cl) {
  df_g <- panel_df2 %>% filter(cluster == cl)
  models <- run_lp_models(df_g, "Interaction_Vol", h_max = h_max)
  get_irf_df(models, "Interaction_Vol", cl)
})

write_csv(irf_pc_all, out_pc)
write_csv(irf_vol_all, out_vol)

# ==========================
# 6) Plot (overlay clusters)
# ==========================
p1 <- ggplot(irf_pc_all, aes(x = h, y = estimate, shape = cluster, group = cluster)) +
  geom_line(linewidth = 1.0, color = "black") +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "gray80", alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Impact of Attention × Price Change on Inflation Expectations (by Rolling-FFT Cluster)",
    x = "Months Ahead (h)",
    y = "Coefficient Estimate",
    shape = "Cluster"
  ) +
  theme_minimal(base_size = 14)

ggsave(fig_pc, plot = p1, width = 8.2, height = 5.2, dpi = 300)

p2 <- ggplot(irf_vol_all, aes(x = h, y = estimate, shape = cluster, group = cluster)) +
  geom_line(linewidth = 1.0, color = "black") +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), fill = "gray80", alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Impact of Attention × Price Volatility on Inflation Expectations (by Rolling-FFT Cluster)",
    x = "Months Ahead (h)",
    y = "Coefficient Estimate",
    shape = "Cluster"
  ) +
  theme_minimal(base_size = 14)

ggsave(fig_vol, plot = p2, width = 8.2, height = 5.2, dpi = 300)
