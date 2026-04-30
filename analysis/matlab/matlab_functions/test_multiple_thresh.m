function [test_im_cropped, boundary] = test_multiple_thresh(test_frame, thresh, vid, backim, angle, crop_region)
%TEST_THRESHOLD Test thresholding value to find edges of the plume
%   on a specific frame of a video.
%   This function processes a given video frame by applying various image
%   processing techniques, including rotation, cropping, background 
%   subtraction, Gaussian filtering, thresholding, blob detection, and 
%   edge smoothing. It then visualizes the result by overlaying the 
%   detected boundaries and plots the processed images.
%
%   Parameters:
%     test_frame (int): The frame number to be processed from the video.
%     thresh (double): The threshold value used for binarization.
%     vid (VideoReader): The VideoReader object corresponding to the video.
%     backim (matrix): The background image used for background subtraction.
%     angle (double): The angle by which to rotate the frame (in degrees).
%     crop_region (4-element vector): The cropping region in the format
%                                     [xmin, ymin, width, height] for cropping.
%
%   Outputs:
%     Boundary array of heights 

    % Image editing steps for the given frame
    test_im_rotated = imrotate(read(vid,test_frame),angle); % Rotate if needed
    test_im_cropped = imcrop(test_im_rotated, crop_region);
    test_im_1 = backim - test_im_cropped; % Crop and remove background
    test_im_2 = test_im_1(:,:,3); % Take 3rd channel
    test_im_3 = imgaussfilt(imlocalbrighten(test_im_2, 0.5), 0.5); % Stretch and edit

    % Thresholding
    test_im_4 = imbinarize(test_im_3, thresh); % Threshold using provided value

    % Find the plume
    test_im_5 = ~bwareaopen(~test_im_4,80); % Remove small holes
    test_im_6 = bwareafilt(test_im_5,1); % Keep only the biggest blob
    
    % Smooth edges
    windowSize = 9;
    kernel = ones(windowSize) / windowSize^2;
    test_im_7 = conv2(single(test_im_6), kernel, 'same');
    test_im_8 = test_im_7 > 0.5; % Rethreshold

    % Plot to show edges
    figure
    A1 = uint8(255 - repmat(test_im_2, 1, 1, 3)); % Original 3rd channel
    A2 = uint8(255 - repmat(test_im_4*255, 1, 1, 3)); % Thresholded image
    if sum(test_im_8, 'all') ~= 0
        B = labeloverlay(255 - test_im_2, test_im_6, 'Transparency', 0.9, "Colormap", [1, 0, 1]); % Unsmoothed
        C = labeloverlay(255 - test_im_2, test_im_8, 'Transparency', 0.9, "Colormap", [1, 0, 1]); % Smoothed
    else
        B = A1;
        C = A1;
    end
    
    % Find boundary
    bound = bwboundaries(test_im_8, 'noholes');
    boundary = bound{1};
    boundary = boundary(boundary(:,2) ~= 1, :);
    boundary = boundary(boundary(:,1) < size(test_im_8, 1) - 3, :);
    
    % imshow([test_im_cropped; A1; A2; B; C])
    % pause(0.2)
    % hold on
    % plot(boundary(:,2), boundary(:,1) + size(test_im_8, 1) * 4, 'red', 'LineWidth', 3)
    % hold off
end