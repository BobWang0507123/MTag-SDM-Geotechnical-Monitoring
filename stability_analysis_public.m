function stats = stability_analysis_public(coordinates, conditionNames, makeFigure)
%STABILITY_ANALYSIS_PUBLIC Coordinate stability analysis for MTag-SDM.
%
%   stats = stability_analysis_public(coordinates)
%   stats = stability_analysis_public(coordinates, conditionNames, makeFigure)
%
% PURPOSE
%   Reproduce the analysis definitions used in Section 3.5 (Fig. 10):
%   frame-to-frame coordinate fluctuations during stationary intervals,
%   expressed as the per-axis peak-to-peak range and standard deviation.
%
% INPUT
%   coordinates    N-by-3 numeric array [X Y Z], OR a cell array of such
%                  arrays, one per monitoring condition. Coordinates must
%                  ALREADY be extracted from stationary intervals and
%                  converted to millimeters. Each row is one frame.
%   conditionNames Optional cell array / string array of condition names.
%                  Default names correspond to the five Fig. 10 conditions
%                  when five datasets are supplied; otherwise generic names.
%   makeFigure     Optional logical flag (default true). If true, plot
%                  mean-centered coordinate fluctuations against frame index.
%
% OUTPUT
%   stats           Table with sample count, X/Y/Z ranges and sample SDs
%                  (MATLAB std(...,0), denominator N-1); all in mm.
%
% IMPORTANT
%   This publication-oriented routine does not select stationary intervals,
%   reconstruct positions, align trajectories, or perform window averaging.
%   NaN/Inf-containing rows are omitted as complete frames, with a warning.
%   Original laboratory geometry, paths and datasets are not provided.
%
% EXAMPLE
%   % Input is an Nx3 matrix of already reconstructed XYZ coordinates (mm):
%   % coords = readmatrix('approved_stationary_coordinates_mm.csv');
%   % stats = stability_analysis_public(coords, {'Air'}, true);
%
%   % To compare all five conditions:
%   % data = {airXYZ, sandXYZ, oneRebarXYZ, threeRebarXYZ, fiveRebarXYZ};
%   % stats = stability_analysis_public(data);
%
% Note: Original internal script computed descriptive XY statistics,
% including SD, from a two-column worksheet. This independent public
% function extends that principle to XYZ and adds axis ranges explicitly
% required by the manuscript. It is NOT a byte-for-byte legacy reproduction.

    if nargin < 2 || isempty(conditionNames)
        conditionNames = {};
    end
    if nargin < 3 || isempty(makeFigure)
        makeFigure = true;
    end
    validateattributes(makeFigure, {'logical','numeric'}, {'scalar'}, ...
        mfilename, 'makeFigure', 3);

    if isnumeric(coordinates)
        datasets = {coordinates};
    elseif iscell(coordinates)
        datasets = coordinates;
    else
        error('coordinates must be an N-by-3 numeric array or a cell array of arrays.');
    end
    nConditions = numel(datasets);
    if nConditions == 0
        error('At least one monitoring condition must be supplied.');
    end

    if isempty(conditionNames)
        if nConditions == 5
            names = {'Air', 'Quartz-sand wall', 'Single rebar', ...
                     'Three rebars', 'Five rebars'};
        else
            names = arrayfun(@(k) sprintf('Condition %d', k), ...
                             1:nConditions, 'UniformOutput', false);
        end
    else
        if isstring(conditionNames)
            conditionNames = cellstr(conditionNames);
        elseif ischar(conditionNames)
            conditionNames = {conditionNames};
        end
        if ~iscell(conditionNames) || numel(conditionNames) ~= nConditions || ...
                ~all(cellfun(@(s) ischar(s) && ~isempty(s), conditionNames))
            error('conditionNames must have one nonempty name per dataset.');
        end
        names = conditionNames(:)';
    end

    counts = zeros(nConditions, 1);
    ranges = zeros(nConditions, 3);
    sds = zeros(nConditions, 3);
    deviations = cell(nConditions, 1);
    frames = cell(nConditions, 1);

    for k = 1:nConditions
        xyz = datasets{k};
        validateattributes(xyz, {'numeric'}, {'2d','real','ncols',3}, ...
            mfilename, sprintf('coordinates{%d}',k));
        originalN = size(xyz, 1);
        keep = all(isfinite(xyz), 2);
        if any(~keep)
            warning('Condition %d: omitted %d frames with nonfinite XYZ.', ...
                    k, sum(~keep));
        end
        xyz = double(xyz(keep,:));
        if size(xyz, 1) < 2
            error('Condition %d requires at least two complete XYZ frames.', k);
        end
        counts(k) = size(xyz, 1);
        ranges(k,:) = max(xyz,[],1) - min(xyz,[],1);
        sds(k,:) = std(xyz,0,1);  % sample SD, N-1 convention
        deviations{k} = xyz - mean(xyz,1);
        frames{k} = find(keep);  % retain original frame index after filtering
        if originalN ~= counts(k)
            fprintf('Condition %s: %d of %d frames retained.\n', ...
                    names{k}, counts(k), originalN);
        end
    end

    stats = table(names(:), counts, ranges(:,1), ranges(:,2), ranges(:,3), ...
                  sds(:,1), sds(:,2), sds(:,3), ...
                  'VariableNames', {'Condition','Nframes', ...
                  'RangeX_mm','RangeY_mm','RangeZ_mm', ...
                  'SD_X_mm','SD_Y_mm','SD_Z_mm'});
    disp(stats);

    if logical(makeFigure)
        figure('Color','w','Name','Stationary coordinate fluctuations');
        for k = 1:nConditions
            subplot(nConditions,1,k);
            plot(frames{k}, deviations{k}(:,1), '-', ...
                 frames{k}, deviations{k}(:,2), '-', ...
                 frames{k}, deviations{k}(:,3), '-', 'LineWidth', 1);
            grid on;
            xlabel('Frame index');
            ylabel('Deviation (mm)');
            title(sprintf('(%s) %s (N = %d)', char('a'+k-1), ...
                          names{k}, counts(k)), 'Interpreter','none');
            legend({'X','Y','Z'}, 'Location','best');
        end
    end
end
