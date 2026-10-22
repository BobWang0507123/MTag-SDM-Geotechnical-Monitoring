function residual = magnetic_dipole_residual(theta, sensor_pos, B_measured, model_scale, valid_mask)
%MAGNETIC_DIPOLE_RESIDUAL Column-major vector of masked field differences.
% valid_mask is logical N-by-3. A zero field value is valid unless masked.
if nargin < 5 || isempty(valid_mask)
    valid_mask = true(size(B_measured));
end
assert(isequal(size(B_measured),size(sensor_pos)), ...
    'B_measured and sensor_pos must both be N-by-3.');
assert(isequal(size(valid_mask),size(B_measured)), ...
    'valid_mask must be N-by-3.');
validateattributes(B_measured, {'numeric'}, {'real','finite'});
valid_mask = logical(valid_mask);
assert(any(valid_mask(:)), 'At least one observed component must be valid.');
B_pred = magnetic_dipole_forward(theta, sensor_pos, model_scale);
delta = B_pred - B_measured;
% Preserve original column-major reshape and elementwise masking convention.
residual = reshape(double(valid_mask) .* delta, [], 1);
end
