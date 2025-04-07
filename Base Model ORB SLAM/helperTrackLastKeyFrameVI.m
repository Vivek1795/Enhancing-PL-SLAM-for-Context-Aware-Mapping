%helperTrackLastKeyFrame Estimate the camera pose by tracking the last key frame
%   [currPose, mapPointIdx, featureIdx] = helperTrackLastKeyFrameStereo(mapPoints, 
%   views, currFeatures, currPoints, lastKeyFrameId, intrinsics, scaleFactor) estimates
%   the camera pose of the current frame by matching features with the
%   previous key frame.
%
%   This is an example helper function that is subject to change or removal 
%   in future releases.
%
%   Inputs
%   ------
%   mapPoints         - A helperMapPoints objects storing map points
%   views             - View attributes of key frames
%   currFeatures      - Features in the current frame 
%   currPoints        - Feature points in the current frame                 
%   lastKeyFrameId    - ViewId of the last key frame 
%   intrinsics        - Camera intrinsics 
%   scaleFactor       - scale factor of features
%   
%   Outputs
%   -------
%   currPose          - Estimated camera pose of the current frame
%   mapPointIdx       - Indices of map points observed in the current frame
%   featureIdx        - Indices of features corresponding to mapPointIdx

%   Copyright 2019-2022 The MathWorks, Inc.

function [currPose, mapPointIdx, featureIdx] = helperTrackLastKeyFrameVI(...
    mapPoints, views, currFeatures, currPoints, lastKeyFrameId, intrinsics, scaleFactor)

K = intrinsics.K;
camInfo = ((K(1,1)/1.5)^2)*eye(2);


% Match features from the previous key frame with known world locations
[index3d, index2d]    = findWorldPointsInView(mapPoints, lastKeyFrameId);
lastKeyFrameFeatures  = views.Features{lastKeyFrameId}(index2d,:);
lastKeyFramePoints    = views.Points{lastKeyFrameId}(index2d);

lastKeyFramePose      = views.AbsolutePose(lastKeyFrameId);

indexPairs  = matchFeatures(currFeatures, binaryFeatures(lastKeyFrameFeatures));

% Estimate the camera pose
matchedPrevImagePoints = lastKeyFramePoints(indexPairs(:,2),:);
matchedImagePoints = currPoints.Location(indexPairs(:,1),:);
matchedWorldPoints = mapPoints.WorldPoints(index3d(indexPairs(:,2)), :);

matchedImagePoints = cast(matchedImagePoints, 'like', matchedWorldPoints);
[currPose, inlier, status] = estworldpose(...
    matchedImagePoints, matchedWorldPoints, intrinsics, ...
    'Confidence', 95, 'MaxReprojectionError', 3, 'MaxNumTrials', 1e4);

if status
    currPose=[];
    mapPointIdx=[];
    featureIdx=[];
    return
end

%%%%%%%%%%%%%%%%%%%%% FG OPTIMIZATION 1 %%%%%%%%%%%%%%%%%%%%%%%

f = factorGraph();

currMatchedImagePoints = matchedImagePoints(inlier,:);
matchedWorldPoints = matchedWorldPoints(inlier,:);

poseID  = generateNodeID(f,1);
ptsIDs  = generateNodeID(f,numel(matchedWorldPoints(:,1)));

currCamIds = ones(1,numel(currMatchedImagePoints(:,2)))*poseID;
currIDS    = [currCamIds;ptsIDs]';

fCam = factorCameraSE3AndPointXYZ(currIDS, K, Information=camInfo, ...
    Measurement=currMatchedImagePoints);
f.addFactor(fCam);

fgCurrPose = double([currPose.Translation rotm2quat(currPose.R)]);

f.nodeState(poseID,fgCurrPose);
f.nodeState(ptsIDs,double(matchedWorldPoints));

f.fixNode(ptsIDs);

opts = factorGraphSolverOptions;
% opts.MaxIterations = 20;
% opts.VerbosityLevel = 0;
% opts.FunctionTolerance  = 1e-5;
% opts.GradientTolerance = 1e-5;
% opts.StepTolerance = 1e-10;
% optd.TrustRegionStrategyType = 0;

% run factor graph optimization
optimize(f,opts);

fgposopt = nodeState(f,poseID);
currPose = rigidtform3d(quat2rotm(fgposopt(4:7)),fgposopt(1:3));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Search for more matches with the map points in the previous key frame
xyzPoints = mapPoints.WorldPoints(index3d,:);

[projectedPoints, isInImage] = world2img(xyzPoints, pose2extr(currPose), intrinsics);
projectedPoints = projectedPoints(isInImage, :);

minScales    = max(1, lastKeyFramePoints.Scale(isInImage)/scaleFactor);
maxScales    = lastKeyFramePoints.Scale(isInImage)*scaleFactor;
r            = 4;
searchRadius = r*lastKeyFramePoints.Scale(isInImage);

indexPairs   = matchFeaturesInRadius(binaryFeatures(lastKeyFrameFeatures(isInImage,:)), ...
    binaryFeatures(currFeatures.Features), currPoints, projectedPoints, searchRadius, ...
    'MatchThreshold', 40, 'MaxRatio', 0.8, 'Unique', true);

if size(indexPairs, 1) < 20
    indexPairs   = matchFeaturesInRadius(binaryFeatures(lastKeyFrameFeatures(isInImage,:)), ...
        binaryFeatures(currFeatures.Features), currPoints, projectedPoints, 2*searchRadius, ...
        'MatchThreshold', 40, 'MaxRatio', 1, 'Unique', true);
end

if size(indexPairs, 1) < 10
    currPose=[];
    mapPointIdx=[];
    featureIdx=[];
    return
end

prevPoints=lastKeyFramePoints(isInImage,:);

% Filter by scales
isGoodScale = currPoints.Scale(indexPairs(:, 2)) >= minScales(indexPairs(:, 1)) & ...
    currPoints.Scale(indexPairs(:, 2)) <= maxScales(indexPairs(:, 1));
indexPairs  = indexPairs(isGoodScale, :);

% Obtain the index of matched map points and features
tempIdx            = find(isInImage); % Convert to linear index
mapPointIdx        = index3d(tempIdx(indexPairs(:,1)));
featureIdx         = indexPairs(:,2);
featurePrevIdx     = indexPairs(:,1);

% Refine the camera pose again
matchedWorldPoints = mapPoints.WorldPoints(mapPointIdx, :);
matchedImagePoints = currPoints.Location(featureIdx, :);


%%%%%%%%%%%%%%%%%%%%%% FG OPTIMIZATION 2 %%%%%%%%%%%%%%%%%%%%%%%

f = factorGraph();

poseID = generateNodeID(f,1);
ptsIDs  = generateNodeID(f,numel(matchedWorldPoints(:,1)));

currCamIds = ones(1,numel(matchedImagePoints(:,2)))*poseID;
currIDS    = [currCamIds;ptsIDs]';

fCam = factorCameraSE3AndPointXYZ(currIDS, K, Information=camInfo, ...
    Measurement=matchedImagePoints);
f.addFactor(fCam);

fgCurrPose = double([currPose.Translation rotm2quat(currPose.R)]);

f.nodeState(poseID,fgCurrPose);
f.nodeState(ptsIDs,double(matchedWorldPoints));

f.fixNode(ptsIDs);

opts = factorGraphSolverOptions;

% run factor graph optimization
optimize(f,opts);

fgposopt = nodeState(f,poseID);
currPose = rigidtform3d(quat2rotm(fgposopt(4:7)),fgposopt(1:3));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



end