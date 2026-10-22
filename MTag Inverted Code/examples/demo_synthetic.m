%DEMO_SYNTHETIC Standalone public test with completely synthetic inputs.
% Run this script from anywhere in MATLAB with Optimization Toolbox.
this_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(this_dir,'..','core'));
sensor_pos = readmatrix(fullfile(this_dir,'synthetic_geometry.csv'));
B_measured = readmatrix(fullfile(this_dir,'synthetic_field.csv'));
opts.model_scale = 1e-4; % Illustrative coefficient; NOT experimental calibration.
opts.theta0 = [0.02 -0.01 0.06 0 0 0.08];
opts.lb = [-0.2 -0.2 -0.2 -0.08 -0.08 0.025];
opts.ub = [0.2 0.2 0.2 0.08 0.08 0.20];
opts.valid_mask = true(size(B_measured));
opts.optim_options = optimoptions('lsqnonlin','Display','off', ...
    'MaxIterations',1000,'FunctionTolerance',1e-12,'StepTolerance',1e-12);
sol = solve_magnetic_localization(sensor_pos,B_measured,opts);
truth = [0.025 -0.018 0.07 0.018 -0.012 0.095];
fprintf('Synthetic reference position [m]: %.6f %.6f %.6f\n',truth(4:6));
fprintf('Estimated position [m]:           %.6f %.6f %.6f\n',sol.positions(1,:));
fprintf('Residual sum of squares: %.6g\n',sol.loss);
assert(norm(sol.positions(1,:)-truth(4:6))<1e-3, ...
    'Synthetic position regression test failed.');
% Exercise the sequence interface using repeated synthetic observations.
seq = run_sequence_inversion(sensor_pos,cat(3,B_measured,B_measured),opts);
assert(all(isfinite(seq.loss)), 'Sequence inversion failed.');
disp('Synthetic demonstration completed.');
