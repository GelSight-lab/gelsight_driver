% This program reads the raw GelSight video, and write a new video with the
% gradiant map and frame number. The defalt initialization frame is the
% first frame in the video.

% Create by Wenzhen Yuan. Jan 2016

name1='1';
name2='_s1';

aviObject = VideoWriter([name1 name2 '_RawOut'], 'MPEG-4');%'Uncompressed AVI');
aviObject.FrameRate = 23;
avrobj=VideoReader([name1 name2 '.mp4']);
f=read(avrobj);
Frn=size(f,4);

%%
thresh=30;
kscale=50;
kernnel=fspecial('gaussian',[kscale*2 kscale*2],kscale*1);
frame0_=double(f(:,:,:,1));
clear f0;
f0(:,:,1)=conv2(frame0_(:,:,1),kernnel,'same');
f0(:,:,2)=conv2(frame0_(:,:,2),kernnel,'same');
f0(:,:,3)=conv2(frame0_(:,:,3),kernnel,'same');

%%
open(aviObject);
resIm=uint8(zeros(size(f,1), size(f,2)*2,3));
for i=1:Frn
    frame=f(:,:,:,i);
    I=f0-double(frame);
    dI=(-sum(I,3)+max(I,[],3))/2;
    dI(dI<0)=0;
    dI=round(dI*8.5);dI(dI>255)=255;
    resIm(:,1:size(f,2),:)=frame;
    resIm(:,size(f,2)+1:end,1)=dI;
    resIm2=imresize(resIm,0.5);
    resIm2=insertText(resIm2,[size(f,2)/2-20 ,10],num2str(i), 'FontSize',30);
    
    writeVideo(aviObject, resIm2);
end
        close(aviObject);