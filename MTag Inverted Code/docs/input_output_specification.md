# Input and output specification

## Coordinates and conventions

- `sensor_pos`: real finite `N x 3`, `[x y z]` in metres, arbitrary sensor order but **the same order as magnetic observations**.
- `B_measured`: real finite `N x 3`, `[Bx By Bz]` in model-consistent field units and already background-corrected by the data provider.
- `theta`: `6K` numbers `[mx my mz px py pz]` for each target, concatenated in target order.
- `model_scale`: finite scalar `C` matching the chosen units, not a default SI calibration.
- `valid_mask`: logical `N x 3`; false excludes that component; true includes actual zero readings. The single-frame solver accepts the same mask as `opts.valid_mask`.
- `B_series`: real finite `N x 3 x T`, time in the third dimension. A single frame may be passed as `N x 3` because MATLAB elides trailing singleton dimensions; the single-frame solver is also supported.

## `solve_magnetic_localization(sensor_pos,B_measured,opts)`

Required `opts.model_scale`, `opts.theta0`, `opts.lb`, `opts.ub`; all parameter vectors have `6K` entries. Optional `opts.valid_mask`, `opts.optim_options` (MATLAB `optimoptions('lsqnonlin',...)`). Uses Optimization Toolbox.

Returns a struct with `theta` (1 x 6K), `positions` (K x 3), `moment_parameters` (K x 3), `loss` (sum of squared weighted residuals), `resnorm`, `residual`, `exitflag`, `output`, `target_count`, `first_target_scaled_moment_norm` (first target only).

## `run_sequence_inversion(sensor_pos,B_series,opts)`

Inherits all solver options, with optional `opts.frame_mask` (`N x 3 x T`), `opts.legacy_zero_mask` (default false), and `opts.skip_all_sensor_norm_below` (default disabled). Per-frame masks and legacy rule are AND-combined. Returns `theta` (`T x 6K`), `loss`, `exitflag`, `skipped`, `first_target_scaled_moment_norm`. Skipped rows are NaN, `skipped(t)` is true. A failed optimizer exit flag does not automatically trigger an alternate initial guess.

## Synthetic CSVs

Files have **no headers**. `synthetic_geometry.csv` is `24 x 3` and `synthetic_field.csv` is `24 x 3`, with sensor row order matched exactly. Example-only truth is `[0.025,-0.018,0.07,0.018,-0.012,0.095]` and example coefficient `1e-4`; neither belongs to the original experiment.
