# ============================================================
# Chapter 2 - Control Variables
# BPS (Building Permits Survey): CBSA-by-month total permits
#
# Raw inputs (NOT committed):
#   data/raw/ch02/control_variables/bps/txt/tb3uYYYYMM.txt
#   data/raw/ch02/control_variables/bps/excel/msamonthly_YYYYMM.xls[x]
#
# Output:
#   data/transformed/ch02/control_variables/bps_cbsa_monthly.csv
# ============================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(readr)
  library(tidyr)
  library(purrr)
  library(readxl)
})

# ----------------------------
# Paths (edit only this block)
# ----------------------------
raw_base_dir <- file.path("data", "raw", "ch02", "control_variables", "bps")
raw_txt_dir  <- file.path(raw_base_dir, "txt")
raw_xls_dir  <- file.path(raw_base_dir, "excel")

out_dir  <- file.path("data", "transformed", "ch02", "control_variables")
out_file <- file.path(out_dir, "bps_cbsa_monthly.csv")

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ----------------------------
# Helpers
# ----------------------------
make_yearmon <- function(year, month) sprintf("%04d-%02d", as.integer(year), as.integer(month))

ym_seq <- function(start_ym, end_ym) {
  # start_ym/end_ym: "YYYYMM"
  sy <- as.integer(substr(start_ym, 1, 4)); sm <- as.integer(substr(start_ym, 5, 6))
  ey <- as.integer(substr(end_ym, 1, 4)); em <- as.integer(substr(end_ym, 5, 6))
  out <- c()
  y <- sy; m <- sm
  while (y < ey || (y == ey && m <= em)) {
    out <- c(out, sprintf("%04d%02d", y, m))
    m <- m + 1
    if (m == 13) { m <- 1; y <- y + 1 }
  }
  out
}

stop_missing <- function(msg) stop(msg, call. = FALSE)

# ----------------------------
# Part A: TXT parser (tb3uYYYYMM.txt)
# ----------------------------
parse_bps_txt_one <- function(txt_path, yyyymm) {
  lines <- readLines(txt_path, warn = FALSE)

  # Find header row containing CBSA and Total
  hdr_idx <- which(str_detect(lines, "\\bCBSA\\b") & str_detect(lines, "\\bTotal\\b"))[1]
  if (is.na(hdr_idx)) {
    stop_missing(paste0("Cannot find header row in txt file: ", basename(txt_path)))
  }

  dat_lines <- lines[(hdr_idx + 1):length(lines)]
  dat_lines <- dat_lines[dat_lines != ""]
  dat_lines <- dat_lines[!str_detect(dat_lines, "^\\s*Source:")]

  split_row <- function(x) str_split(str_squish(x), "\\s+", simplify = FALSE)[[1]]
  rows <- lapply(dat_lines, split_row)

  extract_cbsa_total <- function(tokens) {
    cbsa_pos <- which(str_detect(tokens, "^\\d{5}$"))[1]
    if (is.na(cbsa_pos)) return(NULL)

    cbsa <- tokens[cbsa_pos]
    after <- tokens[(cbsa_pos + 1):length(tokens)]

    # total = first numeric token after the (multi-token) name
    num_pos <- which(str_detect(after, "^\\d+$"))[1]
    if (is.na(num_pos)) return(NULL)

    total <- after[num_pos]
    tibble(cbsa = cbsa, total = as.numeric(total))
  }

  out <- purrr::map(rows, extract_cbsa_total) |> purrr::compact() |> bind_rows()
  if (nrow(out) == 0) {
    stop_missing(paste0("Parsed 0 rows from txt file: ", basename(txt_path)))
  }

  year  <- substr(yyyymm, 1, 4)
  month <- substr(yyyymm, 5, 6)

  out %>%
    mutate(
      yearmon = make_yearmon(year, month),
      cbsa = as.character(cbsa)
    ) %>%
    select(yearmon, cbsa, total)
}

read_bps_txt_panel <- function(start_ym, end_ym) {
  if (!dir.exists(raw_txt_dir)) {
    stop_missing(paste0("Missing directory: ", raw_txt_dir, "\nPlace tb3uYYYYMM.txt files here."))
  }

  yms <- ym_seq(start_ym, end_ym)
  paths <- file.path(raw_txt_dir, sprintf("tb3u%s.txt", yms))
  missing <- paths[!file.exists(paths)]

  if (length(missing) > 0) {
    stop_missing(
      paste0(
        "Missing BPS txt files under: ", raw_txt_dir, "\n",
        "Example missing file(s):\n - ", paste(head(basename(missing), 10), collapse = "\n - "), "\n"
      )
    )
  }

  purrr::map2(paths, yms, parse_bps_txt_one) %>% bind_rows()
}

# ----------------------------
# Part B: Excel parser (msamonthly_YYYYMM.xls/xlsx)
# ----------------------------
parse_bps_excel_one <- function(xls_path) {
  fn <- basename(xls_path)
  yyyymm <- str_match(fn, "(\\d{6})")[, 2]
  if (is.na(yyyymm)) stop_missing(paste0("Cannot extract YYYYMM from filename: ", fn))

  raw <- read_excel(xls_path, col_names = FALSE)

  header_row <- which(apply(raw, 1, function(r) any(str_detect(tolower(as.character(r)), "\\bcbsa\\b"))))[1]
  if (is.na(header_row)) stop_missing(paste0("Cannot locate header row containing 'CBSA' in: ", fn))

  df <- read_excel(xls_path, skip = header_row - 1)

  names(df) <- names(df) %>%
    str_replace_all("\\s+", "_") %>%
    str_replace_all("[^A-Za-z0-9_]+", "") %>%
    tolower()

  cbsa_col <- names(df)[str_detect(names(df), "^cbsa$|cbsa_code|cbsaid|cbsa_")][1]
  if (is.na(cbsa_col)) stop_missing(paste0("Cannot find CBSA column in: ", fn))

  total_candidates <- names(df)[str_detect(names(df), "total")]
  if (length(total_candidates) == 0) stop_missing(paste0("Cannot find any 'total' column in: ", fn))

  # Prefer a "current month total" column if present; fallback to first total column
  total_col <- total_candidates[str_detect(total_candidates, "current")][1]
  if (is.na(total_col)) total_col <- total_candidates[1]

  year  <- substr(yyyymm, 1, 4)
  month <- substr(yyyymm, 5, 6)

  df %>%
    transmute(
      yearmon = make_yearmon(year, month),
      cbsa    = as.character(.data[[cbsa_col]]),
      total   = suppressWarnings(as.numeric(.data[[total_col]]))
    ) %>%
    filter(!is.na(cbsa), cbsa != "", !is.na(total))
}

read_bps_excel_panel <- function(start_ym, end_ym) {
  if (!dir.exists(raw_xls_dir)) {
    # Excel is optional if you only have txt; return empty tibble
    return(tibble(yearmon = character(), cbsa = character(), total = numeric()))
  }

  xls_files <- list.files(
    raw_xls_dir,
    pattern = "(msamonthly_\\d{6}\\.xls|msamonthly_\\d{6}\\.xlsx)$",
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(xls_files) == 0) {
    return(tibble(yearmon = character(), cbsa = character(), total = numeric()))
  }

  ym <- str_match(basename(xls_files), "(\\d{6})")[, 2]
  keep <- !is.na(ym) & ym >= start_ym & ym <= end_ym
  xls_files <- xls_files[keep]

  if (length(xls_files) == 0) {
    return(tibble(yearmon = character(), cbsa = character(), total = numeric()))
  }

  purrr::map(xls_files, parse_bps_excel_one) %>% bind_rows()
}

# ----------------------------
# Main
# ----------------------------
# Target full panel window for Chapter 2
panel_start <- "201801"
panel_end   <- "202412"

# Period split based on your previous workflow:
# txt: 2018-01 to 2019-10
# excel: 2019-11 onward
txt_start <- "201801"
txt_end   <- "201910"
xls_start <- "201911"
xls_end   <- panel_end

message("Reading BPS TXT files: ", txt_start, " to ", txt_end)
bps_txt <- read_bps_txt_panel(txt_start, txt_end)

message("Reading BPS Excel files: ", xls_start, " to ", xls_end)
bps_xls <- read_bps_excel_panel(xls_start, xls_end)

bps_all <- bind_rows(bps_txt, bps_xls) %>%
  mutate(
    cbsa  = str_extract(as.character(cbsa), "\\d{5}"),
    total = as.numeric(total)
  ) %>%
  filter(!is.na(cbsa), cbsa != "", !is.na(total)) %>%
  group_by(yearmon, cbsa) %>%
  summarise(total = sum(total, na.rm = TRUE), .groups = "drop") %>%
  arrange(yearmon, cbsa) %>%
  filter(
    str_replace_all(yearmon, "-", "") >= panel_start,
    str_replace_all(yearmon, "-", "") <= panel_end
  )

# QA: uniqueness
dup <- bps_all %>% count(yearmon, cbsa) %>% filter(n > 1)
if (nrow(dup) > 0) {
  warning("Duplicates found after aggregation. Showing first 10:")
  print(head(dup, 10))
}

write_csv(bps_all, out_file)
