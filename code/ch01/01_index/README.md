# Chapter 1 — Attention Index Construction and Transformation

This directory contains all scripts used to construct and transform
category-level consumer attention indices for Chapter 1.

Together, the scripts in this directory form a self-contained pipeline
that maps raw Google Trends data to analysis-ready attention series.

---

## Overview of Scripts

The scripts in this directory should be run in the following order:

1. **01_build_attention_index.R**

   Constructs category-level attention indices from raw Google Trends data.
   Multiple Google Trends sub-categories are aggregated into a single
   product-level attention index using fixed expenditure-based weights.

2. **02_plot_attention_index.R**

   Produces diagnostic and exploratory plots of the constructed attention
   indices. These plots are used for sanity checks and visualization only
   and do not generate data used directly in regression analysis.

3. **03_detrend_and_difference.R**

   Removes smooth time trends and seasonal components from each
   category-level attention index using a quadratic time trend and
   month fixed effects. First differences of the resulting residual
   series are then constructed to produce analysis-ready attention data.

---

## Construction of Category Weights

To aggregate Google Trends attention series from multiple sub-categories
into a single category-level attention index, sub-category-specific weights
are used.

The weights are constructed using annual consumption expenditure data from
the Consumer Expenditure Survey (CES). For each product category,
Google Trends sub-categories are matched to CES consumption items, and
weights are defined as the share of total category-level consumption
accounted for by each sub-category.

Because CES item definitions and coverage vary over time, weights are
computed using only years in which all relevant sub-categories are jointly
observed. The resulting weights are fixed over time and reflect average
expenditure shares rather than contemporaneous consumption fluctuations.

This weighting strategy ensures that the aggregation weights are:
- grounded in observed household expenditure patterns,
- external to the Google Trends attention data,
- invariant over time, and
- not mechanically correlated with short-run attention dynamics.

The mapping between Google Trends sub-categories and consumption categories
is documented in `data/raw/ch01/gt/`.

## Data Flow

The scripts implement the following transformation pipeline:

raw Google Trends -> combined category-level attention index -> detrended attention residual -> first-differenced residual

