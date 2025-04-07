% Read video file
videoFile = 'output_video.mp4'; % Provide the path to your video file
videoObj = VideoReader(videoFile);

% Preallocate cell array to store detected lines for each frame
detectedLines = cell(1, videoObj.NumFrames);

% Preallocate arrays to store x, y, and z coordinates for each point
xyzPoints = [];

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
        
        % Calculate x, y, and z coordinates
        x = (point1(1) + point2(1)) / 2;
        y = (point1(2) + point2(2)) / 2;
        z = depth; % Assuming depth is the z-coordinate
        
        % Store the x, y, and z coordinates in the xyzPoints array
        xyzPoints = [xyzPoints; x, y, z];
    end
end

% Create a pointCloud object
ptCloud = pointCloud(xyzPoints);

% Use filtering or other processing techniques on ptCloud to generate a correct map

% Display the point cloud
pcshow(ptCloud);
