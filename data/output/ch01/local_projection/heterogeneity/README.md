## Local Projection heterogeneity by rolling FFT clusters

This folder stores heterogeneity results where categories are split into groups
using rolling FFT clustering.

### Inputs
- `data/transformed/ch01/panel/panel_data.csv`
- `data/transformed/ch01/attention_cycle/rolling_fft_cluster_results.csv`

### Code
- `code/ch01/03_expectation_formation/08_lp_hetero_by_fft_cluster.R`

### Outputs
- `cluster_map_used.csv`  
  Category-to-cluster mapping used in the estimation.

- `irf_group_pc.csv`  
  IRFs of the interaction term `Attention × Price Change` by cluster.

- `irf_group_vol.csv`  
  IRFs of the interaction term `Attention × Price Volatility` by cluster.

- `fig_irf_group_pc.png`  
  Plot of `Attention × Price Change` IRFs by cluster.

- `fig_irf_group_vol.png`  
  Plot of `Attention × Price Volatility` IRFs by cluster.
