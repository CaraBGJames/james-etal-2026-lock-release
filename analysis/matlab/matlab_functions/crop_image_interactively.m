function [backim, crop_region, xi, yi] = crop_image_interactively(backim)
    %show and give prompt
    figure;
    imshow(backim);
    title('Crop the image. LHS = edge of lock, BASE = just above dark line of base.')
    disp('Select crop region and double-click to confirm.');
    
    %user selects crop region
    [backim,crop_region] = imcrop(backim);
    disp('Click on all vertical lines (left to right) inside water, then top and bottom of the tank.');
    
    [xi, yi] = getpts; %click on all vertical lines in order L to R inside water, then top and bottom of tank (calibration).
    
    xi = xi(1:end-2);
    yi = yi(end-1:end);

    % Close figure window after selection
    close(gcf);
end