# Algorithm description and traceability

## Parameterization

For each target k, let `theta_k = [m_x, m_y, m_z, p_x, p_y, p_z]` with position in metres and magnetic-moment-like parameters in units consistent with the chosen coefficient. Stacking these rows gives the 6K-vector accepted by MATLAB.

## Dipole field

At sensor `s_i`, define `r_ik = s_i - p_k`, `rho_ik = ||r_ik||`. The model implemented in the original source and public core is

`B_i(theta) = C sum_k [3 (m_k dot r_ik) r_ik / rho_ik^5 - m_k / rho_ik^3]`.

`C` is a model-dependent scale factor, not automatically `mu0/(4*pi)`. The original Live Script used a project-specific coefficient and did not establish its SI provenance. Do not substitute the synthetic demonstration coefficient for experimental calibration. A sensor coinciding with an estimated dipole causes a singular field and is rejected by the public forward routine.

## Residual and inverse problem

For `N x 3` compensated observations `B_obs`, the residual is

`f(theta) = reshape(M .* (B_pred(theta) - B_obs), [], 1)`.

Here `M` is a component-validity mask of zeros or ones, and `reshape` uses MATLAB's column-major ordering. `lsqnonlin` minimizes `sum(f(theta).^2)` within per-component lower and upper parameter bounds. This matches the original source's residual-vector convention.

**Legacy caveat:** Original `target_function1` used `M = double(B_obs ~= 0)`, so exact zero readings were dropped even if physically valid. This public implementation defaults to explicit validity (`true` everywhere), and preserves the original convention on request using `legacy_zero_mask` in `run_sequence_inversion` or by passing `B_obs~=0` as `valid_mask` to the single-frame solver. This choice must be matched before claiming numerical equivalence.

## Sequential operation

Process each compensated frame independently while taking the previous *successful, non-skipped* frame's optimum as the next initial guess. Skipped frames return NaN rows. The original script skipped when all sensor vector norms were at most a hard-coded threshold; the public implementation exposes the rule as an **optional** externally supplied parameter, without distributing the experimental threshold value. Input frames are presumed to have been aligned and background-corrected upstream.

## Differences from the laboratory script

- No acquisition stream / interleaved channel parser is included.
- No empirical deployment geometry generator or original numeric array is included.
- No background correction, experiment files, graphical controls or spreadsheet export.
- No implicit laboratory model coefficient, thresholds or solver initial guesses.
- The publicly documented mask default is scientifically clearer, but not identical to the historical zero-is-missing rule.
- The script supported one target in its recorded configuration; the general core supports K targets, but multipole uniqueness and robustness are not proven by the synthetic test.
- The historical program's `threshold` variable was unused; the implemented skip rule was based on sensor vector norms, not that variable.

## Scientific limitations

The ideal dipole model does not automatically capture ferromagnetic interference, spatially varying background fields, sensor misalignment, saturation or calibration bias. Optimizer convergence is initialization-dependent and does not guarantee global uniqueness. This demonstration is not a validation of the experimental system or reported accuracies.
