% Plume Analysis from Video: Rotation, Cropping, Thresholding, and Visualization
%
% This script analyzes a video to extract and visualize the evolution of a plume.
% It performs the following steps:
% 1.  Reads a video file and allows interactive rotation and cropping.
% 2.  Calculates pixel size and calibration.
% 3.  Processes a specific frame to remove background, threshold, and smooth the plume.
% 4.  Generates a figure showing the processing steps and the plume boundary.
% 5.  Processes multiple frames across time to show plume evolution.
% 6.  Generates a figure showing the plume at different time steps with scale bars.
%
% Inputs:
%   - Video file (.MP4)
%   - Start and end times for analysis (seconds)
%   - User-defined rotation angle and crop region (interactive)
%
% Outputs:
%   - Figures showing processing steps and plume evolution (.png, optional)
%   - Pixel area, pixel sizes, and calibration coefficients.
%
% Dependencies:
%   - VideoReader (MATLAB built-in)
%   - rotate_image_interactively.m (user-defined function)
%   - crop_image_interactively.m (user-defined function)
%   - check_calibration.m (user-defined function)

clear all;
close all;
addpath("matlab_functions")

% Define file location and read in video
directory_path = 'PATH_TO_RAW_VIDEOS_HERE';
exp_name = 'example_vid';
vid_file_path = fullfile(directory_path, [exp_name, '.MP4']);
vid = VideoReader(vid_file_path);

% Input start and end time you want to analyze
vid_start = 35;
vid_end = 74;

% Set framerate, start and end frame, number of frames
framerate = vid.FrameRate;
vid_start_frame = ceil(vid_start * framerate);
vid_end_frame = ceil(vid_end * framerate);

% Get user input to define rotation angle
[backim, angle] = rotate_image_interactively(vid, vid_start_frame);
endim = imrotate(read(vid, vid_end_frame), angle); %end frame

% Get user input to crop it
[backim, crop_region, xi, yi] = crop_image_interactively(backim);
endim = backim - imcrop(endim, crop_region); %same for end frame

% show parallax effect graph, get pixel area
[pix_area, x_coeff, y_pix_sz, x_pix_sz] = check_calibration(backim, xi, yi);

%preprocess end image
endim = endim(:,:,3);
endim =  imgaussfilt(imlocalbrighten(endim, 0.5), 0.5);

%% pick new crop region for the image

[fig_crop, fig_crop_region] = imcrop(endim);
fig_backim = imcrop(backim, fig_crop_region);
close all
%% Get all the editing steps for cropped area
save_im = true;

% Set threshold
fudge_factor = 0.9; % Initial fudge factor
thresh = graythresh(endim) * fudge_factor;

% Pick frame
time_after_start = 35;
frame = vid_start_frame + ceil(time_after_start * framerate);
% frame = vid_end_frame;

% Image editing steps for the given frame
im_rotated = imrotate(read(vid, frame), angle); % Rotate if needed

im_cropped1 = imcrop(im_rotated, crop_region);
im_cropped = imcrop(im_cropped1, fig_crop_region); %small region option

im_noback = backim - im_cropped1; % Crop and remove background
im_noback = fig_backim - im_cropped; % small region option

im_gray = im_noback(:,:,3); % Take 3rd channel

im_local = imlocalbrighten(im_gray, 0.5); %local brighten

im_gauss = imgaussfilt(im_local, 0.5); % gaussian

im_thresh = imbinarize(im_gauss, thresh); % Threshold using provided value

im_open = ~bwareaopen(~im_thresh, 80); % Remove small holes (inverted)

im_blob = bwareafilt(im_open, 1); % Keep only the biggest blob

windowSize = 9;
kernel = ones(windowSize) / windowSize^2;
im_smooth = conv2(single(im_blob), kernel, 'same'); %smooth binary image

im_final = im_smooth > 0.5; % Rethreshold for final plume

if save_im == true
    imwrite(im_noback, "im_noback.jpg", Quality=100)
    imwrite(im_gray, "im_gray.jpg", Quality=100)
    imwrite(im_local, "im_local.jpg", Quality=100)
    imwrite(im_gauss, "im_gauss.jpg", Quality=100)
    imwrite(im_thresh, "im_thresh.jpg", Quality=100)
    imwrite(im_open, "im_open.jpg", Quality=100)
    imwrite(im_blob, "im_blob.jpg", Quality=100)
    imwrite(im_smooth, "im_smooth.jpg", Quality=100)
    imwrite(im_final, "im_final.jpg", Quality=100)
end

%% Show boundary on end image

%purple overlay
image_for_overlay = 255 - im_gray;

if sum(im_final, 'all') ~= 0
    purple_over = labeloverlay(image_for_overlay, im_final, 'Transparency', 0.8, "Colormap", [1, 0, 1]);
else
    purple_over = image_for_overlay;
end

% Display the image
figure;
imshow(purple_over);
hold on;

% Overlay the perimeter in red
[B, L] = bwboundaries(im_final, 'noholes'); % Extract boundary
for k = 1:length(B)
    boundary = B{k};
    boundary = boundary(boundary(:, 2) ~= 1, :); %get rid of left edge
    boundary = boundary(boundary(:, 1) < size(im_final, 1) - 5, :); %limit y val
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2);
end

hold off;

%% Stack images for display
save_im = false; % Want to save it?

O = im_cropped1;
A1 = 255 - im_1;
A2 = uint8(255 - repmat(im_2, 1, 1, 3));
B = uint8(255 - repmat(im_4 * 255, 1, 1, 3));
if sum(im_8, 'all') ~= 0
    C = labeloverlay(255 - im_2, im_8, 'Transparency', 0.9, "Colormap", [1, 0, 1]);
else
    C = A2;
end

% Find boundary
bound = bwboundaries(im_8, 'noholes');
boundary = bound{1};
boundary = boundary(boundary(:, 2) ~= 1, :);
boundary = boundary(boundary(:, 1) < size(im_8, 1) - 3, :);

% Make figure of all the steps
figure;
image = [O; A1; A2; B; C; A2];
imshow(image);
hold on;
plot(boundary(:, 2), boundary(:, 1) + size(im_8, 1) * 5, 'red', 'LineWidth', 3);
hold off;

% Plot the actual scale axes (y first)
y_max = 0.25 / y_pix_sz;
new_y_pix = flip(size(image, 1):-y_max / 4:size(image, 1) - y_max);
new_y_val = 25:-5:0;
new_x_val = 0:10:200;
new_x_pix = (new_x_val / (x_pix_sz)) + 1;
xlabel('length (cm)');
yl = ylabel('height (cm)');
yl.Position(2) = yl.Position(2) * 1.8;
h = gca;
h.Visible = 'on';
h.Box = 'off';
set(h, 'YTick', new_y_pix, 'YTickLabel', new_y_val);
set(h, 'XTick', new_x_pix, 'XTickLabel', new_x_val);
h.FontSize = 14;
set(gcf, 'Position', [10 10 1300 800]);

% if save_im == true
%     exportgraphics(gcf,'example_fig_1.png')
% end

%% Figure showing plume through time
save_im = false; % Want to save it?

% Work out what time steps to show it at, get frames
t_series = [10,20,30,40]-2;
frame_list = ceil((t_series + vid_start) * framerate) + 1;
image = []; %empty image to fill
space = uint8(255 * repmat(ones(5, size(im_8, 2)), 1, 1, 3)); %white line between

for f = frame_list
    % Image editing steps for the given frame
    im_rotated = imrotate(read(vid, f), angle);
    im_cropped = imcrop(im_rotated, crop_region);
    im_1 = backim - im_cropped;
    im_2 = im_1(:,:,3);
    im_3 = imgaussfilt(imlocalbrighten(im_2, 0.5), 0.5);
    im_4 = imbinarize(im_3, thresh);
    im_5 = ~bwareaopen(~im_4, 80);
    im_6 = bwareafilt(im_5, 1);
    im_7 = conv2(single(im_6), kernel, 'same');
    im_8 = im_7 > 0.5;
    if sum(im_8, 'all') ~= 0
        C = labeloverlay(255 - im_2, im_8, 'Transparency', 0.9, "Colormap", [1, 0, 1]);
    else
        C = uint8(255 - repmat(im_2, 1, 1, 3));
    end

    if isempty(image)
        image = C;
    else
        image = [image; space; C];
    end
end

% MAKE FIGURE
figure;
imshow(image);

% Add text
startx = 1650;
starty = size(im_8, 1) / 2;
for t = t_series
    to_add = [num2str(t), ' s'];
    text(startx, starty, to_add, 'FontSize', 14);
    starty = starty + size(im_8, 1) + 5;
end

% Change axes
y_max = 0.25 / y_pix_sz;
new_y_pix = flip(size(image, 1):-y_max / 4:size(image, 1) - y_max);
new_y_val = 25:-5:0;
new_x_val = 0:10:200;
new_x_pix = (new_x_val / (x_pix_sz)) + 1;
xlabel('length (cm)');
yl = ylabel('height (cm)');
yl.Position(2) = yl.Position(2) * 1.8;
h = gca;
h.Visible = 'on';
h.Box = 'off';
set(h, 'YTick', new_y_pix, 'YTickLabel', new_y_val);
set(h, 'XTick', new_x_pix, 'XTickLabel', new_x_val);
h.FontSize = 14;
set(gcf, 'Position', [10 10 1400 800]);

if save_im == true
    exportgraphics(gcf,'example_fig_2.png')
end