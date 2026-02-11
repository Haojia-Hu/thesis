# ============================================================
# LP-IV: Dynamic response of Zillow new listings to mortgage rate gap
#
# PURPOSE
#   Estimate local-projection IV (LP-IV) impulse responses of new listings to the
#   mortgage rate gap using the Bartik instrument (Z_bartik).
#
# Input
#   1) First-stage panel (rate gap + instrument + controls, CBSA-by-month):
#      thesis/data/transformed/ch02/rate_gap/Panel_rategap_hat.csv
#      Required columns: cbsa_code, ym, rate_gap, Z_bartik
#
#   2) Zillow new listings proxy (CBSA-by-month):
#      thesis/data/transformed/ch02/zillow/zillow_newlisting.csv
#      Required columns: cbsa_code, yearmon, proxy_value
#
# Output
#   1) LP-IV coefficient table:
#      thesis/data/output/ch02/housing_quant/lp_iv_new_listings_irf.csv
#
#   2) IRF plot (png):
#      thesis/data/output/ch02/housing_quant/lp_iv_new_listings_irf.png
#
# NOTES
#   - CBSA and month fixed effects are included in each horizon regression.
#   - Standard errors are clustered by CBSA.
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(purrr)
  library(fixest)
  library(ggplot2)
  library(stringr)
  library(lubridate)
  library(zoo)
  library(tibble)
})

# ---------------- Paths ----------------
base_dir <- file.path("thesis")

path_rategap <- file.path(base_dir, "data", "transformed", "ch02", "rate_gap", "Panel_rategap_hat.csv")
path_newlist <- file.path(base_dir, "data", "transformed", "ch02", "zillow", "zillow_newlisting.csv")

out_dir <- file.path(base_dir, "data", "output", "ch02", "housing_quant")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_csv <- file.path(out_dir, "lp_iv_new_listings_irf.csv")
out_png <- file.path(out_dir, "lp_iv_new_listings_irf.png")

# ---------------- Checks ----------------
if (!file.exists(path_rategap)) stop("Missing input: ", path_rategap, call. = FALSE)
if (!file.exists(path_newlist)) stop("Missing input: ", path_newlist, call. = FALSE)

# ---------------- Read inputs ----------------
rategap <- read_csv(path_rategap, show_col_types = FALSE) %>%
  mutate(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym = as.Date(as.yearmon(as.character(ym)))   # ym like "2018-08"
  )

need_rg <- c("cbsa_code", "ym", "rate_gap", "Z_bartik")
miss_rg <- setdiff(need_rg, names(rategap))
if (length(miss_rg) > 0) stop("Panel_rategap_hat missing: ", paste(miss_rg, collapse = ", "), call. = FALSE)

newlisting <- read_csv(path_newlist, show_col_types = FALSE) %>%
  transmute(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym = as.Date(as.yearmon(as.character(yearmon))),
    new_listing = as.numeric(proxy_value)
  )

# Merge
panel_lp <- rategap %>%
  left_join(newlisting, by = c("cbsa_code", "ym")) %>%
  arrange(cbsa_code, ym)

# ---------------- Build lead outcomes h=0..12 ----------------
panel_lp <- panel_lp %>%
  group_by(cbsa_code) %>%
  arrange(ym) %>%
  mutate(newlist_h0 = new_listing) %>%
  ungroup()

for (h in 1:12) {
  panel_lp <- panel_lp %>%
    group_by(cbsa_code) %>%
    arrange(ym) %>%
    mutate(!!paste0("newlist_h", h) := lead(new_listing, h)) %>%
    ungroup()
}

# ---------------- LP-IV estimation ----------------
iv_lp_newlisting <- function(h, df) {
  y_var <- paste0("newlist_h", h)

  # Drop NA for the horizon-specific outcome
  dsub <- df %>% filter(!is.na(.data[[y_var]]), !is.na(rate_gap), !is.na(Z_bartik))

  fml <- as.formula(paste0(y_var, " ~ 1 | cbsa_code + ym | rate_gap ~ Z_bartik"))

  res <- feols(fml, data = dsub, cluster = ~ cbsa_code)

  tibble(
    horizon = h,
    beta = unname(coef(res)[1]),
    se   = unname(se(res)[1]),
    N    = nobs(res)
  )
}

horizons <- 1:12
results_lp_newlisting <- map_dfr(horizons, ~ iv_lp_newlisting(.x, panel_lp)) %>%
  mutate(
    ci_lo = beta - 1.96 * se,
    ci_hi = beta + 1.96 * se
  )

# Save results table
write_csv(results_lp_newlisting, out_csv)

# ---------------- Plot IRF ----------------
p <- ggplot(results_lp_newlisting, aes(x = horizon, y = beta)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2) +
  labs(
    title = "LP-IV: Dynamic Response of New Listings to Mortgage Rate Gap",
    x = "Horizon (months)",
    y = "Effect on new listings (level units)"
  ) +
  theme_minimal()

ggsave(out_png, p, width = 8, height = 5, dpi = 300)

cat("Wrote:\n- ", out_csv, "\n- ", out_png, "\n", sep = "")
