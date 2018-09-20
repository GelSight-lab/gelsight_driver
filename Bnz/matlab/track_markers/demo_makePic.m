% make picture
vid=VideoReader('video.avi');
border=0;
MarkerAreaThresh=30; 
path='./out/';

%%
frame0_=readFrame(vid);
f0 = iniFrame(frame0_, border); 
frame0=double(frame0_(border+1:end-border,border+1:end-border,:));
I=f0-frame0;
dI0=(sum(I,3)-max(I,[],3))/2;
flowcenter=gray2center(dI0, MarkerAreaThresh);  % initialize the center of the markers in the initialization frame
center_last=flowcenter;  % this is the marker center positions in the last frame

imwrite(frame0/255,[path 'frame0.png']);
imwrite(f0/255,[path 'f0.png']);


%%
frameNum=vid.Duration*vid.FrameRate; %48
ReadFrmNum=25;
set(vid,'CurrentTime',ReadFrmNum/vid.FrameRate);
frame_=readFrame(vid);
frame=double(frame_(border+1:end-border,border+1:end-border,:));
I=f0-frame;
dI=(sum(I,3)-max(I,[],3))/2;
MarkerCenter=gray2center(dI, MarkerAreaThresh);

I2=-I+125;
imwrite(frame/255,[path 'frame.png']);
imwrite(I2/255,[path 'dI.png']);

%%
MarkerMask=dI>MarkerAreaThresh;
flowcenter=gray2center(dI, MarkerAreaThresh);
MarkerIm(:,:,1)=uint8(MarkerMask)*255;
MarkerIm(:,:,2)=uint8(MarkerMask)*255;
MarkerIm(:,:,3)=uint8(MarkerMask)*255;
for i=1:length(flowcenter)
    y=flowcenter(i,1);x=flowcenter(i,2);
    MarkerIm(y-2:y+2,x-2:x+2,2:3)=0;
end
figure,imshow(MarkerIm);
imwrite(MarkerIm,[path 'MarkerMask.png']);
