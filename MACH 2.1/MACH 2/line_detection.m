% Read video file
videoFile = 'output_video.mp4'; % Provide the path to your video file
videoObj = VideoReader(videoFile);

% Preallocate cell array to store detected lines for each frame
detectedLines = cell(1, videoObj.NumFrames);

% Create a figure for displaying the video
figure;

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
    
    % Visualize detected lines on the frame
    for k = 1:length(lines)
        xy = [lines(k).point1; lines(k).point2];
        frame = insertShape(frame, 'Line', xy, 'Color', 'green', 'LineWidth', 2);
    end
    
    % Display the frame
    imshow(frame);
    title(['Frame ' num2str(i)]);
    
    % Pause to display each frame for a short duration
    pause(1/videoObj.FrameRate);
end
