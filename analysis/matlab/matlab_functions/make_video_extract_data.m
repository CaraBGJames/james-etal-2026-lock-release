function [times, front_loc, height_pix, plume_area] = make_video_extract_data(exp_name, vid, backim, vid_start_frame, vid_end_frame, thresh, angle, crop_region, pix_area, x_coeff, every_nth)
%MAKE_VIDEO_EXTRACT_DATA Processes a video to extract plume characteristics and creates an edited video.
%
%   [FRONT_LOC, HEIGHT_PIX, PLUME_AREA] = MAKE_VIDEO_EXTRACT_DATA(VID, BACKIM, VID_START_FRAME, VID_END_FRAME, THRESH, ANGLE, CROP_REGION, PIX_AREA, EVERY_NTH)
%   processes the input video VID by removing the background BACKIM and extracting
%   features related to a plume's movement. It also generates an annotated output video.
%
%   Inputs:
%       VID            - VideoReader object representing the input video.
%       BACKIM         - Background image to be subtracted from each frame.
%       VID_START_FRAME - The starting frame index for processing.
%       VID_END_FRAME   - The ending frame index for processing.
%       THRESH         - Threshold value for binarization.
%       ANGLE          - Rotation angle (in degrees) applied to frames.
%       CROP_REGION    - Cropping rectangle specified as [x, y, width, height].
%       PIX_AREA       - Area of a single pixel in physical units.
%       X_COEFF        - Output of polyfit of the selected pixels to real.
%       EVERY_NTH      - Process every nth frame to speed up analysis.
%
%   Outputs:
%       TIMES      - Array of time after start of video
%       FRONT_LOC  - Array containing the detected front location in physical units.
%       HEIGHT_PIX - Matrix storing plume height information for each processed frame.
%       PLUME_AREA - Array of estimated plume areas in physical units.
%
%   The function performs image preprocessing, thresholding, and feature extraction
%   to identify and track the plume across frames. The processed video is saved
%   as 'edited_example_vid.mp4'.

    % 

    %get number of frames for arrays
    n_frames = ceil(vid_end_frame - vid_start_frame + 1/every_nth);
    
    % initialise empty arrays
    plume_area = zeros(n_frames,1);
    front_loc = zeros(n_frames,1);
    height_pix = ones(n_frames,size(backim,2))*size(backim,1); %set at max of image size due to reversed y
    times = ((0:every_nth:vid_end_frame-vid_start_frame) * 1/vid.FrameRate)';

    %check if frame will have an even number in both directions
    [h, w, c] = size(backim); % h = height (rows), w = width (columns)

    % Add a row if height is odd
    if mod(h, 2) == 1
        new_row = uint8(255 * ones(1, w, 3));
    else
        new_row = [];
    end

    % Add a column if width is odd
    if mod(w, 2) == 1
        new_col = uint8(255 * ones(h + (mod(h, 2) == 1), 1, 3));
    else
        new_col = [];
    end

    % open animation writer 
    vwObj = VideoWriter(strcat(exp_name,'_edit.avi'),'Motion JPEG AVI');
    vwObj.FrameRate = vid.FrameRate/every_nth; %so plays at real speed
    vwObj.Quality = 100;
    open(vwObj);
    
    disp("progress... (%)")
    
    i = 0;
    for k = vid_start_frame:every_nth:vid_end_frame %middle number to skips frames if want fast version
        i = i + 1; %index for saving
        
        % Image editing steps for the given frame
        im_rotated = imrotate(read(vid,k),angle); % Rotate if needed
        im_cropped = imcrop(im_rotated, crop_region);
        im_1 = backim - im_cropped; % Crop and remove background
        im_2 = im_1(:,:,3); % Take 3rd channel
        im_3 = imgaussfilt(imlocalbrighten(im_2, 0.5), 0.5); % Stretch and edit
    
        % Thresholding
        im_4 = imbinarize(im_3, thresh); % Threshold using provided value
    
        % Find the plume
        im_5 = ~bwareaopen(~im_4,80); % Remove small holes
        im_6 = bwareafilt(im_5,1); % Keep only the biggest blob
        
        % Smooth edges
        windowSize = 9;
        kernel = ones(windowSize) / windowSize^2;
        im_7 = conv2(single(im_6), kernel, 'same');
        im_8 = im_7 > 0.5; % Rethreshold
    
        % save plume area, front, height
        area = sum(im_8, 'all');
        if area > 0
            plume_area(i) = area*pix_area; %saves area of blob in m^2 (estimate)
            front_pix = find(sum(im_8,1)>0, 1 ,'last'); %location of the front in pixels
            front_loc(i) = polyval(x_coeff,front_pix+crop_region(1)); %adds difference in original vs cropped x loc
            
            %height info
            for col = 1:front_pix %loop through columns of blob
                slice = im_8(:,col);
                if sum(slice)>0 %check slice not empty
                    h = find(slice,1,'first');
                    height_pix(i,col) = h; % from top to bottom, find first non-zero
                end

            end

        end
        
        %write video
        if area > 0 %if plume not empty
            edited_im = labeloverlay(255-im_2, im_8, 'Transparency', 0.9, "Colormap",[1,0,1]);
        else
            edited_im = repmat(255-im_2,1,1,3);
        end

        % % pad if needed
        edited_im = [edited_im; new_row];
        edited_im = [edited_im, new_col];

        % Ensure uint8 data type for correct encoding
        if ~isa(edited_im, 'uint8')
            edited_im = im2uint8(edited_im);
        end
        
        writeVideo(vwObj, edited_im);
    
        %progress tracker
        if rem(k,50) == 0
            fprintf('%.1f\n',(k-vid_start_frame)/(vid_end_frame-vid_start_frame)*100); 
        end

    end
    
    system(sprintf('ffmpeg -i %s_edit.avi -c:v libx264 -c:a aac -strict experimental %s_edit.mp4', exp_name, exp_name));
end



