function varargout = capture(varargin)
% CAPTURE MATLAB code for capture.fig
%      CAPTURE, by itself, creates a new CAPTURE or raises the existing
%      singleton*.
%
%      H = CAPTURE returns the handle to a new CAPTURE or the handle to
%      the existing singleton*.
%
%      CAPTURE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CAPTURE.M with the given input arguments.
%
%      CAPTURE('Property','Value',...) creates a new CAPTURE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before capture_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to capture_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help capture

% Last Modified by GUIDE v2.5 22-Jul-2016 16:28:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @capture_OpeningFcn, ...
                   'gui_OutputFcn',  @capture_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before capture is made visible.
function capture_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to capture (see VARARGIN)

% Configure Axes preview
axes(handles.preview);
imaqreset;
vid = videoinput('winvideo', 1, 'RGB24_960x720');
atobj = getselectedsource(vid);
set(vid, 'FramesPerTrigger', 1);
set(vid, 'TriggerRepeat', Inf);
set(atobj,'Exposure',-3);


userdata.vid = vid;
set(hObject, 'UserData', userdata);

vidRes = vid.VideoResolution;
nBands = vid.NumberOfBands;
hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
preview(vid, hImage);

set(handles.eDir, 'String', [pwd '/data']);
set(handles.eAnn, 'String', fullfile(pwd, 'annotation', 'annotation.mat'));


fprintf('Hello\n');
% Choose default command line output for capture
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes capture wait for user response (see UIRESUME)
% uiwait(handles.capture);


% --- Outputs from this function are returned to the command line.
function varargout = capture_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close capture.
function capture_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to capture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.start, 'UserData');
userdata.stop = true;
set(handles.start, 'UserData', userdata);
cla(handles.intensity);
set(handles.tStatus, 'String', 'Idle');
set(handles.start, 'Visible', 'on');
set(hObject, 'Visible', 'off');
userdata = get(hObject, 'UserData');
if isfield(userdata, 'vid')
    stop(userdata.vid);
end
fprintf('Bye\n');
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Open annotation file.

set(handles.start, 'Enable', 'off');
pause(0.01);
stage = 0;
thre_mul1 = 3;
thre_mul2 = 0.5;
buffer_size = 15;
maxd = [];
init = [];
userdata = get(hObject, 'UserData');
userdata.stop = false;
annfile = get(handles.eAnn, 'String');
if isempty(annfile)
    msgbox('No annotation file selected.');
    return;
end

if exist(annfile, 'file')

    [~,~,ext] = fileparts(annfile);
    if strcmp(ext, '.json')
        annotation = loadjson(fileread(annfile));        
        annotation = annotation.annotation;
        annotation.video = cell2mat(annotation.video);
        annotation.image = cell2mat(annotation.image);
    elseif strcmp(ext, '.mat')
        annotation = load(annfile);
        annotation = annotation.annotation;
    else
        msgbox('Annotation format not supported.');
        return;
    end
else
    annotation = [];
end
if ~isfield(annotation, 'video')
    annotation.video = [];
end
if ~isfield(annotation, 'image')
    annotation.image = [];
end
userdata.annotation = annotation;



set(handles.start, 'UserData', userdata);

set(handles.tStatus, 'String', 'Ready');

capture = get(handles.capture, 'UserData');

vid = capture.vid;
frames = [];
times = [];
f_0 = [];
avg_num = 2;
for i = 1:avg_num
    if isempty(f_0)
        f_0 = getsnapshot(vid) / avg_num;
    else
        f_0 = f_0 + getsnapshot(vid) / avg_num;
    end
end
start(vid);
set(hObject, 'Visible', 'off');
set(handles.terminate, 'Visible', 'on');
set(handles.terminate, 'Enable', 'on');
while true
    while ~vid.FramesAvailable
    end
    [f, time] = getdata(vid, get(vid, 'FramesAvailable'));
    fend = f(:,:,:,end);
    pause(0.01);
    userdata = get(handles.start, 'UserData');
    if userdata.stop
        stop(vid);
        break;
    end
    del_pic = abs(fend(:) - f_0(:));
    del_pic(del_pic < 10) = 0;
    delta = sum(del_pic);
    aligned_delta = repmat(delta, size(time));
    if isempty(frames)
        frames = f;
        times = time;
        deltas = aligned_delta;
    elseif stage == 0
        frames = cat(4, frames(:,:,:,max(end-buffer_size, 1):end), f);
        times = [times(max(end-buffer_size, 1):end); time];
        deltas = [deltas(max(end-buffer_size, 1):end); aligned_delta];
    else
        frames = cat(4, frames, f);
        times = [times; time];
        deltas = [deltas; aligned_delta];
    end


    inten = delta / 5e7;
    axes(handles.intensity);
    fill([0, 0, 1, 1], [0, inten, inten, 0], ...
        'r', 'FaceAlpha', 0.5, 'EdgeAlpha', 0);
    xlim([0, 1]);
    ylim([0, 1]);
    box off
    set(gca, 'XTick', []);
    set(gca, 'YTickLabel', [])
    
    if isempty(init)
        init = delta;
    end
    if isempty(maxd)
        maxd = delta;
    end
    if delta > maxd
        maxd = delta;
    end
    
    if stage == 0 
        if delta > max(init * max(thre_mul1, 2), 1e6);
            stage = 1;
            start_time = time(end);
            ind_edge = length(times);
            set(handles.tStatus, 'String', 'Recording');
        end
    end
    if stage == 1
        if  delta < maxd * thre_mul2
            set(handles.tStatus, 'String', 'Processing');
            thre_mul1 = maxd / init / 8;
            pause(0.01);
            
            % Fetch save configurations
            folder = get(handles.eDir, 'String');
            prefix = get(handles.ePrefix, 'String');
            writeImages = get(handles.cWriteImage, 'Value');
            framerate = mean(1./diff(times));
%             disp(framerate);
            
            % Save single press
            [~, xmax] = max(deltas);
            ann.start = ind_edge;
            ann.end = xmax;
            ann.hardness = get(handles.hardness, 'String');
%             ann.hardness = ann.hardness{1};
            ann.shape = get(handles.shape, 'String');
%             ann.shape = ann.shape{1};
            ann.radius = get(handles.radius, 'String');
%             ann.radius = ann.radius{1};
            [log, anns] = savePress(frames, framerate, folder, prefix, writeImages, ann);
            anns.video.split5=[];
            
            % Write annotations
            userdata = get(hObject, 'UserData');
            annotation = userdata.annotation;
            annotation.video = [annotation.video, anns.video];
            annotation.image = [annotation.image, anns.image];
            userdata.annotation = annotation;
            set(hObject, 'UserData', userdata);
            
            % Print log
            set(handles.eLog, 'String', log.string);
            
            % Snapshot press
            set(handles.bDiscard, 'UserData', log);
            set(handles.bDiscard, 'Enable', 'on');
            
            % Use trigger time as zero
            times = times - start_time;
            
            % Draw the plot.
            axes(handles.press);
            cla(handles.press);
            hold on
            plot(times, deltas);
            yrange = ylim;
            ymin = yrange(1);
            ymax = yrange(2);
            xlim([times(1) times(end)]); 
            fill([times(ind_edge), times(ind_edge), ...
                times(xmax), times(xmax)], [ymin, ymax, ymax, ymin], ...
                'r', 'FaceAlpha', 0.2, 'EdgeAlpha', 0);
            
            % Wait for recover
            set(handles.tStatus, 'String', 'Recovering');
            stage = 2;
        end
    end
    
    if stage == 2
       if delta < init * thre_mul1
            set(handles.tStatus, 'String', 'Ready');
            stage = 0;
            maxd = 0;
            f_0 = frames(:,:,:,1);
            frames = [];
            times = [];
            deltas = [];
            flushdata(vid);
            clear trend;
    %    else 
     %       display('Fail to recover')
       end
    end
    % pause(0.01);

end

userdata = get(hObject, 'UserData');
annotation = userdata.annotation;
if strcmp(ext, '.json')
    fid = fopen(annfile, 'wt');
    fwrite(fid, savejson(annotation));
    fclose(fid);
else
    save(annfile, 'annotation');
end
set(handles.tStatus, 'String', 'Idle');
set(hObject, 'Visible', 'on');
set(handles.terminate, 'Visible', 'off');
set(handles.start, 'Enable', 'on');


% --- Executes on button press in terminate.
function terminate_Callback(hObject, eventdata, handles)
% hObject    handle to terminate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
userdata = get(handles.start, 'UserData');
userdata.stop = true;
set(handles.start, 'UserData', userdata);
cla(handles.intensity);
set(handles.terminate, 'Enable', 'off');
set(handles.start, 'Enable', 'on');
set(handles.bDiscard, 'Enable', 'off');
pause(0.01);
% set(handles.tStatus, 'String', 'Idle');
% set(handles.start, 'Visible', 'on');
% set(hObject, 'Visible', 'off');
% end





function eDir_Callback(hObject, eventdata, handles)
% hObject    handle to eDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eDir as text
%        str2double(get(hObject,'String')) returns contents of eDir as a double


% --- Executes during object creation, after setting all properties.
function eDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bDir.
function bDir_Callback(hObject, eventdata, handles)
% hObject    handle to bDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
path = uigetdir;
if path
    set(handles.eDir, 'String', path);
    if ~exist([path '\video'])
        mkdir([path '\video']);
    end
    if ~exist([path '\image'])
        mkdir([path '\image']);
    end
    set(handles.eAnn, 'String', fullfile(path, 'annotation.mat'));
%     if ~exist([path '\image'])
    annofile=get(handles.eAnn, 'String');
    if ~exist(annofile)
        clear annotation
        annotation.video=[];
        annotation.image=[];
        save(annofile, 'annotation');
    end             
end


function hardness_Callback(hObject, eventdata, handles)
% hObject    handle to hardness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hardness as text
%        str2double(get(hObject,'String')) returns contents of hardness as a double


% --- Executes during object creation, after setting all properties.
function hardness_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hardness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function radius_Callback(hObject, eventdata, handles)
% hObject    handle to radius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of radius as text
%        str2double(get(hObject,'String')) returns contents of radius as a double


% --- Executes during object creation, after setting all properties.
function radius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eAnn_Callback(hObject, eventdata, handles)
% hObject    handle to eAnn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eAnn as text
%        str2double(get(hObject,'String')) returns contents of eAnn as a double


% --- Executes during object creation, after setting all properties.
function eAnn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eAnn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bAnn.
function bAnn_Callback(hObject, eventdata, handles)
% hObject    handle to bAnn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[name, path] = uigetfile({'*.json'; '*.mat'});
if path
    set(handles.eAnn, 'String', [path, name]);
end


function ePrefix_Callback(hObject, eventdata, handles)
% hObject    handle to ePrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ePrefix as text
%        str2double(get(hObject,'String')) returns contents of ePrefix as a double


% --- Executes during object creation, after setting all properties.
function ePrefix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ePrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function shape_Callback(hObject, eventdata, handles)
% hObject    handle to shape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of shape as text
%        str2double(get(hObject,'String')) returns contents of shape as a double


% --- Executes during object creation, after setting all properties.
function shape_CreateFcn(hObject, eventdata, handles)
% hObject    handle to shape (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cWriteImage.
function cWriteImage_Callback(hObject, eventdata, handles)
% hObject    handle to cWriteImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cWriteImage



function eLog_Callback(hObject, eventdata, handles)
% hObject    handle to eLog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of eLog as text
%        str2double(get(hObject,'String')) returns contents of eLog as a double


% --- Executes during object creation, after setting all properties.
function eLog_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eLog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bDiscard.
function bDiscard_Callback(hObject, eventdata, handles)
% hObject    handle to bDiscard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'Enable', 'off');
log = get(hObject, 'UserData');
if ~isempty(log)
    for i = 1:length(log.files)
        delete(log.files{i});
    end
    u = get(handles.start, 'UserData');
    u.annotation.video(end) = [];
    u.annotation.image(end-log.num_images+1:end) = [];
    if isempty(u.annotation.video)
        u.annotation.video = [];
    end
    if isempty(u.annotation.image)
        u.annotation.image = [];
    end
    set(handles.start, 'UserData', u);
end
