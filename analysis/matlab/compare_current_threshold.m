clear all
close all
tic

%load functionsc
addpath("matlab_functions")

% Define file location and read in video
directory_path = "";
exp_name = 'example_vid';
folder_path = 'PATH_TO_RAW_VIDEOS_HERE';
vid_file_path = strcat(folder_path, exp_name, '.MP4');
vid = VideoReader(vid_file_path);

% Input start and end time you want to analyze
vid_start = 7.5;%8;
vid_end = 60+17; %27;
 
% Set framerate, start and end frame, number of frames
framerate = vid.FrameRate;
vid_start_frame = ceil(vid_start * framerate);
vid_end_frame = ceil(vid_end * framerate);

% Get user input to define rotation angle
[backim, angle] = rotate_image_interactively(vid, vid_start_frame);
endim = imrotate(read(vid,vid_end_frame),angle); %end frame

% Get user input to crop it
[backim, crop_region, xi, yi] = crop_image_interactively(backim);
endim = backim - imcrop(endim, crop_region); %same for end frame

% show parallax effect graph, get pixel area
[pix_area, x_coeff, y_pix_sz] = check_calibration(backim, xi, yi);

%preprocess end image
endim = endim(:,:,3);
endedit =  imgaussfilt(imlocalbrighten(endim, 0.5), 0.5);

% Threshold testing loop
test_frame = vid_end_frame-60; % Frame to test thresholding
fudge_factor = 1; % Range of fudge factors

% Compute thresholds
thresh = graythresh(endedit) * fudge_factor;

% Display test thresholded image
fprintf('Testing threshold with fudge factor = %.2f\n', fudge_factor);

%% 
thresholds = [0.8, 1.0, 1.2]; % low, mid, high
lineColors = [0 0 1;   % low - dark blue
              1 0.00 0.0;   % mid - dark magenta
              0 0 0];            % high - black
dashPatterns = {[4 2], [1 0], [2 2]}; % points: [dash gap], adjust as needed

boundaries = cell(1, numel(thresholds));
% test_im_2_current = test_im_2;  % preserve for display

% Compute boundaries
for k = 1:numel(thresholds)
    [test_im_2_current, b] = test_multiple_thresh(test_frame, thresh*thresholds(k), vid, backim, angle, crop_region);
    boundaries{k} = b;
end

% Plot
imshow(test_im_2_current)
pause(0.2)
hold on

for k = 1:numel(boundaries)
    b = boundaries{k};
    x = smoothdata(b(:,2), 'sgolay', 20);
    y = smoothdata(b(:,1), 'sgolay', 20);

    h = plot(x, y, 'Color', lineColors(k,:), 'LineWidth', 3);

    % % Apply custom dash pattern (R2022b or later)
    % if ~isempty(dashPatterns{k})
    %     h.LineStyle = '-';            % required for DashPattern to work
    %     h.DashPattern = dashPatterns{k};
    % end
end

hold off
