% Recompute the released S1 FEM–experiment comparison from state exports.
% Inputs are relative to this script; no COMSOL API or project files required.
% Experimental state exports are in microtesla. FEM state exports are in T.
% Delta convention: state A minus state B. COMSOL coordinates/components are
% retained in the input files; comparison mapping is x_exp=x_COMSOL,
% y_exp=z_COMSOL, and [Bx, By, Bz]_exp = [Bx, Bz, -By]_COMSOL.

scriptDir = fileparts(mfilename('fullpath'));
dataDir = fullfile(scriptDir, '..', '..', 'data', 'fem_experiment_comparison');

expA = readtable(fullfile(dataDir, 'EXP_A_FINAL.csv'));
expB = readtable(fullfile(dataDir, 'EXP_B_FINAL.csv'));
femA = readtable(fullfile(dataDir, 'S1FR_FEM_A_COMSOL_T.csv'));
femB = readtable(fullfile(dataDir, 'S1FR_FEM_B_COMSOL_T.csv'));
reported = readtable(fullfile(dataDir, 'S1_validation_metrics.csv'));

assert(isequal(expA.sensor_id, expB.sensor_id), 'Experimental sensor IDs/order differ.');
assert(isequal(femA.sensor_id, femB.sensor_id), 'FEM sensor IDs/order differ.');
assert(isequal(expA.sensor_id, femA.sensor_id), 'Experimental/FEM sensor IDs/order differ.');

expDelta = [expA.Bx_exp_uT-expB.Bx_exp_uT, ...
            expA.By_exp_uT-expB.By_exp_uT, ...
            expA.Bz_exp_uT-expB.Bz_exp_uT];
femDeltaCOMSOL_uT = 1e6 .* [femA.Bx_T-femB.Bx_T, ...
                            femA.By_T-femB.By_T, ...
                            femA.Bz_T-femB.Bz_T];
femDelta = [femDeltaCOMSOL_uT(:,1), femDeltaCOMSOL_uT(:,3), ...
            -femDeltaCOMSOL_uT(:,2)];

componentNames = {'Bx','By','Bz'};
result = table('Size',[4 7], ...
    'VariableTypes', [repmat("double",1,6), "string"], ...
    'VariableNames', {'MAE_uT','RMSE_uT','MaxE_uT','MBE_uT','relative_L2','Pearson_r','component'});
for k = 1:3
    result{k,1:6} = metricRow(expDelta(:,k), femDelta(:,k));
    result.component(k) = string(componentNames{k});
end
result{4,1:6} = metricRow(expDelta(:), femDelta(:));
result.component(4) = "Overall75";

disp('Recomputed S1 metrics (comparison component order: Bx, By, Bz):');
disp(result);

% Verify every reported summary value to the precision stored in its CSV.
metricNames = {'MAE_uT','RMSE_uT','MaxE_uT','MBE_uT','relative_L2','Pearson_r'};
for r = 1:height(result)
    row = find(strcmp(string(reported.component), result.component(r)), 1);
    assert(~isempty(row), 'Missing reported metric row: %s', char(result.component(r)));
    for c = 1:numel(metricNames)
        field = metricNames{c};
        actual = result.(field)(r);
        expected = reported.(field)(row);
        assert(abs(actual-expected) <= 1e-10*max(1,abs(expected)), ...
            'Mismatch for %s / %s: computed %.16g, stored %.16g', ...
            char(result.component(r)), field, actual, expected);
    end
end
fprintf('All recomputed values match S1_validation_metrics.csv within numerical tolerance.\n');

function values = metricRow(experimental, fem)
    errorValue = fem - experimental;
    centeredExperimental = experimental(:) - mean(experimental(:));
    centeredFem = fem(:) - mean(fem(:));
    pearson = sum(centeredExperimental .* centeredFem) / ...
        sqrt(sum(centeredExperimental.^2) * sum(centeredFem.^2));
    values = [mean(abs(errorValue)), sqrt(mean(errorValue.^2)), ...
        max(abs(errorValue)), mean(errorValue), ...
        norm(errorValue)/norm(experimental), pearson];
end
