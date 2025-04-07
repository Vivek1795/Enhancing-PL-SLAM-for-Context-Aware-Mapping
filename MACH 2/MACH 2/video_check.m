% Create objects for video capturing and figure display
vid = videoinput('winvideo', 1, 'YUY2_640x480'); % Adjust the device ID and format as needed
src = getselectedsource(vid);
vid.FramesPerTrigger = 1;
vid.ReturnedColorspace = 'rgb';
preview(vid);
figure;

% Configure the video input object to stop after 100 frames
vid.TriggerRepeat = 100;
start(vid);

oldLines = [];

while(vid.FramesAcquired <= vid.TriggerRepeat)  % Loop while the video is capturing
    frame = getdata(vid, 1, 'uint8');    % Acquire a single frame
    flushdata(vid);                      % Remove frame from memory

    grayImage = rgb2gray(frame);         % Convert frame to grayscale
    % Detect edges using Canny edge detector
    edges = edge(grayImage, 'Canny');
    % Perform Hough Transform to detect lines
    [H,theta,rho] = hough(edges);
    % Find peaks in the Hough Transform
    peaks = houghpeaks(H, 10);
    % Extract line segments based on the peaks in Hough Transform
    lines = houghlines(edges, theta, rho, peaks, 'FillGap', 20, 'MinLength', 30);

    imshow(frame); hold on;
    
    % Display the current lines in green
    for k = 1:length(lines)
        xy = [lines(k).point1; lines(k).point2];
        plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'green');
    end
    
    % Optionally, compare 'lines' with 'oldLines' to match lines between frames
    % This would require custom code to match lines based on their properties

    % Store current lines as old lines for comparison with the next frame
    oldLines = lines;
    hold off;
end

stop(vid); % Stop the video aquisition
delete(vid); % Delete the video input object
clear vid; % Clear the variable
