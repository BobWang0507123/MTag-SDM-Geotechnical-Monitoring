%% MTag-SDM | Public calibration and detection analysis
% Reproducible numerical analysis for Table 3, static positioning,
% Table 4, background-field variability, and Fig. 4.
%
% MATLAB R2020b or later recommended. Statistics Toolbox not required.
% The four input files are NOT distributed with this script.
% Prepare approved research data in the tabular layouts below before use.
% No imputation, smoothing, outlier removal, or editing is performed.
%
% INPUT FILES (place beside this script; filenames may be customized below):
% 1. displacement_3mm.xlsx: sheets Air, QuartzSand, SingleRebar;
%    range A3:N22 (20 trials), three 5-column blocks containing
%    [trialID, X, Y, Z, unused]. Main-axis measured displacements (mm).
% 2. static_coordinates.xlsx: same three sheets; range A3:D402,
%    [trialID, X, Y, Z] with 400 independent coordinates per sheet (mm).
% 3. detection_trials.xlsx: same three sheets; direction blocks start at
%    rows 3, 207 and 411; 200 data rows per block, 2 intervening header
%    rows per 204-row block. 29 columns: trialID then 7 blocks of
%    [prescribed amplitude, measured X, measured Y, measured Z] (mm).
%    Amplitudes: 0, 0.1, ..., 0.6 mm. Each direction has 200 trials.
% 4. background_field.csv: numeric samples x 75, triplets Bx/By/Bz
%    for 25 sensors, in microtesla. No header row; any sample count >=2.
%
% IMPORTANT: Do not mix these 400-sample static calibration data with
% the ~1200 frame continuous stability data analyzed for Section 3.5.
% This script retains the original statistical definitions and decision
% rules. Change workbook sheet names/configuration only to match approved
% datasets; do not modify historical numeric results without verification.

clear; clc;
rootDir = fileparts(mfilename('fullpath'));
if isempty(rootDir), rootDir = pwd; end
outDir = fullfile(rootDir, 'outputs');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Neutral filenames deliberately replace project-specific file paths.
f3 = fullfile(rootDir, 'displacement_3mm.xlsx');
fs = fullfile(rootDir, 'static_coordinates.xlsx');
fd = fullfile(rootDir, 'detection_trials.xlsx');
fb = fullfile(rootDir, 'background_field.csv');
inputFiles = {f3, fs, fd, fb};
assert(all(cellfun(@(f) exist(f, 'file') == 2, inputFiles)), ...
    'Missing input file(s): provide the four approved workbooks/CSV.');

% Sheet labels in the public interface; edit to match approved files.
sheets = {'Air', 'QuartzSand', 'SingleRebar'};
conditions = {'Air', 'Unreinforced medium', 'Single rebar'};
axesXYZ = {'X', 'Y', 'Z'};
refXYZ = [0, 0, 90];  % reference coordinates (mm), as used in supplied script
Nrep = 20; Nstat = 400; windowN = 20;
Nzero = 200; Ndetect = 200;
amp = (0:6)' / 10;

%% Table 3 | prescribed +3 mm main-axis displacement
T3 = table();
for c = 1:3
    A = readmatrix(f3, 'Sheet', sheets{c}, 'Range', 'A3:N22');
    assert(isequal(size(A), [Nrep, 14]), 'Invalid 3-mm data: %s', sheets{c});
    for a = 1:3
        base = 1 + (a-1)*5;
        assert(isequal(A(:, base), (1:Nrep)'), ...
            'Invalid trial IDs: %s / %s', sheets{c}, axesXYZ{a});
        xyz = A(:, base+(1:3));
        assert(all(isfinite(xyz(:))), 'Missing 3-mm data');
        err = xyz(:, a) - 3;   % signed main-axis error (mm)
        m = mean(err); s = std(err, 0);
        rmse = sqrt(mean(err.^2)); maxae = max(abs(err));
        tcrit = studentT975_public(Nrep-1);
        lo = m - tcrit*s/sqrt(Nrep);
        hi = m + tcrit*s/sqrt(Nrep);
        row = table(string(conditions{c}), string(axesXYZ{a}), Nrep, ...
            m, s, rmse, maxae, lo, hi, 'VariableNames', ...
            {'Condition','Axis','N','Mean_error_mm','SD_mm','RMSE_mm', ...
             'MaxAE_mm','CI95_low_mm','CI95_high_mm'});
        T3 = [T3; row]; %#ok<AGROW>
    end
end
writetable(T3, fullfile(outDir, 'Table3_full_precision.csv'));

%% Static calibration | 400 coordinates -> 20 consecutive windows of 20
TS = table();
for c = 1:3
    A = readmatrix(fs, 'Sheet', sheets{c}, 'Range', 'A3:D402');
    assert(isequal(size(A), [Nstat, 4]), ...
        'Static sheet must contain exactly 400 valid rows: %s', sheets{c});
    assert(isequal(A(:, 1), (1:Nstat)'), 'Invalid static trial IDs: %s', sheets{c});
    xyz = A(:, 2:4);
    assert(all(isfinite(xyz(:))), ...
        'Missing static coordinates: %s. Do not fabricate missing rows.', sheets{c});
    assert(mod(Nstat, windowN) == 0);
    winMean = squeeze(mean(reshape(xyz, windowN, Nstat/windowN, 3), 1));
    avg = mean(xyz, 1);
    staticBias = avg - refXYZ;
    windowSD = std(winMean, 0, 1);
    for a = 1:3
        row = table(string(conditions{c}), string(axesXYZ{a}), Nstat, ...
            Nstat/windowN, windowN, avg(a), staticBias(a), windowSD(a), ...
            std(xyz(:, a), 0), 'VariableNames', ...
            {'Condition','Axis','N_coordinates','N_windows', ...
             'Samples_per_window','Mean_coordinate_mm','Static_bias_mm', ...
             'Window_SD_mm','Samplewise_SD_mm'});
        TS = [TS; row]; %#ok<AGROW>
    end
    W = table((1:size(winMean,1))',winMean(:,1),winMean(:,2),winMean(:,3), ...
        'VariableNames', {'Window','X_mm','Y_mm','Z_mm'});
    writetable(W, fullfile(outDir, sprintf('Static_windows_condition_%d.csv', c)));
end
writetable(TS, fullfile(outDir, 'Static_stability_full_precision.csv'));

%% Detection trials | 200 per amplitude including zero
TD = table();
for c = 1:3
    for a = 1:3
        firstRow = 3+(a-1)*204;
        excelRange = sprintf('A%d:AC%d', firstRow, firstRow+Nzero-1);
        M = readmatrix(fd, 'Sheet', sheets{c}, 'Range', excelRange);
        assert(isequal(size(M), [Nzero, 29]), ...
            'Invalid detection sheet: %s/%s', sheets{c}, axesXYZ{a});
        assert(isequal(M(:,1), (1:Nzero)'), 'Invalid detection trial IDs');
        assert(all(isfinite(M(:))), 'Missing detection data');
        for k = 1:7
            assert(all(abs(M(:,2+4*(k-1))-amp(k)) < 1e-10), ...
                'Prescribed amplitude mismatch');
        end
        zero = M(:, 3+(a-1));  % measured main-axis values at 0 mm
        rawQ95 = type7Quantile_public(zero, 0.95);
        threshold = roundHalfUp3_public(rawQ95);
        for k = 1:7
            measured = M(:, 3+4*(k-1)+(a-1));
            hits = sum(measured > threshold); % strictly greater, not >=
            rate = 100*hits/Ndetect;
            [low, high] = clopperPearson_public(hits, Ndetect, 0.05);
            row = table(string(conditions{c}), string(axesXYZ{a}), ...
                amp(k), Ndetect, rawQ95, threshold, hits, rate, ...
                100*low, 100*high, 'VariableNames', ...
                {'Condition','Axis','Amplitude_mm','N_trials','Raw_q95_mm', ...
                 'Threshold_mm','N_detected','Detection_rate_pct', ...
                 'CI95_low_pct','CI95_high_pct'});
            TD = [TD; row]; %#ok<AGROW>
        end
    end
end
writetable(TD, fullfile(outDir, 'Fig4_all_points_with_exact_CI.csv'));

%% Table 4 | first positive tested amplitude with >=95% detection
T4 = table();
for i = 1:height(TS)
    same = TD.Condition == TS.Condition(i) & TD.Axis == TS.Axis(i);
    sub = TD(same, :);
    j = find(sub.Amplitude_mm > 0 & sub.Detection_rate_pct >= 95, 1, 'first');
    assert(~isempty(j), 'No tested positive amplitude met 95%% criterion');
    row = table(TS.Condition(i), TS.Axis(i), TS.Static_bias_mm(i), ...
        TS.Window_SD_mm(i), sub.Threshold_mm(j), sub.Amplitude_mm(j), ...
        sub.Detection_rate_pct(j), sub.N_detected(j), ...
        sub.CI95_low_pct(j), sub.CI95_high_pct(j), 'VariableNames', ...
        {'Condition','Axis','Static_bias_mm','Static_SD_mm', ...
         'Decision_threshold_mm','Detection_displacement_mm', ...
         'Detection_rate_pct','N_detected', ...
         'Detection_CI95_low_pct','Detection_CI95_high_pct'});
    T4 = [T4; row]; %#ok<AGROW>
end
writetable(T4, fullfile(outDir, 'Table4_full_precision.csv'));

%% Background field | temporal SD by component and sensor
B = readmatrix(fb);
assert(size(B,2) == 75 && size(B,1) >= 2 && all(isfinite(B(:))), ...
    'Expected >=2 numeric background rows with 75 columns');
nt = size(B,1);
B3 = reshape(B, nt, 3, 25); % time x component x sensor
sensorSD = squeeze(std(B3, 0, 1));
magRMS = sqrt(mean(sensorSD.^2, 2));
TB = table(string({'Bx';'By';'Bz'}), magRMS, ...
    'VariableNames', {'Field_component','RMS_of_25_sensor_temporal_SDs_uT'});
writetable(TB, fullfile(outDir, 'Background_field_RMS_SD.csv'));
TM = table((1:25)', sensorSD(1,:)', sensorSD(2,:)', sensorSD(3,:)', ...
    'VariableNames', {'Sensor','Bx_temporal_SD_uT', ...
                       'By_temporal_SD_uT','Bz_temporal_SD_uT'});
writetable(TM, fullfile(outDir, 'Background_field_per_sensor_SD.csv'));

%% Fig. 4 | data and visualization
FW = table(amp, 'VariableNames', {'Amplitude_mm'});
for c = 1:3
    for a = 1:3
        sel = TD.Condition == string(conditions{c}) & TD.Axis == string(axesXYZ{a});
        v = TD.Detection_rate_pct(sel);
        assert(numel(v) == 7 && all(abs(TD.Amplitude_mm(sel)-amp)<1e-10));
        FW.(sprintf('C%d_%s_pct', c, axesXYZ{a})) = v;
    end
end
writetable(FW, fullfile(outDir, 'Fig4_plot_wide_percent.csv'));

f = figure('Color','w','Position',[100,100,1300,390]);
styles = {'-o','-s','-^'};
for a = 1:3
    subplot(1,3,a); hold on;
    for c = 1:3
        sel = TD.Condition == string(conditions{c}) & ...
              TD.Axis == string(axesXYZ{a}) & TD.Amplitude_mm > 0;
        v = TD(sel, :);
        errorbar(v.Amplitude_mm, v.Detection_rate_pct, ...
            v.Detection_rate_pct-v.CI95_low_pct, ...
            v.CI95_high_pct-v.Detection_rate_pct, ...
            styles{c}, 'LineWidth',1.1,'MarkerSize',5,'CapSize',3);
    end
    yline(95,'k--','95% criterion','LabelVerticalAlignment','bottom');
    xlabel('Prescribed displacement (mm)');
    ylabel('Detection probability (%)');
    title(sprintf('(%s) %s direction', char('a'+a-1), axesXYZ{a}));
    xlim([0.05, 0.65]); ylim([0, 105]); xticks(0.1:0.1:0.6);
    grid on; box on;
    if a == 1, legend(conditions, 'Location','southeast'); end
end
exportgraphics(f, fullfile(outDir, 'Fig4_recalculated.png'), 'Resolution',300);
try
    exportgraphics(f, fullfile(outDir, 'Fig4_recalculated.pdf'), ...
        'ContentType', 'vector');
catch
    warning('Could not export Fig. 4 as PDF; PNG was saved.');
end

fprintf('\n=== TABLE 3 ===\n'); disp(T3);
fprintf('\n=== TABLE 4 ===\n'); disp(T4);
fprintf('\n=== BACKGROUND FIELD ===\n'); disp(TB);
fprintf('\n=== FIG. 4 WIDE DATA ===\n'); disp(FW);
fprintf('\nOutputs saved to: %s\n', outDir);

%% Mathematical utility functions (no Statistics Toolbox required)
function q = type7Quantile_public(x, p)
    x = sort(x(:)); n = numel(x);
    assert(n > 1 && p >= 0 && p <= 1);
    h = 1+(n-1)*p; i = floor(h); j = min(i+1,n);
    q = x(i)+(h-i)*(x(j)-x(i));
end
function x = roundHalfUp3_public(y)
    % Preserve supplied three-decimal half-up rule for nonnegative q95.
    assert(y >= 0, 'Expected nonnegative 95th-percentile threshold');
    x = floor(1000*y+0.5+1e-10)/1000;
end
function t = studentT975_public(df)
    % Student-t 0.975 quantile, using inverse regularized beta.
    b = betaincinv(0.05, df/2, 0.5);
    t = sqrt(df*(1/b-1));
end
function [lo, hi] = clopperPearson_public(k, n, alpha)
    % Two-sided exact binomial confidence interval (proportions).
    if k == 0, lo = 0; else, lo = betaincinv(alpha/2, k, n-k+1); end
    if k == n, hi = 1; else, hi = betaincinv(1-alpha/2, k+1, n-k); end
end
