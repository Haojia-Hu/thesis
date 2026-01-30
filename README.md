# Thesis Repository

This repository contains code and writing for my PhD dissertation.

The goal of this repository is to ensure transparency and reproducibility.
Only plain-text source files are tracked.
Generated files and datasets are excluded from version control.

## Structure

- `code/`  
  Source code for each dissertation chapter, organized by chapter.

- `data/raw/`  
  Original raw datasets.  
  These files are stored locally, never modified, and not tracked.

- `data/transformed/`  
  Intermediate datasets generated from raw data.  
  Not tracked.

- `data/output/`  
  Final output files (tables, figures, estimates).  
  Not tracked.

- `writing/`  
  LaTeX source files for dissertation chapters and references.

## Notes

All empirical results can be reproduced by running the code in `code/`
using the original raw data stored locally.
