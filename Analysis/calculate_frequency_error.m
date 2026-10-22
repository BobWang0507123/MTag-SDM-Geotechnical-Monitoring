function result = calculate_frequency_error(visual_xy, magnetic_xy, fs)
%CALCULATE_FREQUENCY_ERROR Compare dominant trajectory frequencies (Hz).
%   RESULT = CALCULATE_FREQUENCY_ERROR(VISUAL_XY,MAGNETIC_XY,FS)
%   Both inputs are N-by-2 [x y] time-aligned, uniformly sampled trajectories.
%   Use an appropriate common sampling grid before calling this function.
%   X/Y signals are mean-centered; radial signal is sqrt(dx^2+dy^2) AFTER
%   separately linear-detrending x and y. The radial construction can
%   produce harmonic peaks and is not equivalent to a signed displacement.
%
%   Retained from the source script: Hann window, coherent-gain amplitude
%   correction U=sum(w)/N, 2*abs(fft)/(N*U), candidates f>0.1 Hz,
%   and bins 1:floor(N/2) (MATLAB one-based indexing).
%   NEW metric: abs(dominant magnetic frequency - visual frequency),
%   separately for radial, x and y. No relative frequency error is claimed.
%
%   Requires Signal Processing Toolbox (hann) or compatible hann function.
    validateattributes(visual_xy,{'numeric'},{'real','2d','ncols',2},mfilename,'visual_xy',1);
    validateattributes(magnetic_xy,{'numeric'},{'real','2d','ncols',2},mfilename,'magnetic_xy',2);
    validateattributes(fs,{'numeric'},{'real','scalar','finite','positive'},mfilename,'fs',3);
    if any(~isfinite(visual_xy(:))) || any(~isfinite(magnetic_xy(:)))
        error('Inputs must be finite; clean and synchronize observations first.');
    end
    if size(visual_xy,1)~=size(magnetic_xy,1) || size(visual_xy,1)<4
        error('Both trajectories must have equal row counts (at least 4).');
    end
    result.visual = local_peaks(visual_xy,fs);
    result.magnetic = local_peaks(magnetic_xy,fs);
    result.abs_error_hz.radial = abs(result.magnetic.radial.frequency_hz - result.visual.radial.frequency_hz);
    result.abs_error_hz.x = abs(result.magnetic.x.frequency_hz - result.visual.x.frequency_hz);
    result.abs_error_hz.y = abs(result.magnetic.y.frequency_hz - result.visual.y.frequency_hz);
    result.fs_hz = fs;
    result.n_points = size(visual_xy,1);
end

function out = local_peaks(xy,fs)
    n=size(xy,1);
    w=hann(n);
    gain=sum(w)/n;
    freq=(0:n-1)'*(fs/n);
    half=(1:floor(n/2))';
    usable=half(freq(half)>0.1);
    radial=sqrt(detrend(xy(:,1)).^2+detrend(xy(:,2)).^2);
    out.radial=peak_info(radial,w,gain,n,freq,usable);
    out.x=peak_info(xy(:,1)-mean(xy(:,1)),w,gain,n,freq,usable);
    out.y=peak_info(xy(:,2)-mean(xy(:,2)),w,gain,n,freq,usable);
end

function s=peak_info(signal,w,gain,n,freq,usable)
    s.frequency_hz=NaN;
    s.amplitude=NaN;
    if isempty(usable), return; end
    amplitude=2*abs(fft(signal.*w))/(n*gain);
    [a,idx]=max(amplitude(usable));
    s.amplitude=a;
    s.frequency_hz=freq(usable(idx));
end
