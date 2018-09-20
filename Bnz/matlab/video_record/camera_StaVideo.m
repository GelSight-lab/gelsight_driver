% One camera, has the function of recording the dynamic video and record
% the static images

% output: frame0; frame1 (series); frametime (static time); videotime: time
% sequence for the record time
% Attention: It takes some time to write down the video after each
% recording, and during the delay it is not able to record the static
% frames.
% 
% frame0 is the background frame after refresh; in int8
% frame1 is a serie of the frames saved during the experiment, (in int8) and
% frametime records the time of the frame recorded. 
%
% Modified 07202014

close all
clear

imaqreset;
% vid = videoinput('winvideo', 1, 'RGB24_960x720');
vid = videoinput('macvideo', 2, 'YCbCr422_1280x960');

atobj=getselectedsource(vid);
vid.FramesPerTrigger = 1;
vid.TriggerRepeat = Inf;
% set(atobj,'Exposure',-1);
vidRes = get(vid, 'VideoResolution');
vtn1=0;
vid.TriggerFcn = 'vtn1=vtn1+1;vtime1(vtn1)=datenum(clock);';



%% Initialization for video rec

writename1='Rec';
writename2='_1';
wrn3=1;

video_on=0;
video_framenum=0;   % write every video_framenum+1 frames
% video_i=0;
% video_t=0;
% video_timeseq=[];
frame1=[];
videotime=[];
frametime=[];

%% 
t=0;

hf = figure('Position',[100,300,1000,800],... 
    'Units', 'Normalized', 'Menubar', 'None',...
    'NumberTitle', 'off', 'Name', 'Show The Imaging System');
ha2=axes('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.52 .6 .45 .35]);
axis off
ha = axes('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.02 .6 .45 .35]);
axis off

ha3=axes('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.02 .15 .45 .35]);
axis off

ha4=axes('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.52 .15 .45 .35]);
axis off

%%
hb_exit= uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.11 .94 .08 .04], 'String', 'Exit', ...
    'Callback',['close(hf);work_on=0;']);
hb_save = uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.1 .05 .15 .05], 'String', 'Start Rec', ...
    'Callback', 'video_on=3;');
hb_stop =  uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.3 .05 .15 .05], 'String', 'Stop Rec', ...
    'Callback','vt2=datenum(clock);video_on=2;stop(vid);');
hb_frame1 = uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.5 .05 .15 .05], 'String', ['Save frame' num2str(t+1)], ...
    'Callback', 't=t+1;frame1{t}=getsnapshot(vid); frametime(t)=datenum(clock);set(hb_frame1,''String'',[''Save frame'' num2str(t+1)]);');

hb_refresh = uicontrol('Parent', hf, 'Units', 'Normalized', ...
    'Position', [.7 .05 .15 .05], 'String', 'Renew Background', ...
    'Callback', 'frame0=getsnapshot(vid);imshow(frame0,''Parent'',ha2);');

% frame0=step(frobj);
pause(1);
work_on=1;

hImage1 = image(zeros(vidRes(2),vidRes(1), 3),'Parent',ha);
preview(vid,hImage1);
frame0=getsnapshot(vid);imshow(frame0,'Parent',ha2);

while work_on && ishandle(hf)

%     imshow(frame0,'Parent',ha2);
%     imshow(frame-frame0+0.5,'Parent',ha4);
     
%     if t>0
%         imshow(frame1{t},'Parent',ha3);
%     end
%     
    %% vedio record part
    if video_on ==3 % Start recording
        video_on=1;
%         aviObject = VideoWriter([writename1 writename2 '_' num2str(wrn3)], 'MPEG-4');
        aviObject = VideoWriter([writename1 writename2], 'MPEG-4');
        aviObject.FrameRate = 25;        
        set(hb_save,'String','Recing');
        start(vid);     
    elseif video_on == 2
        set(hb_stop,'String','Stopped');
        video_on = 0;
          
        open(aviObject);
        data = getdata(vid, vid.FramesAvailable);
        numFrames1 = size(data, 4);
        for ii = 1:numFrames1
            writeVideo(aviObject, data(:,:,:,ii));
        end
        close(aviObject);
        clear data;
        
        videotime{wrn3}=vtime1;
        vtn1=0;vtime1=[];
        wrn3=wrn3+1;
        
        set(hb_save,'String',['Start Rec ' num2str(wrn3)]);
        set(hb_stop,'String','Stop Rec');
     
    end
       
    pause(0.005);
   
end

StaticFrmNum=t;
VideoNum=wrn3-1;
save([writename1 writename2], 'videotime', 'frame1','frametime','StaticFrmNum','VideoNum','writename1', 'writename2');
delete(vid);




