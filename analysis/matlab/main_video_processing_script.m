% This script processes a video of a plume experiment, allowing the user to:
%
% 1) Select a start and end time for analysis.
% 2) Define a cropping region and correct for rotation.
% 3) Interactively adjust the threshold used to detect the plume.
% 4) Generate a new video displaying the selected region, the original video, 
%    and a thresholded version of the plume with overlay to show selection.
% 5) Save processed data as CSV files, including:
%    a) Plume area over time (m²)1.
%    b) Plume front location over time (m)
%    c) Plume height profile over time (m)
%    d) Time values (s)
%
% The user is prompted to adjust the thresholding parameter ("fudge factor") 
% until satisfied before processing the full video.
%
% Outputs:
% - A processed video showing the extracted plume.
% - CSV files with analyzed plume properties for further analysis.
%
% Author: [Cara B G James]
% Date: [April 2025]

clear all
close all
tic

%load functionsc
addpath("matlab_functions")

% Define file location and read in video
exp_name = ['example_vid'];
folder_path = 'PATH_TO_RAW_VIDEOS_HERE';
vid_file_path = strcat(folder_path, exp_name, '.MP4');
vid = VideoReader(vid_file_path);

% Input start and end time you want to analyze
vid_start =8;
vid_end = 27;
 
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
fudge_factor = 1; % Initial fudge factor

while true
    % Compute threshold
    thresh = graythresh(endedit) * fudge_factor;

    % Display test thresholded image
    fprintf('Testing threshold with fudge factor = %.2f\n', fudge_factor);
    test_threshold(test_frame, thresh, vid, backim, angle, crop_region);

    % Ask user for input
    user_input = input('Enter a new fudge factor or type "c" to continue: ', 's');

    % If the user types "c", break the loop and proceed
    if strcmpi(user_input, 'c')
        break;
    end

    % Otherwise, update the fudge factor
    new_fudge = str2double(user_input);
    if ~isnan(new_fudge) && new_fudge > 0
        fudge_factor = new_fudge;
    else
        disp('Invalid input. Please enter a positive number or "c" to continue.');
    end
end

%close any figures
close all

% Thresholded plume video and save loop
[times, front_loc, height_pix, plume_area] = make_video_extract_data(exp_name,vid, backim, vid_start_frame, vid_end_frame, thresh, angle, crop_region, pix_area, x_coeff, 1);

% Align and save data
[times_crop, front_loc_crop, height_crop, plume_area_crop] = align_and_save(exp_name, backim, times, front_loc, height_pix, plume_area, y_pix_sz);

toc

%%
% Create and size the figure: [left, bottom, width, height] in pixels
figure('Position', [100, 100, 400/25*160, 400]);

% Initial plot
h = plot(height_crop(1, :));
ylim([0, 0.25]);                   % Fix Y-axis
xlim([1, size(height_crop, 2)]);   % Fix X-axis
axis manual;                       % Lock axes

n_step = 10;                       % Every 10th frame

for t = 1:n_step:size(height_crop, 1)
    h.YData = height_crop(t, :);   % Update the existing line
    title(sprintf('Timestep: %d', t));  % Optional: show timestep
    drawnow;
    pause(0.02);                   % Slow it down (adjust as needed)
end
