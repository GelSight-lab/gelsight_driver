function showMarkerImage(f_0, frame)
% display the image with marker vectors
% input is the uncropped initial frame, and frmae is the cropped current frame

thresh=30;
border=50;

MarkerAreaThresh=15;
MarkerAreaThresh2=30;
f0=iniFrame(f_0, border);
size1=size(f0,1);size2=size(f0,2);

frame_=f_0(border+1:end-border,border+1:end-border,:);
I=f0-double(frame_);
% I=mean(f0-I,3);
dI=(sum(I,3)-max(I,[],3))/2;
flowcenter=gray2center(dI, MarkerAreaThresh2);
center_last=flowcenter;

I=f0-frame;
BrightIm=(sum(I,3)-max(I,[],3))/2;

% Get marker motions
MarkerCenter=gray2center(BrightIm, MarkerAreaThresh2);
[ut,vt, center_last, AreaChange]=cal_vol_oncenter2(flowcenter,center_last,MarkerCenter);
MarkerMotion.u=ut;
MarkerMotion.v=vt;
MarkerMotion.flowcenter=round(flowcenter);

figure;
ha=axes;
displayMarkerandFrame(ha, frame, MarkerMotion)

% figure,imshow(frame/255);hold on
% id=find(AreaChange>0);
% scatter(center_last(id,2),center_last(id,1),(AreaChange(id)')*10,'LineWidth',4)
% id=find(AreaChange<0);
% scatter(center_last(id,2),center_last(id,1),(-AreaChange(id)')*10,'LineWidth',4)
% i=0;
