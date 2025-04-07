% Open the video file
videoFile = VideoReader('output_video.mp4');
focalLength    = [535.4, 539.2];    % in units of pixels
principalPoint = [320.1, 247.6];    % in units of pixels
imageSize      = [videoFile.Height, videoFile.Width];  % Get image size from video file

% Create stereo parameters object
intrinsics = cameraIntrinsics(focalLength, principalPoint, imageSize);
stereoParams = stereoParameters(intrinsics, intrinsics, rigid3d);

% Create a VideoWriter object to save the depth map
outputVideo = VideoWriter('depth_map.avi');
open(outputVideo);

% Process each frame of the video
while hasFrame(videoFile)
    % Read the frame
    frame = readFrame(videoFile);
    
    % Convert the frame to grayscale
    grayFrame = rgb2gray(frame);
    
    % Rectify the frame (assuming stereo rectification has been done)
    rectifiedFrame = undistortImage(grayFrame, stereoParams.CameraParameters1);
    
    % Perform block matching for stereo disparity estimation
    disparityRange = [-16 16]; % Range of disparities to search for
    disparityMap = disparityBM(rectifiedFrame, rectifiedFrame, 'DisparityRange', disparityRange, 'UniquenessThreshold', 15);
    
    % Calculate depth map from disparity map
    baseline = 0.1; % Example baseline in meters
    focalLength = 535.4; % Assuming the focal length is the same for both cameras
    depthMap = (baseline * focalLength) ./ disparityMap;
    
    % Write the depth map frame to the output video
    writeVideo(outputVideo, mat2gray(depthMap));
end

% Close the output video file
close(outputVideo);
