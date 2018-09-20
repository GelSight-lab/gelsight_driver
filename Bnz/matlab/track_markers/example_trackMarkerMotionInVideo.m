% example: track markers in the video sequence
% Note: this is just an example of how to use the functions, and no real
% input is given. Please feed in the proper input in order to make the code
% work
% 
% By Wenzhen Yuan, Jan 2017

%% Input:
f;  % the read images from a video. should be 4 dimension; The first frame must be blank
frame_num=size(f,4); % number of frames in the video
border=0;   %pixel numbers that you want to crop from each frame

MarkerAreaThresh=30;  % modify this value if the marker areas are not well picked 

%% get the initial information on the first frame
f0 = iniFrame(f(:,:,:,1), border);  % the background of the image when markers are removed
frame0=f(border+1:end-border,border+1:end-border,:,1);
I=f0-double(frame0);
dI=(sum(I,3)-max(I,[],3))/2;
flowcenter=gray2center(dI, MarkerAreaThresh);  % initialize the center of the markers in the initialization frame
center_last=flowcenter;  % this is the marker center positions in the last frame

%% get the movement of the markers in each frame

for i=2:frame_num
    frame=f(border+1:end-border,border+1:end-border,:,i);
    I=f0-double(frame);
    dI=(sum(I,3)-max(I,[],3))/2;
    MarkerCenter=gray2center(dI, MarkerAreaThresh);  % get the center of the markers in the current frame
    % get the 2d motion of each marker on comparing the center of the
    % markers in the current frame, last frame, and the very first frame.
    % center_last (the marker motion in the last frame) is updated here
    [ut,vt, center_last, AreaChange]=cal_vol_oncenter2(flowcenter,center_last,MarkerCenter);    
    % The out put value ut and vt are 1d arrays, corresponding to the
    % x-direction motion and y-direction motion in the camera frame, in
    % pixel. The order of the array is the same, as the same order in 'flow
    %center'. when the motion of a marker is not found, ut and vt are both
    %0.
    MarkerMotion(i).u=ut;
    MarkerMotion(i).v=vt;
    % flowcenter is a nx3 array. n is the marker number. The first column
    % is the y coordinate of the marker center, 2nd column is the x
    % coordinate.
    MarkerMotion(i).flowcenter=round(flowcenter);    
    
    %% draw the arrow field of the markers
    showscale=18;
    figure;ha=axis;
    set(ha,'NextPlot','add');
    himage=imshow( frame/255, 'Parent', ha);
    hquiver=quiver(ha,MarkerMotion.flowcenter(:,2),MarkerMotion.flowcenter(:,1),...
    MarkerMotion.u'*showscale,MarkerMotion.v'*showscale,...
    'Color','y','LineWidth',2,'AutoScale','off');
end