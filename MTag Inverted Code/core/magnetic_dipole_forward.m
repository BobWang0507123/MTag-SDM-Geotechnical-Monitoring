function B = magnetic_dipole_forward(theta, sensor_pos, model_scale)
%MAGNETIC_DIPOLE_FORWARD Multi-target dipole field, in model-consistent units.
% theta: [mx my mz x y z] repeated for each target (1-by-6K or 6K-by-1).
% sensor_pos: N-by-3 sensor coordinates, in metres.
% model_scale: scalar proportionality coefficient consistent with theta and B.
% B: N-by-3 predicted magnetic field, same units as the measurements.
% The coefficient is not assumed to equal a SI dipole constant; see docs.
validateattributes(sensor_pos, {'numeric'}, {'real','finite','2d','ncols',3});
validateattributes(theta, {'numeric'}, {'real','finite','vector','nonempty'});
validateattributes(model_scale, {'numeric'}, {'real','finite','scalar'});
assert(mod(numel(theta),6)==0, 'theta must contain six entries per target.');
P = reshape(theta, 6, []).';
B = zeros(size(sensor_pos));
for k = 1:size(P,1)
    m = P(k,1:3);
    r = sensor_pos - P(k,4:6);
    dist = sqrt(sum(r.^2,2));
    if any(dist <= 1e-12)
        error('Dipole location coincides with a sensor; forward field is singular.');
    end
    proj = sum(r .* m,2);
    B = B + model_scale * (3 .* (proj ./ dist.^5) .* r - m ./ dist.^3);
end
end
