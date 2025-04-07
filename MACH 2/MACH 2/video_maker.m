% Specify the directory containing the frames
framesDir = 'C:\Users\vivek\OneDrive - Arizona State University\documents\MS\Semester 2\Perception\Project\rgbd_dataset_freiburg3_long_office_household\depth'; % Provide the path to the directory containing the frames

% Get a list of all image files in the directory
imageFiles = dir(fullfile(framesDir, '*.png')); % Change '*.png' to the appropriate file extension if necessary

% Create a VideoWriter object to save the frames as a video
outputVideoFile = 'RGBD_video_depth.mp4'; % Provide the desired name for the output video file
outputVideo = VideoWriter(outputVideoFile);
open(outputVideo);

% Loop through each image file and add it to the video
for i = 1:numel(imageFiles)
    % Read the image
    frame = imread(fullfile(framesDir, imageFiles(i).name));
    frame = uint8(frame * 255); % Assuming frame values are in the range [0, 1]
% writeVideo(outputVideo, frame);
    % Write the frame to the output video
    writeVideo(outputVideo, frame);
end

% Close the VideoWriter object
close(outputVideo);
