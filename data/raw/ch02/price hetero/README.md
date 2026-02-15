# Chapter 2 Raw Data: Saiz (2010) Housing Supply Elasticity

This folder contains raw source files used to build a CBSA-level measure of housing supply elasticity from Saiz (2010). The Saiz elasticity is originally reported at a legacy MSA (msanecma) level, so we require a Census crosswalk to map those MSAs into modern 5-digit CBSA codes.

## Contents

1) saiz2010.csv  
- Source: MIT Urban Economics (Saiz 2010 data)  
  https://urbaneconomics.mit.edu/research/data  
- Key fields used:
  - msanecma: legacy MSA code (4-digit, often called NECMA/MSA code)
  - elasticity: Saiz housing supply elasticity

2) cbsa03_msa99.xls  
- Source: U.S. Census crosswalk file (1999 MSA -> 2003 CBSA)  
  https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2003/99-msa-to-03-cbsa/cbsa03_msa99.xls  
- Purpose:
  - Provides a mapping from legacy MSA codes (1999 definitions) to CBSA codes (2003 definitions).
  - The file is county-based, so one MSA may map into multiple CBSAs.

## How these raw files are used

These inputs are transformed by:
- code/ch02/07_housing_price/00_build_saiz2010_cbsa.R

The script produces:
- data/transformed/ch02/housing_price/saiz2010_cbsa.csv

## Notes

- If a legacy MSA maps to multiple CBSAs, we assign a “primary CBSA” defined as the CBSA containing the largest number of counties in that MSA (ties broken by CBSA code).
- The CBSA-level elasticity file is used for heterogeneity analysis in the house price Local Projection section (grouping by supply elasticity).

  ---

  
