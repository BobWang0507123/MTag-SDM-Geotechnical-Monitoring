function result = calculate_trajectory_error(visual_xy, magnetic_xy)
%CALCULATE_TRAJECTORY_ERROR Two-dimensional trajectory comparison.
%   RESULT = CALCULATE_TRAJECTORY_ERROR(VISUAL_XY, MAGNETIC_XY)
%   accepts N-by-2 and M-by-2 trajectories, each ordered as [x y].
%   Returns resampled trajectories, Procrustes-aligned magnetic trajectory,
%   pointwise Euclidean error, mean, max, min and position RMSE.
%
%   Scientific method extracted from guijiduibifenxiheji1_xin.m:
%   independent trajectory-length normalization by linear interpolation,
%   MATLAB Procrustes alignment with its DEFAULT scaling/reflection options,
%   and pointwise Euclidean distance.
%
%   IMPORTANT: The source script removed NaNs from each coordinate SEPARATELY.
%   This public function instead rejects nonfinite rows as intact (x,y)
%   pairs; on datasets with missing values this can change results. To
%   reproduce historical numerical results, validate the original cleaning
%   and use an appropriately preprocessed dataset.
%
%   Requires MATLAB Statistics and Machine Learning Toolbox (procrustes).
    validateattributes(visual_xy, {'numeric'}, {'real','2d','ncols',2}, mfilename,'visual_xy',1);
    validateattributes(magnetic_xy, {'numeric'}, {'real','2d','ncols',2}, mfilename,'magnetic_xy',2);
    visual_xy = visual_xy(all(isfinite(visual_xy),2),:);
    magnetic_xy = magnetic_xy(all(isfinite(magnetic_xy),2),:);
    if size(visual_xy,1)<2 || size(magnetic_xy,1)<2
        error('Each trajectory must have at least two complete finite points.');
    end
    n = min(size(visual_xy,1), size(magnetic_xy,1));
    tau = linspace(0,1,n)';
    tv = linspace(0,1,size(visual_xy,1))';
    tm = linspace(0,1,size(magnetic_xy,1))';
    v = [interp1(tv,visual_xy(:,1),tau,'linear'), ...
         interp1(tv,visual_xy(:,2),tau,'linear')];
    m = [interp1(tm,magnetic_xy(:,1),tau,'linear'), ...
         interp1(tm,magnetic_xy(:,2),tau,'linear')];
    [~, aligned, transform] = procrustes(v,m);
    e = sqrt(sum((v-aligned).^2,2));
    result.visual_xy = v;
    result.magnetic_xy_resampled = m;
    result.magnetic_xy_aligned = aligned;
    result.point_error = e;
    result.mean_error = mean(e);
    result.max_error = max(e);
    result.min_error = min(e);
    result.rmse_position = sqrt(mean(e.^2));
    result.transform = transform;
    result.n_points = n;
end
