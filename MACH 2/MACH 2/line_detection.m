% Read video file
videoFile = 'output_video.mp4'; % Provide the path to your video file
videoObj = VideoReader(videoFile);

% Preallocate cell array to store detected lines for each frame
detectedLines = cell(1, videoObj.NumFrames);

% Camera intrinsics
focalLength = [535.4, 539.2]; % in pixels
principalPoint = [320.1, 247.6]; % in pixels

% Loop through each frame
for i = 1:videoObj.NumFrames
    % Read the frame
    frame = readFrame(videoObj);
    
    % Convert the frame to grayscale
    grayFrame = rgb2gray(frame);
    
    % Perform edge detection (you can use different methods here based on your preference)
    edgeFrame = edge(grayFrame, 'Canny');
    
    % Perform Hough Transform to detect lines
    [H,theta,rho] = hough(edgeFrame);
    P = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
    lines = houghlines(edgeFrame,theta,rho,P,'FillGap',5,'MinLength',7);
    
    % Store detected lines for this frame
    detectedLines{i} = lines;
    
    % Loop through each detected line
    for k = 1:length(lines)
        % Get the endpoints of the line in image coordinates
        point1 = lines(k).point1;
        point2 = lines(k).point2;
        
        % Compute the depth of the line (assuming the line is perpendicular to the image plane)
        depth = mean(focalLength) * mean(lines(k).rho) / norm(point1 - point2);
        
        % Mark the points where the depth is calculated with an 'x'
        frame = insertMarker(frame, [(point1(1) + point2(1)) / 2, (point1(2) + point2(2)) / 2], 'x', 'Color', 'red');
        
        % Visualize the depth on the frame
        textPosition = [(point1(1) + point2(1)) / 2, (point1(2) + point2(2)) / 2];
        frame = insertText(frame, textPosition, ['Depth: ' num2str(depth)], 'FontSize', 10, 'BoxColor', 'red', 'BoxOpacity', 0.4, 'TextColor', 'white');
    end
    
    % Display the frame
    imshow(frame);
    title(['Frame ' num2str(i)]);
    
    % Pause to display each frame for a short duration
    pause(1/videoObj.FrameRate);
end
