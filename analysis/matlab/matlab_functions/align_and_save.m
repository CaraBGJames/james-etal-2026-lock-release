function [times_crop, front_loc_crop, height_crop, plume_area_crop] = align_and_save(exp_name, backim, times, front_loc, height_pix, plume_area, y_pix_sz)
%ALIGN_AND_SAVE Aligns plume data to a common starting point and saves it to CSV files.
%
% This function identifies the last time step before the plume appears and
% trims all input data to start from that point. The processed data is then
% saved as CSV files.
%
% INPUTS:
%   times       - Array of time values (in seconds).
%   front_loc   - Array representing the front location of the plume (in meters).
%   height_pix  - 2D array of pixel heights (rows: time, columns: width).
%   plume_area  - Array representing the plume area (in square meters).
%   y_pix_sz    - Conversion for vertical pixel size to m from calibration.
%
% OUTPUTS:
%   No direct output to workspace. The function saves the following CSV files:
%     - 'example_front_m.csv': Trimmed front location data.
%     - 'example_area_m2.csv': Trimmed plume area data.
%     - 'example_height_m.csv': Trimmed height data, converted from pixels to meters.
%     - 'example_time_s.csv': Adjusted time data.
%
% USAGE:
%   align_and_save(times, front_loc, height_pix, plume_area);
%
% NOTES:
%   - The function assumes that the plume appears when `front_loc` becomes nonzero.
%   - Ensure that `saveloc` and conversion factors (e.g., `y_pix_sz`) are defined before calling.


    % find time where plume appears
    cut_idx = find(front_loc==0,1,'last'); %last 0 of front
    
    %front 1D (size of time) - in m
    file_name = strcat(exp_name,'_front_m.csv');
    front_loc_crop = front_loc(cut_idx:end); %crop
    writematrix(front_loc_crop,file_name); 
    
    %area_real 1D (size of time) - in m^2
    file_name = strcat(exp_name,'_area_m2.csv');
    plume_area_crop = plume_area(cut_idx:end);
    writematrix(plume_area_crop,file_name);
    
    %h 2D (time x width) - in m
    file_name = strcat(exp_name,'_height_m.csv');
    height = (size(backim,1) - height_pix)*y_pix_sz; %flip and convert
    height_crop = height(cut_idx:end,:);
    writematrix(height_crop,file_name);
    
    %time 1D - in s
    file_name = strcat(exp_name,'_time_s.csv');
    times_crop = times(1:end-cut_idx+1);
    writematrix(times_crop,file_name); %crop and save
end