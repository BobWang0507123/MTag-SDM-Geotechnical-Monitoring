function result = solve_magnetic_localization(sensor_pos, B_measured, opts)
%SOLVE_MAGNETIC_LOCALIZATION Bounded least squares for K magnetic dipoles.
% Required opts: model_scale, theta0, lb, ub. Optional: valid_mask,
% optim_options. Requires MATLAB Optimization Toolbox (lsqnonlin).
assert(isstruct(opts), 'opts must be a structure.');
required = {'model_scale','theta0','lb','ub'};
for i = 1:numel(required)
    assert(isfield(opts, required{i}), ['Missing option: ' required{i}]);
end
x0 = opts.theta0(:).'; lb = opts.lb(:).'; ub = opts.ub(:).';
assert(numel(x0)==numel(lb) && numel(x0)==numel(ub) && ...
       mod(numel(x0),6)==0, 'Bounds and initial guess must be 6K vectors.');
assert(all(lb <= x0 & x0 <= ub), 'Initial guess must lie inside bounds.');
if isfield(opts,'valid_mask')
    mask = opts.valid_mask;
else
    mask = true(size(B_measured));
end
if isfield(opts,'optim_options')
    optim_opts = opts.optim_options;
else
    optim_opts = optimoptions('lsqnonlin','Display','off');
end
fun = @(theta) magnetic_dipole_residual(theta,sensor_pos,B_measured,opts.model_scale,mask);
[theta, resnorm, residual, exitflag, output] = lsqnonlin(fun,x0,lb,ub,optim_opts);
result.theta = theta(:).';
result.loss = sum(residual.^2); % Same norm(F)^2 definition as original script.
result.resnorm = resnorm;
result.residual = residual;
result.exitflag = exitflag;
result.output = output;
result.target_count = numel(theta)/6;
result.positions = reshape(theta,6,[]).';
result.positions = result.positions(:,4:6);
result.moment_parameters = reshape(theta,6,[]).';
result.moment_parameters = result.moment_parameters(:,1:3);
% Original script calculated this quantity only for the first target.
result.first_target_scaled_moment_norm = opts.model_scale * norm(theta(1:3));
end
