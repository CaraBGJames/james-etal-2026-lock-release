function [backim, angle] = rotate_image_interactively(vid, start_frame)
    % Read and display the image
    img = read(vid, start_frame);
    figure;
    imshow(img);
    title('Draw a line along the correct horizontal alignment');
    
    % Let the user draw a line
    h = drawline;  % Works in MATLAB R2018b+
    waitforbuttonpress; % Wait for user to press Enter
    
    % Get the coordinates of the line
    position = h.Position; 

    % Calculate the angle of the line
    delta_y = position(2,2) - position(1,2);
    delta_x = position(2,1) - position(1,1);
    angle = atan2d(delta_y, delta_x); % Convert from radians to degrees

    % Rotate the image
    backim = imrotate(img, angle);

    % Display the angle in the command window
    fprintf('Rotation angle: %.2f degrees\n', angle);

    % Close the figure window
    close(gcf);
end