function [column_timeseries_im, x_m]= height_profile_xpix(vid, vid_start_frame, vid_end_frame, x_coeff)
% HEIGHT_PROFILE_XPIX Extracts the time series of a 1-pixel-wide vertical column (grayscale) from a video.
%
% Inputs:
%   vid             - VideoReader object
%   vid_start_frame - First frame index
%   vid_end_frame   - Last frame index
%   x_coeff         - coefficients convert x_pix to m
%   x_m             - distance from gate of the profile in m    
%
% Output:
%   column_timeseries_im - [height x n_frames] grayscale image of column over time


    disp("progress... (%)")

    % Number of frames and column height
    n_frames = vid_end_frame - vid_start_frame + 1;
    
    % Show frame for user to select ROI
    endim = read(vid, vid_end_frame);
    imshow(endim);
    title('Select top and bottom of tank at column you want to profile.');
    [xi, yi] = getpts;
    close(gcf);

    % Get crop bounds
    top = round(min(yi));
    bottom = round(max(yi));
    output_height = bottom - top + 1;

    %get x distance
    col = round(mean(xi));  % Use average x for column
    x_m = polyval(x_coeff,col); %get loc in m 

    % Read background frame
    backim = read(vid, vid_start_frame);
    backim_crop = backim(top:bottom, col, 3);  % blue channel

    
    % Preallocate result (grayscale)
    column_timeseries_im = zeros(output_height, n_frames, 'like', backim_crop);

    % Loop through frames
    for i = 1:n_frames
        k = vid_start_frame + i - 1;

        frame = read(vid, k);
        im_cropped = frame(top:bottom, col, 3);  % blue channel

        im_diff = backim_crop - im_cropped;
        column_timeseries_im(:, i) = im_diff;

        % Display progress
        if rem(i,50) == 0 || i == n_frames
            fprintf('%.1f%% complete\n', 100 * i / n_frames);
        end
    end
end
