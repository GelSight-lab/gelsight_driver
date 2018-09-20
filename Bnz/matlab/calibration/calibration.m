
% Generate lookup table from images in a single folder
% To make the calibration video: press a sphere onto the GelSight sensor
% surface, roll it on different positions. Maker sure the 1st frame (or at
% least one frame) is blank with nothing contacting the Gel
% Pick up one or more frames in the videos to calibrate the sensor
% Modify the Ball's radius and the sensor's display ratio for each test
%
% Mod by Wenzhen Yuan (yuanwenzhen@gmail.com), Jan 2018

clear;close all;
BallRad=3.96/2;% Ball's radius, in mm   
border=30;
BALL_MANUAL=1;      % whether to find the ball manually

type='new';  % choose whether it's the new sensor or the old one
name1=['UR5_sensor1_180110'];
Inputfolder='./cali_180110/';
savename=[name1 '.mat'];

addpath(genpath('functions'));
%% generate lookup table 
READ_RADIUS=0;

bins=80;
gradmag=[];gradir=[];countmap=[];
if strcmp(type,'new')
    Pixmm=0.03026;   % 640*480, on ROS platform
    zeropoint=-90;
    lookscale=180;
elseif strcmp(type,'old')
    zeropoint=-1e-3;
    lookscale=5e-3;
    Pixmm=0.0254;
end
BallRad_pix=BallRad/Pixmm;
             
%%

% read Ini Image
frame0=imread([Inputfolder 'frame0.jpg']);
f0 = iniFrame(frame0, border);
% list of calibration images
ImList=dir([Inputfolder 'Im_*']);

for Frn=1:length(ImList)
    frame=imread([Inputfolder ImList(Frn).name]);
    display(['Calibration on Frame' num2str(Frn)]);
    frame_=frame(border+1:end-border,border+1:end-border,:);
    I=double(frame_)-f0;    
    dI=(min(I,[],3)-max(I,[],3))/2;
    
    [ContactMask, validMask, touchCenter, Radius]= FindBallArea_coarse(dI,frame_,BALL_MANUAL);
    validMask=validMask & ContactMask;
    
    nomarkermask=min(-I,[],3)<30;   % for new sensor
    nomarkermask=imerode(nomarkermask,strel('disk',3)); 
    validMask=validMask & nomarkermask;      
    [gradmag, gradir,countmap]=LookuptableFromBall_Bnz(I,f0, bins , touchCenter, BallRad, Pixmm, validMask, gradmag, gradir, countmap, zeropoint, lookscale);
end


[GradMag, GradDir]=LookuptableSmooth(bins, gradmag, gradir, countmap);
LookupTable.bins=bins;
LookupTable.GradMag=GradMag;
LookupTable.GradDir=GradDir
LookupTable.GradX=-cos(GradDir).*GradMag;
LookupTable.GradY=sin(GradDir).*GradMag;;
LookupTable.Zeropoint=zeropoint;
LookupTable.Scale=lookscale;
LookupTable.Pixmm=Pixmm;
LookupTable.FrameSize=size(frame);
save([Inputfolder savename],'LookupTable');    %Save the loopup table file
display('Calibration Done');
