# ============================================================
# Purpose: IV estimation: Mortgage Rate Gap -> Zillow lock-in proxies (2SLS)
#
# Input:
#   - data/transformed/ch02/rate_gap/Panel_rategap_hat.csv
#   - data/transformed/ch02/zillow/zillow_*.csv   (original names)
#
# Output:
#   - data/output/ch02/housing_quant/iv_lockin_proxies_2sls_results.csv
#
# Notes:
#   - Includes CBSA FE and month FE (factor cbsa_code + factor ym)
#   - Cluster-robust SE at CBSA level
#   - "Z-score" is computed using residual SDs after partialling out controls + FE
#     (new/spec you chose).
# ============================================================

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(stringr)
  library(purrr)
  library(AER)       # ivreg
  library(sandwich)  # vcovCL
  library(tibble)
})

# ---------------- paths ----------------
panel_fp <- file.path("data", "transformed", "ch02", "rate_gap", "Panel_rategap_hat.csv")

zillow_dir <- file.path("data", "transformed", "ch02", "zillow")
z_invt_fp  <- file.path(zillow_dir, "zillow_invt.csv")
z_newl_fp  <- file.path(zillow_dir, "zillow_newlisting.csv")
z_pend_fp  <- file.path(zillow_dir, "zillow_newlypending.csv")
z_dtp_fp   <- file.path(zillow_dir, "zillow_daytopending.csv")
z_cut_fp   <- file.path(zillow_dir, "zillow_sharepricecut.csv")

out_dir <- file.path("data", "output", "ch02", "housing_quant")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

out_fp <- file.path(out_dir, "iv_lockin_proxies_2sls_results.csv")

# ---------------- checks ----------------
must_exist <- c(panel_fp, z_invt_fp, z_newl_fp, z_pend_fp, z_dtp_fp, z_cut_fp)
missing <- must_exist[!file.exists(must_exist)]
if (length(missing) > 0) {
  stop("Missing required input files:\n- ", paste(missing, collapse = "\n- "), call. = FALSE)
}

# ---------------- helpers ----------------
read_proxy <- function(fp, newname) {
  fread(fp) %>%
    transmute(
      cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
      ym        = as.character(yearmon),
      !!newname := as.numeric(proxy_value)
    ) %>%
    distinct(cbsa_code, ym, .keep_all = TRUE)
}

.extract_diag <- function(fit) {
  # Works across AER versions: diagnostics table may vary
  s <- summary(fit, diagnostics = TRUE)
  diag_tbl <- tryCatch(s$diagnostics, error = function(e) NULL)

  get_stat <- function(tbl, pattern, col) {
    if (is.null(tbl)) return(NA_real_)
    rn <- rownames(tbl)
    hit <- which(grepl(pattern, rn, ignore.case = TRUE))
    if (length(hit) == 0) return(NA_real_)
    as.numeric(tbl[hit[1], col, drop = TRUE])
  }

  list(
    KP_F     = get_stat(diag_tbl, "Kleibergen|Weak instruments", "statistic"),
    AR_p     = get_stat(diag_tbl, "Anderson|Anderson.?Rubin",    "p-value"),
    Wu_p     = get_stat(diag_tbl, "Wu.?Hausman|Wu-?Hausman",     "p-value"),
    Sargan_p = get_stat(diag_tbl, "Sargan|Basmann|Hansen",       "p-value")
  )
}

.partialled_sds <- function(fit, yvar, xvar) {
  # Use exact 2SLS sample used by ivreg
  mf <- model.frame(fit)

  # "term.labels" gives RHS terms for the structural equation
  all_terms <- attr(terms(fit), "term.labels")
  ctrls <- setdiff(all_terms, xvar)  # drop endogenous regressor to get controls + FE

  f_y <- as.formula(paste(yvar, "~", paste(ctrls, collapse = " + ")))
  y_res <- resid(lm(f_y, data = mf, na.action = na.omit))

  f_x <- as.formula(paste(xvar, "~", paste(ctrls, collapse = " + ")))
  x_res <- resid(lm(f_x, data = mf, na.action = na.omit))

  c(sd_y = sd(y_res, na.rm = TRUE), sd_x = sd(x_res, na.rm = TRUE))
}

run_iv_one <- function(depvar, data_panel) {
  # 2SLS with FE and controls:
  # dep ~ rate_gap + controls + FE | Z + controls + FE
  fml <- as.formula(paste0(
    depvar, " ~ rate_gap + unemployment_rate + mig_rate_month + bps_total + cbsa_code + ym | ",
    "Z_bartik + unemployment_rate + mig_rate_month + bps_total + cbsa_code + ym"
  ))

  fit <- ivreg(fml, data = data_panel, x = TRUE, y = TRUE, model = TRUE)
  mf  <- model.frame(fit) # ensures cluster var aligns with regression sample

  vc_cl <- vcovCL(fit, cluster = ~ cbsa_code, data = mf)

  beta_raw <- unname(coef(fit)["rate_gap"])
  se_raw   <- sqrt(diag(vc_cl))["rate_gap"]

  sds <- .partialled_sds(fit, yvar = depvar, xvar = "rate_gap")
  scale_fx <- sds["sd_x"] / sds["sd_y"]

  beta_std <- beta_raw * scale_fx
  se_std   <- se_raw   * scale_fx

  dg <- .extract_diag(fit)

  tibble(
    proxy    = depvar,
    n_obs    = nrow(mf),
    beta_raw = beta_raw,
    se_raw   = se_raw,
    beta_z   = beta_std,
    se_z     = se_std,
    KP_F     = dg$KP_F,
    AR_p     = dg$AR_p,
    Wu_p     = dg$Wu_p,
    Sargan_p = dg$Sargan_p
  )
}

# ---------------- load inputs ----------------
# Stage-1 panel (rate gap + IV + controls)
panel_core <- fread(panel_fp) %>%
  mutate(
    cbsa_code = str_pad(as.character(cbsa_code), 5, pad = "0"),
    ym        = as.character(ym)
  )

req_cols <- c("cbsa_code","ym","rate_gap","Z_bartik","unemployment_rate","mig_rate_month","bps_total")
miss_cols <- setdiff(req_cols, names(panel_core))
if (length(miss_cols) > 0) {
  stop("Panel_rategap_hat is missing required columns: ",
       paste(miss_cols, collapse = ", "), call. = FALSE)
}

# Zillow outcomes (separate files, original names)
inv      <- read_proxy(z_invt_fp, "proxy_invt")
newl     <- read_proxy(z_newl_fp, "proxy_newlist")
pend     <- read_proxy(z_pend_fp, "proxy_pending")
daytp    <- read_proxy(z_dtp_fp,  "proxy_days")
pricecut <- read_proxy(z_cut_fp,  "proxy_cut")

proxy_all <- reduce(list(inv, newl, pend, daytp, pricecut),
                    full_join, by = c("cbsa_code","ym"))

# Combine
panel <- panel_core %>%
  left_join(proxy_all, by = c("cbsa_code","ym")) %>%
  filter(
    !is.na(rate_gap),
    !is.na(Z_bartik),
    !is.na(unemployment_rate),
    !is.na(mig_rate_month),
    !is.na(bps_total)
  ) %>%
  mutate(
    cbsa_code = as.factor(cbsa_code),
    ym        = as.factor(ym)
  )

cat("Panel summary (pre-outcome-specific NA drops):\n")
cat("  rows:", nrow(panel), "\n")
cat("  CBSAs:", n_distinct(panel$cbsa_code), "\n")
cat("  months:", n_distinct(panel$ym), "\n\n")

# ---------------- run IV for each proxy ----------------
proxy_cols <- c("proxy_invt","proxy_newlist","proxy_pending","proxy_days","proxy_cut")
res <- map_dfr(proxy_cols, run_iv_one, data_panel = panel)

# Long-format output (two specs per proxy)
out_long <- bind_rows(
  res %>% transmute(proxy, spec = "Raw(1pp)", n_obs, beta = beta_raw, se = se_raw, KP_F, AR_p, Wu_p, Sargan_p),
  res %>% transmute(proxy, spec = "Z-score (partialled)", n_obs, beta = beta_z, se = se_z, KP_F, AR_p, Wu_p, Sargan_p)
) %>%
  arrange(proxy, spec)

fwrite(out_long, out_fp)
cat("Wrote:", out_fp, "\n")
