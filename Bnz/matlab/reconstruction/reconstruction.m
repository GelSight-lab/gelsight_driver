clear LookupTable;

addpath(genpath('functions'));

Inputfolder='./cali_180110/';
lookupfile=[Inputfolder 'UR5_sensor1_180110.mat'];
framename=[Inputfolder 'Im_235_1336917.jpg'];

border=30;

load(lookupfile);
[Inputfolder 'frame0.jpg']
frame0=imread([Inputfolder 'frame0.jpg']);
f0 = iniFrame(frame0, border);
frame=imread(framename);

frame_=frame(border+1:end-border,border+1:end-border,:);
I=double(frame_)-f0;

[ImGradX, ImGradY, ImGradMag, ImGradDir]=matchGrad_Bnz(LookupTable, I, f0);
hm=fast_poisson2(ImGradX, ImGradY);

figure,subplot(1,2,1);imshow(frame_);
subplot(1,2,2);imagesc(hm);axis equal