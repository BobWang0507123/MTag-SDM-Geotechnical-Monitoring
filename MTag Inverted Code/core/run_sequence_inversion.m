function sequence = run_sequence_inversion(sensor_pos, B_series, opts)
%RUN_SEQUENCE_INVERSION Process N-by-3-by-T compensated observation frames.
% B_series must already be corrected/aligned in the public interface.
% Skip rule is optional; no laboratory-specific threshold is embedded.
% opts.frame_mask: logical N-by-3-by-T (default all true).
% opts.legacy_zero_mask: true reproduces original (B ~= 0) weighting.
% opts.skip_all_sensor_norm_below: optional nonnegative threshold; if all
%   sensor vector norms are <= threshold, frame is skipped.
% A single frame can be N-by-3 because MATLAB drops trailing singleton dims.
assert(ndims(B_series)<=3, 'B_series must be N-by-3-by-T.');
assert(size(B_series,1)==size(sensor_pos,1) && size(B_series,2)==3, ...
    'B_series must have dimensions N-by-3-by-T.');
validateattributes(B_series, {'numeric'}, {'real','finite'});
T = size(B_series,3);
K = numel(opts.theta0)/6;
assert(mod(K,1)==0 && K>=1,'theta0 must contain 6K parameters.');
sequence.theta = nan(T,6*K);
sequence.loss = nan(T,1);
sequence.exitflag = nan(T,1);
sequence.skipped = false(T,1);
sequence.first_target_scaled_moment_norm = nan(T,1);
working = opts;
for t = 1:T
    frame = B_series(:,:,t);
    if isfield(opts,'skip_all_sensor_norm_below') && ...
            all(sqrt(sum(frame.^2,2)) <= opts.skip_all_sensor_norm_below)
        sequence.skipped(t) = true;
        continue;
    end
    if isfield(opts,'frame_mask')
        mask = opts.frame_mask(:,:,t);
    else
        mask = true(size(frame));
    end
    if isfield(opts,'legacy_zero_mask') && opts.legacy_zero_mask
        mask = logical(mask) & (frame ~= 0);
    end
    working.valid_mask = mask;
    solved = solve_magnetic_localization(sensor_pos,frame,working);
    sequence.theta(t,:) = solved.theta;
    sequence.loss(t) = solved.loss;
    sequence.exitflag(t) = solved.exitflag;
    sequence.first_target_scaled_moment_norm(t) = solved.first_target_scaled_moment_norm;
    working.theta0 = solved.theta; % Previous successful estimate warm-start.
end
end
