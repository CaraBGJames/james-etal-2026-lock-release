function [pix_area, x_coeff, y_pix_sz, x_pix_sz] = check_calibration(backim, xi, yi)
    %actual locations of the lines (every 10cm after the gate is 1.8cm)
    x_real = [1.8/100,(10:10:200)/100]; %in m
    y_real = [0, 0.3]; %30cm high
    
    %create function to transfer pixels to distance
    x_coeff = polyfit(xi,x_real(1:length(xi)),2); %'real' is the y value, x2 for curve
    y_coeff = polyfit(yi, y_real,1); %linear (2 points)
    x_pix = 1:size(backim,2); %however long backim is in pix
    x_fit = polyval(x_coeff, x_pix);
    
    %average pixel size for area
    x_pix_sz = mean(diff(x_fit));
    y_pix_sz = abs(diff(y_real)/(diff(yi)));
    pix_area = x_pix_sz * y_pix_sz;

    %plot
    figure
    scatter(xi, x_real(1:length(xi)))
    hold on
    plot(x_pix, x_fit)
    hold off
    title('Calibrating horizontal scale')
    xlabel('(uncropped) image horizontal pixels')
    ylabel('Real horizontal location from gate (m)')
    legend('location of vertical bars','x^2 fit', Location='northwest')
end