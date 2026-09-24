function varargout = UltraTimTrack(varargin)
% ULTRATIMTRACK M-file for UltraTimTrack.fig
%      ULTRATIMTRACK, by itself, creates a new ULTRATIMTRACK or raises the existing
%      singleton*.
%      H = ULTRATIMTRACK returns the handle to a new ULTRATIMTRACK or the handle to
%      the existing singleton*.
%
%      ULTRATIMTRACK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ULTRATIMTRACK.M with the given input arguments.
%
%      ULTRATIMTRACK('Property','Value',...) creates a new ULTRATIMTRACK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before UltraTimTrack_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to UltraTimTrack_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help UltraTimTrack

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @UltraTimTrack_OpeningFcn, ...
    'gui_OutputFcn',  @UltraTimTrack_OutputFcn, ...
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

% --- Executes just before UltraTimTrack is made visible.
function UltraTimTrack_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to UltraTimTrack (see VARARGIN)

% Check if Parallel Computing Toolbox is installed
% chkParallelToolBox(); %if exists it runs infinitely till Ultratimtrack is closed

% do some checking to make sure the required toolboxes are available
version = ver;

ava_tbs = cell(1,length(version));
for j = 1:length(version)
    ava_tbs{j} = version(j).Name;
end

req_tbs = {'Computer Vision Toolbox','Image Processing Toolbox', 'Parallel Computing Toolbox', 'Parallel Computing Toolbox'};
for j = 1:length(req_tbs)
    if ~sum(contains(ava_tbs,req_tbs{j}))
        warning(['This application requires the ', req_tbs{j}, ' to be installed. You may try to proceed without it, but parts of the algorithm may not work.'])
    end
end

% Choose default command line output for UltraTimTrack
handles.output = hObject;

%add automatically all files and subfolders dynamically
[program_directory, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath(program_directory));

% load some setting
load('TimTrack_parms.mat','parms')
load('ultrasound_tracking_settings.mat', 'ImageDepth', 'Position');

handles.UTT.TT.parms = parms;
handles.UTT.UT.BlockSize = [21 71]; %initialize it
handles.US.ID = ImageDepth;

set(handles.ImDepthEdit,'String',num2str(ImageDepth));
set(0,'RecursionLimit',3000)
set(gcf,'DoubleBuffer','on','Position',Position);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes UltraTimTrack wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function menu_load_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_load_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% First clean up some variables from any previously loaded files
rfields = {'movObj','BIm','Bheader','ImStack','Region','crop_rect'};

for j = 1:length(rfields)
    if isfield(handles, rfields{j})
        handles = rmfield(handles, rfields{j});
    end
end

%determine the available video formats
reader = 'VideoReader';
file_formats = eval([reader '.getFileFormats']);
format_list{1,1} = [];
format_list{1,2} = 'All Video Files (';
for i = 1:length(file_formats)
    format_list{1,1} = [format_list{1,1} '*.' file_formats(i).get.Extension ';'];
    format_list{1,2} = [format_list{1,2} file_formats(i).get.Description ', '];
    format_list{i+1,1} = ['*.' file_formats(i).get.Extension];
    format_list{i+1,2} = ['*.' file_formats(i).get.Extension ' - ' file_formats(i).get.Description];
end

format_list{1,2} = [format_list{1,2}(1:end-2) ')'];

newlist = strcat(format_list{1,1},'*.b32;*.b8;*.mat;*.jpg;*.png;*.bmp;*.jpeg;*.tiff');% add some options that we can use

%load the avi file
[handles.US.fname, handles.US.pname] = uigetfile(newlist, 'Pick a movie file');    
handles = load_video(hObject, eventdata, handles);

guidata(hObject, handles);
show_image(hObject,handles);



function[handles] = load_video(hObject, eventdata, handles)


if isequal(handles.US.fname,0) || isequal(handles.US.pname,0)
    return;
end

mb = waitbar(0,'Loading Video....');
cd (handles.US.pname)
[~,~,Ext]=fileparts([handles.US.pname handles.US.fname]);

if strcmp(Ext,'.b32')||strcmp(Ext,'.b8')
    
    [BIm,Bheader] = RPread([handles.US.pname handles.US.fname]); %read in the .b32 file
    
    handles.ImStack = fliplr(BIm / max(max(max(BIm))));
    handles.US.NumFrames = size(BIm,3); % get the number of image frames
    handles.US.vidHeight = (Bheader.bl(2)-1)-(Bheader.ul(2)+1); % get the height in pixels of the images
    handles.US.vidWidth = (Bheader.br(1)-1)-(Bheader.bl(1)+1); % get the width in pixels
    handles.US.FrameRate = Bheader.dr;
    
elseif strcmp(Ext,'.mat')
    
    load([handles.US.pname handles.US.fname])
    handles.ImStack = TVDdata.Im;
    handles.US.vidHeight = double(TVDdata.Height);
    handles.US.vidWidth = double(TVDdata.Width);
    handles.US.NumFrames = double(TVDdata.Fnum);
    % sort the time data - the last timestamp is always duplicated and so
    % needs to be adjusted
    handles.TimeStamps = double(TVDdata.Time)/1000;
    handles.US.FrameRate = round(1/(handles.TimeStamps(end-1)/(handles.US.NumFrames-1)));
    handles.TimeStamps(end) = handles.TimeStamps(end-1)+(1/handles.US.FrameRate);
    
elseif strcmp(Ext,'.png') || strcmp(Ext,'.jpg') || strcmp(Ext,'.bmp') || strcmp(Ext,'.jpeg') || strcmp(Ext,'.tiff')
    
    imgRGB = imread([handles.US.pname handles.US.fname]);
    
    if size(imgRGB,3)>1
        img = rgb2gray(imgRGB);
    else
        img = imgRGB;
    end
    
    handles.ImStack = repmat(img, 1, 1, 2);
    handles.US.vidHeight = size(handles.ImStack,1);
    handles.US.vidWidth = size(handles.ImStack,2);
    handles.US.NumFrames = size(handles.ImStack,3);
    
    handles.TimeStamps = [1; 2];
    handles.US.FrameRate = 1;
    
    handles.TimTrack_mode.Value = 1;
    
else % video file
                
    handles.movObj = VideoReader(fullfile(handles.US.pname, handles.US.fname));

    % get info
    handles.US.vidHeight = handles.movObj.Height;
    handles.US.vidWidth = handles.movObj.Width;
    handles.US.NumFrames = handles.movObj.NumFrames;
    handles.US.FrameRate = handles.movObj.FrameRate;

    i=1;
    handles.ImStack     = zeros(handles.US.vidHeight, handles.US.vidWidth, handles.US.NumFrames,'uint8');

    % read frame by frame
    while hasFrame(handles.movObj)
        waitbar(handles.movObj.CurrentTime/handles.movObj.Duration,mb)
        
        if regexp(handles.movObj.VideoFormat,'RGB')
            handles.ImStack(:,:,i) = im2gray(readFrame(handles.movObj));
        else
            handles.ImStack(:,:,i) = readFrame(handles.movObj);
        end

        handles.US.ImBrightness(i) = mean(handles.ImStack(:,:,i),'all');
        i=i+1;
    end

end

% check whether a mat file exists in the location with the same name with
% setting of the video (ImageDepth)
[path,name,~] = fileparts([handles.US.pname handles.US.fname]); %more elegant, people may not have necessarly mp4
if exist([path '/' name '.mat'],"file")
    TVD = load([path '/' name '.mat']);
    if isfield(TVD, 'TVDdata')
        if isfield(TVD.TVDdata,'cmPerPixY') %check whether the field exists and update scalar
            %ImageDepth = round(TVD.TVDdata.cmPerPixY*10,3); %round to 3 digits
            ImageDepth = round(cast(TVD.TVDdata.Height * TVD.TVDdata.cmPerPixY,'single'),3)*10;
            handles.US.ID = ImageDepth;
            set(handles.ImDepthEdit,'String',num2str(ImageDepth));
            
            % Update handles structure
            guidata(hObject, handles);
        end
    end
    clearvars path name
end

% display the path and name of the file in the filename text box
set(handles.filename,'String',[handles.US.pname handles.US.fname])

% set the string in the frame_number box to the current frame value (1)
set(handles.frame_number,'String',num2str(1))

% allows Cut_frames_before_Callback to work
handles.UTT.start_frame = 1;

if ~handles.trackbck_chkBox.Value
    handles.UTT.frame0 = handles.UTT.start_frame;
    handles.UTT.direction = 1; % forward direction
else
    handles.UTT.frame0 = handles.UTT.start_frame + handles.US.NumFrames - 1;
    handles.UTT.direction = -1; % backward direction
end

% set the limits on the slider - use number of frames to set maximum (min =
% 1)
set(handles.frame_slider,'Min',1);
set(handles.frame_slider,'Max',handles.US.NumFrames);
set(handles.frame_slider,'Value',1);
set(handles.frame_slider,'SliderStep',[1/handles.US.NumFrames 10/handles.US.NumFrames]);
set(handles.frame_rate,'String',handles.US.FrameRate(1))
set(handles.vid_width,'String',handles.US.vidWidth(1))
set(handles.vid_height,'String',handles.US.vidHeight(1))

cd(handles.US.pname)

waitbar(1,mb)
close(mb)

% make a timeline which corresponds to the ultrasound frame data
if strcmp(Ext,'.mat')
    handles.US.Time = handles.TimeStamps;
elseif exist('TVD','var') && isfield(TVD, 'TVDdata')
    if isfield(TVD.TVDdata,'Time') %check if also time exists as Telemed has uncostant framerate
        handles.US.Time = TVD.TVDdata.Time; %note that the last timestamp is repeated in Echo Wave II recordings
    end
else
    handles.US.Time = (0:(1/handles.US.FrameRate):((handles.US.NumFrames-1)/handles.US.FrameRate))';
end

if exist('TrackingData','var')
    chkload = questdlg('Do you want to load previous tracking?','Tracking data detected','Yes');
    if strcmp(chkload,'Yes')
        
        handles.Region = TrackingData.Region;
        handles.UTT.start_frame = TrackingData.start_frame;
        handles.US.NumFrames = TrackingData.NumFrames;
        set(handles.frame_slider,'Min',1);
        set(handles.frame_slider,'Max',handles.US.NumFrames);
        set(handles.frame_slider,'Value',1);
        set(handles.frame_slider,'SliderStep',[1/handles.US.NumFrames 5/handles.US.NumFrames]);
        % set the string in the frame_number to 1
        set(handles.frame_number,'String',1);
    end
end

cd(handles.US.pname)

% clear any tracking
handles = PreAllocate_Tracking(hObject, eventdata, handles);

if isfield(handles.Region.Fascicle,'TT')
    handles.Region.Fascicle = rmfield(handles.Region.Fascicle,'TT');
end

recs = findobj(handles.axes1,'Type','images.roi.rectangle');

for i = 1:length(recs)
    delete(recs(i));
end

% display the image
frame_no = round(get(handles.frame_slider,'Value')) + handles.UTT.start_frame - 1;
Im = handles.ImStack(:,:,frame_no);
axes(handles.axes1)
handles.image = image(Im);
colormap(gray(256));
axis off;
axis equal

% get the box
handles.UTT.B = [1 1 handles.US.vidWidth handles.US.vidHeight-1];
handles.UTT.imWidth = handles.US.vidWidth;
handles.UTT.imHeight = handles.US.vidHeight;

% autocrop
% handles = AutoCrop_Callback(hObject, eventdata, handles);

% add ROIs
% create region rectangles if they don't exist yet
if ~isfield(handles.UTT,'Bi') || ~isvalid(handles.UTT.Bi)
    handles.UTT.Bi = images.roi.Rectangle(handles.axes1,'position', handles.UTT.B,'color','yellow','FaceAlpha',0,'FaceSelectable',0,'Linewidth',1,'StripeColor','white');
end

if ~isfield(handles.Region, 'S')
    handles.Region.S = images.roi.Rectangle(handles.axes1,'position', [1 handles.UTT.TT.parms.apo.super.cut(1)*handles.US.vidHeight handles.US.vidWidth diff(handles.UTT.TT.parms.apo.super.cut)*handles.US.vidHeight] + [handles.UTT.Bi.Position(1) handles.UTT.Bi.Position(2) 0 0],'color','blue','FaceSelectable',0);
    handles.Region.D = images.roi.Rectangle(handles.axes1,'position', [1 handles.UTT.TT.parms.apo.deep.cut(1)*handles.US.vidHeight handles.US.vidWidth diff(handles.UTT.TT.parms.apo.deep.cut)*handles.US.vidHeight] + [handles.UTT.Bi.Position(1) handles.UTT.Bi.Position(2) 0 0],'color','green','FaceSelectable',0);
end

if handles.flipimage.Value == 1 %check based on flip tick box value
    handles = do_flip(hObject, eventdata, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = UltraTimTrack_OutputFcn(~, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
 


% --------------------------------------------------------------------
function[handles] = AutoCrop_Callback(hObject, eventdata, handles)
% hObject    handle to AutoCrop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% relative change with time
dIm = sum(abs(diff(handles.ImStack,1, 3)),3);
ndIm = dIm / max(dIm(:));

% threshold
indIm = imbinarize(ndIm);

% find connected components in the filtered matrix.
BW2 = bwareaopen(indIm,200);
stats = regionprops(BW2, 'BoundingBox');

% extract the bounding box information.
boundingBoxes = cat(1, stats.BoundingBox);

% remove Bi
if isfield(handles.UTT, 'Bi')
    handles.UTT = rmfield(handles.UTT, 'Bi');
end

% calculate the overall bounding box that encompasses all smaller bounding boxes.
handles.UTT.B = round([min(boundingBoxes(:, 1)), min(boundingBoxes(:, 2)), ...
    max(boundingBoxes(:, 1) + boundingBoxes(:, 3)) - min(boundingBoxes(:, 1)), ...
    max(boundingBoxes(:, 2) + boundingBoxes(:, 4)) - min(boundingBoxes(:, 2))]);

handles.UTT.imWidth = length(handles.UTT.B(1):(handles.UTT.B(1)+handles.UTT.B(3)-1));
handles.UTT.imHeight = length(handles.UTT.B(2):(handles.UTT.B(2)+handles.UTT.B(4)-1));

% Update handles structure
guidata(hObject, handles);

% update the image axes using show_image function (bottom)
show_image(hObject,handles);


% --------------------------------------------------------------------
function menu_crop_image_Callback(hObject, eventdata, handles)
% hObject    handle to menu_crop_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'ImStack')
    
    % define current axes
    set(handles.axes1)
    axes(handles.axes1)
    
    % use imcrop tool to determine croppable area
    [~,handles.crop_rect] = imcrop;
    
    handles.crop_rect = round(handles.crop_rect);
    handles.US.vidHeight = handles.crop_rect(4)+1;
    handles.US.vidWidth = handles.crop_rect(3)+1;
    
    % save a copy and overwrite
    ImStackOld = handles.ImStack;
    handles.ImStack     = zeros(handles.US.vidHeight, handles.US.vidWidth, handles.US.NumFrames,'uint8');
    
    %Crop all images before updating
    for ii = size(handles.ImStack,3)
        handles.ImStack(:,:,ii) = imcrop(ImStackOld(:,:,ii),handles.crop_rect);
    end
    
    clearvars tmp
    % Clean axis from original image and tight axis on the cropped image
    cla
    % update the image axes using show_image function (bottom)
    show_image(hObject,handles);
    axis tight
    
    guidata(hObject, handles);
    
end

% --- Executes on button press in clear_fascicle.
function[handles] = clear_fascicle_Callback(hObject, eventdata, handles)
% hObject    handle to clear_fascicle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    handles = PreAllocate_Tracking(hObject, eventdata, handles);
    
    if isfield(handles.Region.Fascicle,'TT')
        handles.Region.Fascicle = rmfield(handles.Region.Fascicle,'TT');
    end
    
    % set current frame to 1
    set(handles.frame_slider,'Value',1);
    set(handles.frame_number,'String',1);
    
    cla(handles.length_plot); %clean fascicle length data
    cla(handles.mat_plot);%clean fascicle angle data
%     cla(handles.axes1); %clean image data
    
    recs = findobj(handles.axes1,'Type','images.roi.rectangle');

    for i = 1:length(recs)
        delete(recs(i));
    end

    % autocrop
    handles = AutoCrop_Callback(hObject, eventdata, handles);

    % add ROIs
    handles.UTT.Bi = images.roi.Rectangle(handles.axes1,'position', handles.UTT.B,'color','yellow','FaceAlpha',0,'FaceSelectable',0,'Linewidth',1,'StripeColor','white');
    handles.Region.S = images.roi.Rectangle(handles.axes1,'position', [1 handles.UTT.TT.parms.apo.super.cut(1)*handles.UTT.imHeight handles.UTT.imWidth diff(handles.UTT.TT.parms.apo.super.cut)*handles.UTT.imHeight] + [handles.UTT.Bi.Position(1) handles.UTT.Bi.Position(2) 0 0],'color','blue','FaceSelectable',0);
    handles.Region.D = images.roi.Rectangle(handles.axes1,'position', [1 handles.UTT.TT.parms.apo.deep.cut(1)*handles.UTT.imHeight handles.UTT.imWidth diff(handles.UTT.TT.parms.apo.deep.cut)*handles.UTT.imHeight] + [handles.UTT.Bi.Position(1) handles.UTT.Bi.Position(2) 0 0],'color','green','FaceSelectable',0);


    show_data(hObject,handles);
    show_image(hObject,handles);

% --------------------------------------------------------------------
function menu_reset_image_Callback(hObject, eventdata, handles)
% hObject    handle to menu_reset_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'ImStack')
    
    show_image(hObject,handles);
    
end


% --------------------------------------------------------------------
function menu_set_depth_Callback(hObject, eventdata, handles)
% hObject    handle to menu_set_depth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'ImStack')
    
    if ~isfield(handles, 'ID')
        handles.US.ID = 60.4;
    end
    
    A = inputdlg('Enter image depth', 'Image Depth', 1, {num2str(handles.US.ID)});
    handles.US.ID = str2double(A{1});
    
    set(handles.ImDepthEdit, 'String',A{1})
    % Update handles structure
    guidata(hObject, handles);
    
end


% --------------------------------------------------------------------
function [handles] = menu_load_fascicle_Callback(hObject, eventdata, handles,varargin)
% hObject    handle to menu_load_fascicle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check if the 'file' input is provided
if nargin < 4
    % 'file' input is not provided, handle accordingly
    fileFas = []; % You can set a default file or leave it empty
else
    % 'file' input is provided in case of process folder
    fileFas = varargin{1};
end

%make trasparent
set(handles.Region.S, 'EdgeAlpha',0,'FaceAlpha',0.1,'InteractionsAllowed','none')
set(handles.Region.D, 'EdgeAlpha',0,'FaceAlpha',0.1,'InteractionsAllowed','none')

% update parms
handles.UTT.TT.parms.apo.super.cut = [handles.Region.S.Position(2) handles.Region.S.Position(2)+handles.Region.S.Position(4)] / handles.UTT.imHeight;
handles.UTT.TT.parms.apo.deep.cut = [handles.Region.D.Position(2) handles.Region.D.Position(2)+handles.Region.D.Position(4)] / handles.UTT.imHeight;

if isfield(handles,'ImStack')
    
    % find current frame number from slider
    frame_no = round(get(handles.frame_slider,'Value'))+handles.UTT.start_frame-1;
    if isempty(fileFas)
        [fname, pname] = uigetfile('*.mat','Load tracking MAT file');
        if fname == 0
            %make trasparent
            set(handles.Region.S, 'EdgeAlpha',1,'FaceAlpha',0.2,'InteractionsAllowed','all')
            set(handles.Region.D, 'EdgeAlpha',1,'FaceAlpha',0.2,'InteractionsAllowed','all')
            return
        else
            load([pname fname],'Fdat', 'TrackingData');
        end
    else
        load(fileFas,'Fdat', 'TrackingData');
    end
    
    %just be sure such necessary data exists
    if exist('Fdat','var')
        for i = 1:length(Fdat.Region)
            for k = 1:length(Fdat.Region(i).Fascicle)
               
                handles.Region(i).Fascicle(k).fas_x{frame_no} = Fdat.Region(i).Fascicle(k).fas_x{1};
                handles.Region(i).Fascicle(k).fas_y{frame_no} = Fdat.Region(i).Fascicle(k).fas_y{1};
                
                handles.Region(i).Fascicle(k).fas_x_original{frame_no} = Fdat.Region(i).Fascicle(k).fas_x{1};
                handles.Region(i).Fascicle(k).fas_y_original{frame_no} = Fdat.Region(i).Fascicle(k).fas_y{1};
                
                handles.Region(i).sup_x{frame_no} = Fdat.Region(i).sup_x{1};
                handles.Region(i).sup_y{frame_no} = Fdat.Region(i).sup_y{1};
                
                handles.Region(i).deep_x{frame_no} = Fdat.Region(i).deep_x{1};
                handles.Region(i).deep_y{frame_no} = Fdat.Region(i).deep_y{1};
                
                handles.Region(i).UT.ROIx{frame_no} = Fdat.Region(i).UT.ROIx{1};
                handles.Region(i).UT.ROIy{frame_no} = Fdat.Region(i).UT.ROIy{1};
                
                handles.UTT = TrackingData.UTT;
                
                handles = calc_fascicle_length_and_pennation(handles,frame_no);
                
                if ~isfield(handles.Region(i).Fascicle(k),'analysed_frames')
                    handles.Region(i).Fascicle(k).analysed_frames = frame_no;
                else
                    handles.Region(i).Fascicle(k).analysed_frames = sort([handles.Region(i).Fascicle(k).analysed_frames frame_no]);
                end
                
            end
            
            %             Nfascicle(i) = length(handles.Region(i).Fascicle);
            
        end
        
    else
        
        warndlg('Fascicle data not found','ERROR')
        
    end
    
    show_data(hObject,handles);
    show_image(hObject,handles);
end

% --------------------------------------------------------------------
function menu_save_fascicle_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save_fascicle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'movObj')||isfield(handles,'BIm')||isfield(handles,'ImStack')
    
    % find current frame number from slider in relation to starting frame
    frame_no = round(get(handles.frame_slider,'Value'))+handles.UTT.start_frame-1;
    try
        for i = 1:length(handles.Region)
            for j = 1:length(handles.Region(i).Fascicle)
                
                if isfield(handles.Region(i).Fascicle(j),'fas_x')
                    
                    Fdat.Region(i).Fascicle(j).fas_x{frame_no} = handles.Region(i).Fascicle(j).fas_x{frame_no};
                    Fdat.Region(i).Fascicle(j).fas_y{frame_no} = handles.Region(i).Fascicle(j).fas_y{frame_no};
                    
                end
                
            end
            
            % Save geofeatures
            Fdat.geofeatures(frame_no) = handles.Region.Fascicle.TT.geofeatures(frame_no);
            
            % Save apo data (OK)
            Fdat.Region(i).sup_x{frame_no} = handles.Region(i).sup_x{frame_no};
            Fdat.Region(i).sup_y{frame_no} = handles.Region(i).sup_y{frame_no};
            Fdat.Region(i).deep_x{frame_no} = handles.Region(i).deep_x{frame_no};
            Fdat.Region(i).deep_y{frame_no} = handles.Region(i).deep_y{frame_no};
            
            % Save fascicle length and pennation
            Fdat.Region(i).fas_length(frame_no) = handles.Region(i).Fascicle.UTT.fas_length(frame_no);
            Fdat.Region(i).fas_pen(frame_no) = handles.Region(i).Fascicle.UTT.fas_pen(frame_no);
            
            % Also save the ROI data
            Fdat.Region(i).ROIx{frame_no} = handles.Region(i).UT.ROIx{frame_no};
            Fdat.Region(i).ROIy{frame_no} = handles.Region(i).UT.ROIy{frame_no};
            %Fdat.Region(i).ROI = handles.Region(i).ROIp{frame_no};
        end
        
        % save to file
        [fname, pname] = uiputfile('*.mat', 'Save fascicle to MAT file');
        save([pname fname],'Fdat');
    catch
        warndlg('There is no fascicle to save at this frame!','ERROR')
    end
end

% --------------------------------------------------------------------
function menu_save_image_Callback(hObject, eventdata, handles)
% hObject    handle to menu_save_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'ImStack')
    [fileout, pathout, FI] = uiputfile('*.tif', 'Save video as');
    
    if FI > 0
        IM_out = getframe(handles.axes1);
        imwrite(IM_out.cdata,[pathout fileout], 'TIFF');
    end
    
end

% --------------------------------------------------------------------
function save_video_Callback(hObject, eventdata, handles)
% hObject    handle to save_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  
if ~isfolder(fullfile(handles.US.pname, 'Tracked'))
    mkdir(fullfile(handles.US.pname, 'Tracked'))
end

vidObj = VideoWriter(fullfile(handles.US.pname, 'Tracked', [handles.US.fname(1:end-4), '_tracked']),'MPEG-4');
vidObj.FrameRate = handles.US.FrameRate;
open(vidObj);

h = waitbar(0,['Saving frame 1/', num2str(handles.US.NumFrames)],'Name','Saving to video file...');

for f = handles.UTT.start_frame:(handles.UTT.start_frame + handles.US.NumFrames - 1)

    set(handles.frame_slider,'Value',f);
    set(handles.frame_number,'String',num2str(f));
    show_image(hObject,handles);

    % write the current frame to the video file
    writeVideo(vidObj,handles.image.CData)

    frac_progress = f/handles.US.NumFrames;
    waitbar(frac_progress,h, ['Processing frame ', num2str(f), '/', num2str(get(handles.frame_slider,'Max'))])
end

close(vidObj)
close(h)

% --------------------------------------------------------------------
function menu_process_all_Callback(hObject, eventdata, handles)
% hObject    handle to menu_process_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

process_all_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function Save_As_Txt_Callback(hObject, eventdata, handles)
% hObject    handle to Save_As_Txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'Region')
    
    for i = 1:length(handles.Region)
        
        
        if isfield(handles,'movObj')||isfield(handles,'BIm')||isfield(handles,'ImStack') && isfield(handles.Region(i),'fas_length')
            
            time = handles.US.Time;
            
            %determine any non-zero entries in fascicle length array
            nz = logical(handles.Region(i).Fascicle.UTT.fas_length(:,1) ~= 0);
            
            T = time(nz)';
            
            if isfield(handles.Region(i),'fas_length_corr') && ~isempty(handles.Region(i).fas_length_corr)
                R(i).FL = handles.Region(i).fas_length_corr(nz,:)';
                R(i).PEN = handles.Region(i).fas_pen_corr(nz,:)';
                
                for j = 1:size(handles.Region(i).fas_length_corr,2)
                    if sum(handles.Region(i).fas_length_corr(nz,j)) == 0
                        
                        R(i).FL(j,:) = handles.Region(i).Fascicle.UTT.fas_length(nz,j)';
                        R(i).PEN(j,:) = handles.Region(i).Fascicle.UTT.fas_pen(nz,j)';
                        
                    end
                end
                
            else R(i).FL = handles.Region(i).Fascicle.UTT.fas_length(nz,:)';
                R(i).PEN = handles.Region(i).Fascicle.UTT.fas_pen(nz,:)';
            end
            
            col_head{i} = ['Time\tFascicle Length R' num2str(i) '_F1\tFascicle Angle R' num2str(i) '_F1\t'];
            col_type{i} = '%3.4f\t%3.6f\t%3.6f';
            
            data_out{i} = [T' R(i).FL(1,:)' R(i).PEN(1,:)'];
            
            if size(R(i).FL',2) > 1
                for k = 2:size(R(i).FL',2)
                    
                    data_out{i} = [data_out{i} R(i).FL(k,:)' R(i).PEN(k,:)'];
                    regionlabel = num2str(i);
                    faslabel = num2str(k);
                    col_head{i} = [col_head{i} 'Fascicle Length R' regionlabel '_F' faslabel '\tPennation Angle R' regionlabel '_F' faslabel '\t'];
                    col_type{i} = [col_type{i} '\t%3.6f\t%3.6f'];
                end
            end
        end
    end
    
    header = [];
    type = [];
    dout = [];
    for i = 1:length(handles.Region)
        header = [header col_head{i}];
        type = [type col_type{i}];
        dout = [dout data_out{i}];
    end
    
    
    header = [header '\n'];
    %     type = [type '\n'];
    
    fileout_suggest = [handles.US.pname handles.US.fname(1:end-3) 'txt'];
    [fileout, pathout] = uiputfile(fileout_suggest,'Save fascicle data as...');
    cd(pathout);
    % open a new text file for writing
    fid = fopen(fileout,'w');
    fprintf(fid,header);
    dlmwrite(fileout,dout,'-append','delimiter','\t')
    %     fprintf(fid,type,dout);
    
    fclose(fid);
end


% --------------------------------------------------------------------
function Save_As_Mat_Callback(hObject, eventdata, handles)
% hObject    handle to Save_As_Mat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'Region')
    
    for i = 1:length(handles.Region)
        
        if isfield(handles,'movObj')||isfield(handles,'BIm')||isfield(handles,'ImStack') && isfield(handles.Region(i),'fas_length')
            
            time = handles.US.Time;
            %determine any non-zero entries in fascicle length array
            nz = logical(handles.Region(i).Fascicle.UTT.fas_length(handles.UTT.start_frame:end,1) ~= 0);
            
            T = time(nz)';
            
            TrackingData.res = handles.US.ID;
            TrackingData.start_frame = handles.UTT.start_frame;
            TrackingData.NumFrames = handles.US.NumFrames;
            %info about tracking for replication purposes
%             TrackingData.ProcessingTime = handles.UTT.ProcessingTime; %two
            TrackingData.BlockSize = handles.UTT.UT.BlockSize;
            TrackingData.Parallel = handles.do_parfor.Value;
            TrackingData.info = "Processing [TimTrack; Opticflow], %%\nBlockSize [width; height], %%\nGains [Apo, Position, Angle]";
            TrackingData.S = handles.Region.S;
            TrackingData.D = handles.Region.D;
            
            if isfield(handles.UTT.KF,'R')
                Fdat.R = handles.UTT.KF.R;
            end
            
            if isfield(handles,'Frequency')
                Fdat.Frequency = handles.Frequency;
            end
                     
            TrackingData.UTT = handles.UTT;
            Fdat.Region(i) = handles.Region(i);
            Fdat.Region(i).FL = handles.Region(i).Fascicle.UTT.fas_length(nz,:)';
            Fdat.Region(i).PEN = handles.Region(i).Fascicle.UTT.fas_pen(nz,:)';
            if isfield(handles.Region,'fas_ang') %this exists only when estimator runs
                Fdat.Region(i).ANG = handles.Region(i).Fascicle.UTT.fas_ang(nz,:)';
            end
            Fdat.Region(i).Time = time(nz);
        end
    end
end

filename = fullfile(handles.US.pname, 'Tracked', [handles.US.fname(1:end-4), '_tracked']);
save(filename,'TrackingData','Fdat');

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if strcmp(eventdata.Key,'rightarrow')
    % get the current value from the slider (round to ensure it is integer)
    % and add one to make the new frame number
    frame_no = round(get(handles.frame_slider,'Value'))+1;
    
    if frame_no < get(handles.frame_slider,'Max')
        % set the slider
        set(handles.frame_slider,'Value',frame_no);
        % set the string in the frame_number box to the current frame value
        set(handles.frame_number,'String',num2str(frame_no));
        
        show_image(hObject,handles);
    end
end

if strcmp(eventdata.Key,'leftarrow')
    % get the current value from the slider (round to ensure it is integer)
    % and subtract 1 to make the new frame number
    frame_no = round(get(handles.frame_slider,'Value'))-1;
    
    if frame_no > 1
        % set the slider
        set(handles.frame_slider,'Value',frame_no);
        % set the string in the frame_number box to the current frame value
        set(handles.frame_number,'String',num2str(frame_no));
        
        show_image(hObject,handles);
    end
end


% --- Executes on button press in PlayButton.
function PlayButton_Callback(hObject, eventdata, handles)
% hObject    handle to PlayButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'Interruptible','on');
show_data(hObject, handles);

frame_no = round(get(handles.frame_slider,'Value'));
end_frame = get(handles.frame_slider,'Max');
guidata(hObject,handles);

for f = frame_no:end_frame
    stop = get(handles.StopButton,'Value');
    
    if stop
        set(handles.StopButton,'Value',0.0);
        return
    else
        set(handles.frame_slider,'Value',f);
        set(handles.frame_number,'String',num2str(f));
        
        % update image
        show_image(hObject,handles);
        drawnow
    end
end

% --- Executes on button press in StopButton.
function StopButton_Callback(hObject, eventdata, handles)
% hObject    handle to StopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.StopButton,'Value',1.0)


% --------------------------------------------------------------------
function Load_All_Tracked_Frames_Callback(hObject, eventdata, handles)
% hObject    handle to Load_All_Tracked_Frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%load the avi file

menu_clear_tracking_Callback(hObject, eventdata, handles); % clear any current tracking

%select file
[fname, pname] = uigetfile('*.mat', 'Pick a .MAT file');
load([pname fname],'TrackingData','Fdat');

handles.Region = Fdat.Region;
handles.UTT.start_frame = TrackingData.start_frame;
handles.US.NumFrames = TrackingData.NumFrames;
handles.Region.S = TrackingData.S;
handles.Region.D = TrackingData.D;
handles.UTT = TrackingData.UTT;

handles.Region.Fascicle.TT.geofeatures = Fdat.Region.Fascicle.TT.geofeatures;
set(handles.frame_slider,'Min',1);
set(handles.frame_slider,'Max',handles.US.NumFrames);
set(handles.frame_slider,'Value',1);
set(handles.frame_slider,'SliderStep',[1/handles.US.NumFrames 5/handles.US.NumFrames]);
% set the string in the frame_number to 1
set(handles.frame_number,'String',1);

show_image(hObject,handles);
show_data(hObject, handles); %update plots


% --- Executes on button press in zoominvideo.
function zoominvideo_Callback(hObject, eventdata, handles)
% hObject    handle to zoominvideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% function too zoom the image by adjusting the axes' limits
axes(handles.axes1)
cx = get(gca,'XLim');
cy = get(gca,'YLim');

xrange = cx(2)-cx(1);
yrange = cy(2)-cy(1);
px = xrange/10;
py = yrange/10;

nx = [cx(1)+(0.5*px),cx(2)-(0.5*px)];
ny = [cy(1)+(0.5*py),cy(2)-(0.5*py)];


set(gca,'XLim',nx,'YLim',ny);
handles.Vidax_X = nx;
handles.Vidax_Y = ny;
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in zoomoutvideo.
function zoomoutvideo_Callback(hObject, eventdata, handles)
% hObject    handle to zoomoutvideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1)
cx = get(gca,'XLim');
cy = get(gca,'YLim');

xrange = cx(2)-cx(1);
yrange = cy(2)-cy(1);
px = xrange/10;
py = yrange/10;

nx = [cx(1)-(0.5*px),cx(2)+(0.5*px)];
ny = [cy(1)-(0.5*py),cy(2)+(0.5*py)];

set(gca,'XLim',nx,'YLim',ny);
handles.Vidax_X = nx;
handles.Vidax_Y = ny;
% Update handles structure
guidata(hObject, handles);

% --- Executes on value changed
function ImDepthEdit_Callback(hObject, eventdata, handles)
% hObject    handle to ImDepthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ImDepthEdit as text
%        str2double(get(hObject,'String')) returns contents of ImDepthEdit as a double
scalarOld = handles.US.ID;
handles.US.ID = str2double(get(handles.ImDepthEdit,'String'));

for i = 1:length(handles.Region)
    if isfield(handles.Region(i),'Fascicle')
        if isfield(handles.Region(i).Fascicle.UTT,'fas_length')
            
            if ~isempty(handles.Region(i).Fascicle.UTT.fas_length)
                FL = handles.Region(i).Fascicle.UTT.fas_length;
                FL = FL ./ scalarOld;
                FL = FL .* handles.US.ID;
                handles.Region(i).Fascicle.UTT.fas_length = FL;
            end
        end
        show_data(hObject, handles); %update plots
    end
end

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ImDepthEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImDepthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function show_data(hObject, handles)
% difference with show_image is that this is called once (not per frame)

% find current frame number from slider
frame_no = round(get(handles.frame_slider,'Value')) + handles.UTT.start_frame - 1;
j = 1;
i = 1;

% dt = 1/handles.US.FrameRate;
FL = handles.Region(i).Fascicle.UTT.fas_length(1:handles.US.NumFrames);
PEN = handles.Region(i).Fascicle.UTT.fas_pen(1:handles.US.NumFrames);
FLm = handles.Region(i).Fascicle(j).manual.fas_length(1:handles.US.NumFrames);
PENm = handles.Region(i).Fascicle(j).manual.fas_pen(1:handles.US.NumFrames);
time = handles.US.Time(1:handles.US.NumFrames);

% fascicle length
hold(handles.length_plot, 'off');
% if ~handles.TimTrack_mode.Value
    plot(handles.length_plot,time,FL,'r', time(:), FLm(:), 'mx','linewidth',2);
    
    if sum(isfinite(FL(:)))>0
        set(handles.length_plot,'ylim',[min(FL)*0.85 max(FL)*1.15],'box','off','xlim', [0 max(time)]); %set axis 15% difference of min and and value,easier to read
    end
    xlabel(handles.length_plot, 'Time (s)');
    ylabel(handles.length_plot, 'Fascicle Length (mm)');

% end
%     cla
%     set(handles.length_plot,'ylim',[0 1],'box','off','xlim', [0 1], 'XTick',[],'XTickLabel',[],'YTick',[],'YTickLabel',[])
%     text(handles.length_plot, .1, .5, ['Fascicle length = ', num2str(round(FL(frame_no),1)), ' mm'],'FontSize',14)
%     xlabel('');
%     ylabel('');
% end

% pennation
hold(handles.mat_plot, 'off');
% if ~handles.TimTrack_mode.Value
    plot(handles.mat_plot,time,PEN,'r', time(:), PENm(:), 'mx','linewidth',2);
    
    if sum(isfinite(PEN(:)))>0
        set(handles.mat_plot,'ylim',[min(PEN)*0.85 max(PEN)*1.15],'box','off','xlim', [0 max(time)]); %set axis 15% difference of min and and value,easier to read
    end
    xlabel(handles.mat_plot, 'Time (s)');
    ylabel(handles.mat_plot, 'Fascicle angle (deg)');

% end
%     cla
%     set(handles.mat_plot,'ylim',[0 1],'box','off','xlim', [0 1], 'XTick',[],'XTickLabel',[],'YTick',[],'YTickLabel',[])
%     text(handles.mat_plot, .1, .5, ['Fascicle angle = ', num2str(round(PEN(frame_no),1)), ' deg'],'FontSize',14)
%     xlabel('');
%     ylabel('');
% end


%---------------------------------------------------------
% Function to show image with appropriate image processing
%---------------------------------------------------------
function handles = show_image(hObject, handles)

if isfield(handles,'ImStack')
    
    % find current frame number from slider
    frame_no = round(get(handles.frame_slider,'Value')) + handles.UTT.start_frame - 1;
    
    i = 1;
    j = 1;
    
    if isfield(handles.UTT, 'Bi')
        if isvalid(handles.UTT.Bi)
            handles.UTT.B = get(handles.UTT.Bi,'position');
        end
    end
    
    % extract locations to be plotted
    fasx = handles.Region(i).Fascicle(j).fas_x{frame_no} + handles.UTT.B(1);
    fasy = handles.Region(i).Fascicle(j).fas_y{frame_no} + handles.UTT.B(2);
    fasx_m = [handles.Region(i).Fascicle(j).fas_x_manual{frame_no}] + handles.UTT.B(1);
    fasy_m = [handles.Region(i).Fascicle(j).fas_y_manual{frame_no}] + handles.UTT.B(2);
    FL = handles.Region(i).Fascicle(j).UTT.fas_length(:);
    PEN = handles.Region(i).Fascicle(j).UTT.fas_pen(:);
    
    supx = handles.Region(i).sup_x{frame_no} + handles.UTT.B(1);
    supy = handles.Region(i).sup_y{frame_no} + handles.UTT.B(2);
    deepx = handles.Region(i).deep_x{frame_no} + handles.UTT.B(1);
    deepy = handles.Region(i).deep_y{frame_no} + handles.UTT.B(2);
    ROIx = handles.Region(i).UT.ROIx{frame_no} + handles.UTT.B(1);
    ROIy = handles.Region(i).UT.ROIy{frame_no} + handles.UTT.B(2);
    ptsx = handles.Region(i).UT.fas_points{frame_no}(:,1) + handles.UTT.B(1); 
    ptsy = handles.Region(i).UT.fas_points{frame_no}(:,2) + handles.UTT.B(2); 

    % start with the image
    Im = handles.ImStack(:,:,frame_no);

    % add manual fascicle
    if sum(isfinite([fasx_m; fasy_m])) >= 4
        Im = insertShape(Im,'line',[fasx_m(1), fasy_m(1), fasx_m(2),fasy_m(2)], 'LineWidth',5, 'Color','magenta');
        Im = insertMarker(Im,[fasx_m(1), fasy_m(1); fasx_m(2), fasy_m(2)], 'o', 'Color','magenta','size',5);
    end

    % add fascicle
    if sum(isfinite([fasx; fasy])) >= 4
        Im = insertShape(Im,'line',[fasx(1), fasy(1), fasx(2),fasy(2)], 'LineWidth',5, 'Color','red');
        Im = insertMarker(Im,[fasx(1), fasy(1); fasx(2), fasy(2)], 'o', 'Color','red','size',5);
    end

    % add aponeurosis
    if sum(isfinite([supx; supy])) >= 4
        Im = insertShape(Im,'line',[supx(1), supy(1),supx(2),supy(2)], 'LineWidth',5, 'Color','blue');
    end

    if sum(isfinite([deepx; deepy])) >= 4
        Im = insertShape(Im,'line',[deepx(1), deepy(1),deepx(2),deepy(2)], 'LineWidth',5, 'Color','green');
    end

    % add ROI
    if sum(isfinite([ROIx; ROIy])) >= 10
        Im = insertShape(Im,'Polygon',[ROIx(1), ROIy(1), ROIx(2), ROIy(2),ROIx(3), ROIy(3), ROIx(4), ROIy(4), ROIx(5), ROIy(5)],'LineWidth',1, 'Color','red');
    end

    % add feature points
    if sum(isfinite([ptsx; ptsy])) >= 10
        Im = insertMarker(Im,[ptsx, ptsy], '+', 'Color','red','size',2);
        Im = insertText(Im, [10 10], ['Number of feature points: ' ,num2str(length(handles.Region(i).UT.fas_points{frame_no}))],'BoxColor','white');
    end

    % plot the image
    if ~isfield(handles, 'image') || ~isvalid(handles.image) % if it didn't exist yet
        axes(handles.axes1)
        handles.image = image(Im);
        colormap(gray(256));
        axis off;
        axis equal

    else
        set(handles.image, 'CData',Im);  % if it did exist yet
    end

%     % create region rectangles if they don't exist yet
%     if ~isfield(handles.UTT,'Bi') || ~isvalid(handles.UTT.Bi)
%         handles.UTT.Bi = images.roi.Rectangle(handles.axes1,'position', handles.UTT.B,'color','yellow','FaceAlpha',0,'FaceSelectable',0,'Linewidth',1,'StripeColor','white');
%     end
% 
%     if ~isfield(handles.Region, 'S')
%         handles.Region.S = images.roi.Rectangle(handles.axes1,'position', [1 handles.UTT.TT.parms.apo.super.cut(1)*handles.UTT.imHeight handles.UTT.imWidth diff(handles.UTT.TT.parms.apo.super.cut)*handles.UTT.imHeight] + [handles.UTT.Bi.Position(1) handles.UTT.Bi.Position(2) 0 0],'color','blue','FaceSelectable',0);
%         handles.Region.D = images.roi.Rectangle(handles.axes1,'position', [1 handles.UTT.TT.parms.apo.deep.cut(1)*handles.UTT.imHeight handles.UTT.imWidth diff(handles.UTT.TT.parms.apo.deep.cut)*handles.UTT.imHeight] + [handles.UTT.Bi.Position(1) handles.UTT.Bi.Position(2) 0 0],'color','green','FaceSelectable',0);
%     end
    
    % flip things back if needed
    if handles.flipimage.Value
        title(handles.axes1,'\leftarrow Superficial fascicle attachment');
        set(handles.axes1,'xdir','reverse')
    else
        title(handles.axes1,'Superficial fascicle attachment \rightarrow');
        set(handles.axes1,'xdir','normal')
    end
    
    % data plot
    % remove previous vertical lines
    children = get(handles.length_plot, 'children');
    if length(children) > 2
        delete(children(1));
    end
    
    children = get(handles.mat_plot, 'children');
    if length(children) > 2
        delete(children(1));
    end

    if sum(isfinite(FL)) > 0
        % add new vertical lines
        line(handles.length_plot, 'xdata', handles.US.Time(frame_no) * ones(1,2), 'ydata', [.85*min(FL) 1.15*max(FL)],'color',[0 0 0]);
        line(handles.mat_plot, 'xdata', handles.US.Time(frame_no) * ones(1,2), 'ydata', [.85*min(PEN) 1.15*max(PEN)],'color', [0 0 0]);
    end
    
    % if handles.TimTrack_mode.Value
    %     show_data(hObject, handles)
    % end
    
    % Update handles structure
    guidata(hObject, handles);
    
end

% --- Executes on button press in process_all.
function[handles] = process_all_Callback(hObject, eventdata, handles)
% hObject    handle to process_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

i = 1;

% detect first frame if required or last frame if backward tracking
if isnan(handles.Region(i).Fascicle.UTT.fas_length(handles.UTT.frame0))
    % needed because Auto_Detect works on current frame
    set(handles.frame_slider,'Value',handles.UTT.frame0 - handles.UTT.start_frame + 1);
    set(handles.frame_number,'String',num2str(handles.UTT.frame0 - handles.UTT.start_frame + 1));

    handles = Auto_Detect_Callback(hObject, eventdata, handles);
end

% Run TimTrack
handles = process_all_TimTrack(hObject, eventdata, handles);

if ~handles.TimTrack_mode.Value
    % Run Ultratrack
    handles = process_all_UltraTrack(hObject, eventdata, handles);

    % Do state estimation
    handles = do_state_estimation(hObject, eventdata, handles);
end

% update the image axes using show_image function (bottom)
show_data(hObject, handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%% TimTrack
function[handles] = process_all_TimTrack(hObject, eventdata, handles)

% run TimTrack on all frames
frames = handles.UTT.frame0:handles.UTT.direction:(handles.UTT.frame0 + handles.UTT.direction * (handles.US.NumFrames-1)); 

% remove super_pos and deep_pos from geofeatures
if isfield(handles.Region.Fascicle.TT.geofeatures, 'super_pos')
    handles.Region.Fascicle.TT.geofeatures = rmfield(handles.Region.Fascicle.TT.geofeatures, 'super_pos');
    handles.Region.Fascicle.TT.geofeatures = rmfield(handles.Region.Fascicle.TT.geofeatures, 'deep_pos');
end

% get the first estimate from auto_detect
% geofeatures(frames(1)) = handles.Region.Fascicle.TT.geofeatures(frames(1));    

numIterations = length(frames);

parms = handles.UTT.TT.parms;
parms.extrapolation = 1;

n = handles.UTT.imWidth;

if isfield(handles,'ImStack')
    B = round([1 handles.UTT.Bi.Position(2) handles.UTT.imWidth handles.UTT.Bi.Position(4)]);

    Im = handles.ImStack(B(2):(B(2)+B(4)-1), B(1):(B(1)+B(3)-1),:);
    im2 = imresize(Im, 1/handles.UTT.TT.imresize_fac);
    
    % call once to get the correct fascicle region
    auto_ultrasound(im2(:,:,handles.UTT.start_frame), parms);
    
    % call again a bunch of times to get estimate the total duration
    for i = 1:min([size(im2,3), 5])
        tstart = tic;
        auto_ultrasound(im2(:,:,1), parms);
        dt = toc(tstart);
    end
    
    est_duration = dt * numIterations;
    
    % prompt to optionally change processing based on computational time
    answer = 'Undefined';
    if (est_duration > 60) && handles.do_parfor.Value == 0
        answer = questdlg(['Estimated TimTrack duration: ', num2str(est_duration), ' s, would you like to use parallel pool?'], 'Type of computation', 'Yes','No','Cancel','Yes');
    end
    
    if strcmp(answer, 'Yes')
        handles.do_parfor.Value = 1;
    elseif strcmp(answer, 'No')
        handles.do_parfor.Value = 0;
    elseif strcmp(answer,'Cancel')
        return
    end
    
    if ~strcmp(answer,'Cancel')
        for i = 1:length(handles.Region)
            
            % TimTrack (parfor or for)
            if handles.do_parfor.Value
                % Then construct a ParforProgressbar object:
                WaitMessage = parfor_wait(numIterations,'Waitbar', true,'Title','Running TimTrack...');
                
                tstart = tic;
                
                parfor f = frames
                    geofeatures(f) = auto_ultrasound(im2(:,:,f), parms);
                    WaitMessage.Send; %update waitbar parfor
                end
                WaitMessage.Destroy(); %update waitbar parfor
                handles.UTT.TT.ProcessingTime(1) = toc(tstart);
                %
                
            else
                %single thread for loop
                tstart = tic;
                hwb = waitbar(0,'','Name','Running TimTrack...');
                for f = frames
                    geofeatures(f) = auto_ultrasound(im2(:,:,f), parms);
                    waitbar((f-handles.UTT.start_frame) / numIterations, hwb, sprintf('Processing frame %d/%d', (f-handles.UTT.start_frame), numIterations)); %maybe numIterations +1 on bar, but not sure for cutting frames
                    
                end
                close(hwb)
                handles.UTT.TT.ProcessingTime(1) = toc(tstart);
            end
            
            % Adjust the parameter of geofeatures
            for kk = frames
                
                % resize
                geofeatures(kk).fas_coef(2)     = geofeatures(kk).fas_coef(2) * handles.UTT.TT.imresize_fac;
                geofeatures(kk).super_coef(2)   = geofeatures(kk).super_coef(2) * handles.UTT.TT.imresize_fac;
                geofeatures(kk).deep_coef(2)    = geofeatures(kk).deep_coef(2) * handles.UTT.TT.imresize_fac;
                geofeatures(kk).thickness       = geofeatures(kk).thickness * handles.UTT.TT.imresize_fac;
                geofeatures(kk).faslen          = geofeatures(kk).faslen * handles.UTT.TT.imresize_fac;                

                % get vertical locations at image boundaries
                geofeatures(kk).super_pos = polyval(geofeatures(kk).super_coef, [1 n]);
                geofeatures(kk).deep_pos = polyval(geofeatures(kk).deep_coef, [1 n]);
                
                % calculate fascicle
                Deep_intersect_x = round((geofeatures(kk).deep_coef(2) - geofeatures(kk).fas_coef(2))   ./ (geofeatures(kk).fas_coef(1) - geofeatures(kk).deep_coef(1)));
                Super_intersect_x = round((geofeatures(kk).super_coef(2) - geofeatures(kk).fas_coef(2)) ./ (geofeatures(kk).fas_coef(1) - geofeatures(kk).super_coef(1)));
                Super_intersect_y = polyval(geofeatures(kk).super_coef, Super_intersect_x);
                Deep_intersect_y = polyval(geofeatures(kk).deep_coef, Deep_intersect_x);
                
                handles.Region(i).sup_x{kk} = [1 n]';
                handles.Region(i).sup_y{kk} = polyval(geofeatures(kk).super_coef, [1 n]');
                
                handles.Region(i).deep_x{kk} = [1 n]';
                handles.Region(i).deep_y{kk} = polyval(geofeatures(kk).deep_coef, [1 n]');
                
                handles.Region(i).sup_x_original{kk} = handles.Region(i).sup_x{kk};
                handles.Region(i).sup_y_original{kk} = handles.Region(i).sup_y{kk};
                handles.Region(i).deep_x_original{kk} = handles.Region(i).deep_x{kk};
                handles.Region(i).deep_y_original{kk} = handles.Region(i).deep_y{kk};
                
                super_apo = geofeatures(kk).super_pos';
                deep_apo = geofeatures(kk).deep_pos';
                thickness = deep_apo - super_apo;
                r = .1; % fraction of thickness
     
                handles.Region(i).UT.ROIx{kk} = [1 1 n n 1]';
                handles.Region(i).UT.ROIy{kk} = round([super_apo(1)+thickness(1)*r; deep_apo-thickness*r; super_apo([2,1])+thickness([2,1])*r]);
                
                % if not first or last update fas pts
                if kk ~= frames(1)  
                    handles.Region.Fascicle.fas_x{kk} = [Deep_intersect_x Super_intersect_x]';
                    handles.Region.Fascicle.fas_y{kk} = [Deep_intersect_y Super_intersect_y]';
                    
                    handles.Region.Fascicle.fas_x_original{kk} = handles.Region.Fascicle.fas_x{kk};
                    handles.Region.Fascicle.fas_y_original{kk} = handles.Region.Fascicle.fas_y{kk};
                end
                
                % calculate the length and pennation for the current frame
                handles = calc_fascicle_length_and_pennation(handles,kk);
            end
            
            handles.Region.Fascicle.TT.geofeatures = geofeatures;
        end
    end 
end

%%%% Ultratrack (KLT optic flow)
function[handles] = process_all_UltraTrack(hObject, eventdata, handles)

% 3 ROItypes are supported:
% - Hough - local (default): ROI is based on detected fascicles from Hough
% transform. Advantage: more precisely tracking fascicles. Disadvantage:
% fewer feature points. 
% - Hough - global: ROI is based on detected aponeuroses from Hough
% transform. Advantage: more feature points. Disadvantage: less precisely
% tracking fascicles. 
% - Optical flow: ROI of first frame is based on detected aponeuroses from
% Hough transform, but all other frames are based on optical flow. Note:
% this ROI drifts over time. 

h = waitbar(0,['Processing frame 1/', num2str(handles.US.NumFrames)],'Name','Running UltraTrack...');

tstart = tic;

frames = handles.UTT.frame0:handles.UTT.direction:(handles.UTT.frame0 + handles.UTT.direction * (handles.US.NumFrames-1)); 

n = handles.UTT.imWidth;
m = handles.UTT.imHeight;
        
for i = 1:length(handles.Region)
    for f = frames
        
        % previous frame
        fprev = f - handles.UTT.direction;

        % extract image
        B = round([1 handles.UTT.Bi.Position(2) handles.UTT.imWidth handles.UTT.Bi.Position(4)]);
        im = handles.ImStack(B(2):(B(2)+B(4)-1), B(1):(B(1)+B(3)-1),f);

        % get masked image
        [I_fmasked, I_amasked] = get_masked_image(im, f, handles);
           
        % get ROI
        ROIy = handles.Region(i).UT.ROIy{f};
        ROIx = handles.Region(i).UT.ROIx{f};

        for j = 1:length(handles.Region(i).Fascicle)
                       
            if f == frames(1) || ~exist('fpointTracker','var') % first frame: detect points
           
                % detect points
                fpoints = detectMinEigenFeatures(I_fmasked,'FilterSize',11, 'MinQuality', 0.005);
                
                if contains(handles.UTT.UT.ROItype, 'Hough')
                    fpoints = fpoints.selectStrongest(300);
                end
                
                % get location
                fpoints = double(fpoints.Location);
                
                % points must be in ROI
                inPoints = inpolygon(fpoints(:,1), fpoints(:,2), ROIx, ROIy);
                fpoints = fpoints(inPoints,:);
                
                % define fascicle tracker
                fpointTracker = vision.PointTracker('NumPyramidLevels',4,'MaxIterations',50,'MaxBidirectionalError',inf,'BlockSize',handles.UTT.UT.BlockSize);
                initialize(fpointTracker,fpoints,im);
                
                % seperately track aponeurosis
                if contains(handles.UTT.UT.ROItype, 'Hough')
                    % define aponeurosis tracker
                    apoints = detectMinEigenFeatures(I_amasked,'FilterSize',11, 'MinQuality', 0.005);
                    apoints =  double(apoints.Location);
                    apointTracker = vision.PointTracker('NumPyramidLevels',4,'MaxIterations',50,'MaxBidirectionalError',inf,'BlockSize',handles.UTT.UT.BlockSize);
                    initialize(apointTracker,apoints,im);
                end
                
                % reset fas_x and fas_y to original values
                handles.Region(i).Fascicle(j).fas_x{f} = handles.Region(i).Fascicle(j).fas_x_original{f};
                handles.Region(i).Fascicle(j).fas_y{f} = handles.Region(i).Fascicle(j).fas_y_original{f};
                
            else % not the first frame
                
                % Compute the flow and new roi
                [fpointsNew, isFound] = step(fpointTracker, im);
                [wf,~] = estimateGeometricTransform2D(fpoints(isFound,:), fpointsNew(isFound,:), 'affine', 'MaxDistance',50);
                handles.Region(i).UT.fas_warp(:,:,fprev) = wf;
                
                % apply the warp to fascicles
                fas_prev = [handles.Region(i).Fascicle(j).fas_x{fprev} handles.Region(i).Fascicle(j).fas_y{fprev}];
                fas_new = transformPointsForward(wf, fas_prev);
                
                % save
                handles.Region(i).Fascicle(j).fas_x{f} = fas_new(:,1);
                handles.Region(i).Fascicle(j).fas_y{f} = fas_new(:,2);
                
                % make a copy
                handles.Region(i).Fascicle(j).fas_x_original{f} = handles.Region(i).Fascicle(j).fas_x{f};
                handles.Region(i).Fascicle(j).fas_y_original{f} = handles.Region(i).Fascicle(j).fas_y{f};
                
                % in ROItype = Hough, seperately track the aponeuroses
                if contains(handles.UTT.UT.ROItype, 'Hough')
                    
                    % Compute the flow and new roi
                    [apointsNew, isFound] = step(apointTracker, im);
                    [wa,~] = estimateGeometricTransform2D(apoints(isFound,:), apointsNew(isFound,:), 'affine', 'MaxDistance',50);
                    handles.Region(i).UT.apo_warp(:,:,fprev) = wa;
                    
                    % apply warp to aponeurosis
                    super_prev = [handles.Region(i).sup_x{fprev} handles.Region(i).sup_y{fprev}];
                    super_new = transformPointsForward(wa, super_prev);
                    
                    deep_prev = [handles.Region(i).deep_x{fprev} handles.Region(i).deep_y{fprev}];
                    deep_new = transformPointsForward(wa, deep_prev);
                    
                    % save
                    handles.Region(i).sup_x{f} = [1 n]';
                    handles.Region(i).sup_y{f} = super_new(:,2);
                    handles.Region(i).deep_x{f} = [1 n]';
                    handles.Region(i).deep_y{f} = deep_new(:,2);
   
                else % in ROItype = Optical flow, don't use TimTrack ROI, but compute it from optical flow
                    % apply warp to ROI
                    ROIpos = transformPointsForward(wf, [handles.Region(i).UT.ROIx{fprev} handles.Region(i).UT.ROIy{fprev}]);
                    
                    ROIx = ROIpos(:,1);
                    ROIy = ROIpos(:,2);
                    
                    ROIx(ROIx > handles.UTT.imWidth) = handles.UTT.imWidth;
                    ROIy(ROIy > handles.UTT.imHeight) = handles.UTT.imHeight;
                    ROIx(ROIx < 1) = 1;
                    ROIy(ROIy < 1) = 1;
                    
                    handles.Region(i).sup_x{f}  = ROIx([1,4]);
                    handles.Region(i).sup_y{f}  = ROIy([1,4]);
                    handles.Region(i).deep_x{f} = ROIx([2,3]);
                    handles.Region(i).deep_y{f} = ROIy([2,3]);
                end
                
                % make a copy
                handles.Region(i).sup_x_original{f} = handles.Region(i).sup_x{f};
                handles.Region(i).sup_y_original{f} = handles.Region(i).sup_y{f};
                handles.Region(i).deep_x_original{f} = handles.Region(i).deep_x{f};
                handles.Region(i).deep_y_original{f} = handles.Region(i).deep_y{f};
                
                % save ROI
                handles.Region(i).UT.ROIx{f} = ROIx;
                handles.Region(i).UT.ROIy{f} = ROIy;
                
                % calculate the length and pennation for the current frame
                handles = calc_fascicle_length_and_pennation(handles,f);
                
                % update the points
%                 fpoints = fpointsNew;
                
                % if drops below 100, define new points
%                 if length(fpoints) < 100 || ~strcmp(handles.UTT.UT.ROItype(1:5), 'Hough')
                    
                    % detect points
                    fpoints = detectMinEigenFeatures(I_fmasked,'FilterSize',11, 'MinQuality', 0.005);
                    
                    if strcmp(handles.UTT.UT.ROItype(1:5), 'Hough')
                        fpoints = fpoints.selectStrongest(300);
                    end
                    
                    fpoints = double(fpoints.Location);
%                 end
                
                % points must be in ROI
                inPoints = inpolygon(fpoints(:,1),fpoints(:,2), ROIx, ROIy);
                fpoints = fpoints(inPoints,:);                
                
                % set tracker
                setPoints(fpointTracker, fpoints);
                
                % update the points
                if strcmp(handles.UTT.UT.ROItype(1:5), 'Hough')
                    apoints = apointsNew;
                    
                    if length(apoints) < 500
                        % detect points
                        apoints = detectMinEigenFeatures(I_amasked,'FilterSize',11, 'MinQuality', 0.005);
                        apoints = double(apoints.Location);
                    end
                    
                    s = handles.UTT.TT.parms.apo.super.cut;
                    ROIys = [s(1) s(2) s(2) s(1) s(1)]' * m;
                    
                    d = handles.UTT.TT.parms.apo.deep.cut;
                    ROIyd = [d(1) d(2) d(2) d(1) d(1)]' * m;
                    
                    % must be in ROI
                    dinPoints = inpolygon(apoints(:,1),apoints(:,2), ROIx, ROIyd);
                    sinPoints = inpolygon(apoints(:,1),apoints(:,2), ROIx, ROIys);
                    apoints = apoints(dinPoints | sinPoints,:);
                   
                    
                    % set tracker
                    setPoints(apointTracker, apoints);
                end
            end
            
            if strcmp(handles.UTT.UT.ROItype(1:5), 'Hough')
                % save the points
                handles.Region(i).UT.apo_points{f} = apoints;
            end

            % save the points
            handles.Region(i).UT.fas_points{f} = fpoints;

        end
        
        frac_progress = ((f-handles.UTT.start_frame)+(get(handles.frame_slider,'Max')*(i-1))) / (get(handles.frame_slider,'Max')*length(handles.Region));
        waitbar(frac_progress,h, ['Processing frame ', num2str((f-handles.UTT.start_frame+1)), '/', num2str(get(handles.frame_slider,'Max'))])
    end
    
end
close(h)
handles.UTT.UT.ProcessingTime = toc(tstart);


function[handles] = do_state_estimation(hObject, eventdata, handles)
% hObject    handle to do_state_estimation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

i = 1;
j = 1;

% get Qmax
if ~isnan(handles.UTT.KF.Q)
    handles = estimate_variance(hObject, eventdata, handles);
    
    frames = handles.UTT.frame0:handles.UTT.direction:(handles.UTT.frame0 + handles.UTT.direction * (handles.US.NumFrames-1)); 
    
    % reset fascicle and aponeurosis locations to original values
    handles.Region(i).Fascicle(j).fas_x = handles.Region(i).Fascicle(j).fas_x_original;
    handles.Region(i).Fascicle(j).fas_y = handles.Region(i).Fascicle(j).fas_y_original;
    handles.Region(i).sup_x = handles.Region(i).sup_x_original;
    handles.Region(i).sup_y = handles.Region(i).sup_y_original;
    handles.Region(i).deep_x = handles.Region(i).deep_x_original;
    handles.Region(i).deep_y = handles.Region(i).deep_y_original;
    
    % initialize state estimator
    handles = initialize_state_estimator(handles);
    
    % aponeurosis state estimation
    for f = 2:length(frames)
        handles = apo_state_estimator(handles,frames(f),frames(f-1));
    end

    % fascicle state estimation
    for f = 2:length(frames)
        handles = state_estimator(handles,frames(f),frames(f-1));
    end
    
    % Rauch-Tung-Striebel backwards filter
    reversed_frames = flip(frames);
    for f = 2:length(reversed_frames)
        handles = state_smoothener(handles,reversed_frames(f),reversed_frames(f-1));
    end

    % update fascicle
    for f = 1:length(frames)
        handles = update_Fascicle(handles,frames(f));
    end
    
    show_image(hObject,handles);
    show_data(hObject, handles);
    guidata(hObject, handles);
end

function[handles] = initialize_state_estimator(handles)

i = 1;
j = 1;

Rs = handles.UTT.KF.R(2:end) * .01;
handles.Region(i).KF.P_plus{handles.UTT.frame0} = Rs';

alpha0 = nan(1,handles.UTT.KF.NS);

for k = 1:handles.UTT.KF.NS % number of starting frames
    alpha0(k) = atan2d(-diff(handles.Region(i).Fascicle(j).fas_y{handles.UTT.frame0+handles.UTT.direction*k}), diff(handles.Region(i).Fascicle(j).fas_x{handles.UTT.frame0+handles.UTT.direction*k}));
end

handles.Region(i).Fascicle(j).KF.X_plus{handles.UTT.frame0} = [handles.Region(i).Fascicle(j).fas_x{handles.UTT.frame0}(2) mean(alpha0)];    
handles.Region(i).Fascicle(j).KF.P_plus{handles.UTT.frame0} = [0 var(alpha0)+.1];

% if manual is available for first frame, overrule
if isfinite(handles.Region(i).Fascicle(j).fas_x_manual{handles.UTT.frame0}(2))
    
    handles.Region(i).Fascicle(j).KF.X_plus{handles.UTT.frame0} = [handles.Region(i).Fascicle(j).fas_x_manual{handles.UTT.frame0}(2) handles.Region(i).Fascicle(j).manual.fas_ang(handles.UTT.frame0)];
    handles.Region(i).Fascicle(j).KF.P_plus{handles.UTT.frame0} = [0 0];

    handles.Region(i).sup_x{handles.UTT.frame0} = handles.Region(i).sup_x_manual{handles.UTT.frame0};
    handles.Region(i).sup_y{handles.UTT.frame0} = handles.Region(i).sup_y_manual{handles.UTT.frame0};
    handles.Region(i).deep_x{handles.UTT.frame0} = handles.Region(i).deep_x_manual{handles.UTT.frame0};
    handles.Region(i).deep_y{handles.UTT.frame0} = handles.Region(i).deep_y_manual{handles.UTT.frame0};

end

% a priori is the same as a positeriori
handles.Region(i).Fascicle(j).KF.P_minus{handles.UTT.frame0} = handles.Region(i).Fascicle(j).KF.P_plus{handles.UTT.frame0};
handles.Region(i).Fascicle(j).KF.X_minus{handles.UTT.frame0} = handles.Region(i).Fascicle(j).KF.X_plus{handles.UTT.frame0};

handles = update_Fascicle(handles,handles.UTT.frame0);


function[handles] = state_estimator(handles,frame_no,prev_frame_no)

i = 1; 
j = 1;

% Apply warp
fas_prev = [handles.Region(i).Fascicle(j).fas_x{prev_frame_no} handles.Region(i).Fascicle(j).fas_y{prev_frame_no}];
alpha_prev = handles.Region(i).Fascicle(j).KF.X_plus{prev_frame_no}(2);

w = handles.Region(i).UT.fas_warp(:,:,prev_frame_no);
fas_new = transformPointsForward(w, fas_prev);

% Estimate the change in fascicle angle from the change in points
dalpha = abs(atan2d(diff(fas_new(:,2)), diff(fas_new(:,1)))) - abs(atan2d(diff(fas_prev(:,2)), diff(fas_prev(:,1))));
alpha_new = alpha_prev + dalpha;

% A priori state estimate
x_minus = [fas_new(2,1) alpha_new];

% State estimation superficial aponeurosis attachment
% previous estimate covariance
P_prev = handles.Region(i).Fascicle(j).KF.P_plus{prev_frame_no};

% get the process noise and measurement noise covariance
dx = sqrt((fas_new(2,1)-fas_prev(2,1)).^2 + (fas_new(2,2)-fas_prev(2,2)).^2);
s.Q = getQ(handles, dx);
R(1) = handles.UTT.KF.X;

% a priori estimate from optical flow
s.x_minus = x_minus(1);

% 'measurement', here is the first value
y(1) = handles.Region(i).Fascicle(j).fas_x{handles.UTT.frame0}(2);

% if there is a manual estimate, add a second measurement
if isfinite(handles.Region(i).Fascicle(j).fas_x_manual{frame_no}(2))
    y(2) = handles.Region(i).Fascicle(j).fas_x_manual{frame_no}(2);
    R(2) = handles.UTT.KF.R_manual;
end

% previous state covariance
s.P_prev = P_prev(1);

% a posteriori variance estimate
s.P_minus = s.P_prev + s.Q;

% run kalman filter
for ii = 1:length(y)
    
    if ii == 2
        % update
        s.x_minus = S.x_plus;
        s.P_minus = S.P_plus;
    end
    
    s.y = y(ii);
    s.R = R(ii);
    
    S = run_kalman_filter(s);   
end

% ascribe
fasx2_plus = S.x_plus;
fasx2_minus = s.x_minus;
supP_plus = S.P_plus;
supP_minus = s.P_minus;

if isinf(handles.UTT.KF.Q)
    fasx2_plus = s.y;
    supP_plus = s.R;
elseif isinf(handles.UTT.KF.X)
    fasx2_plus = s.x_minus;
    supP_plus = s.Q;
end

% Fascicle angle estimate
% get the process noise and measurement noise covariance
dx = abs(dalpha);
dx(dx<0.005) = 0;
f.Q = getQ(handles, dx);
R(1) = handles.UTT.KF.R(1);

% apriori estimate from optical flow
f.x_minus = x_minus(2);

% measurement from Hough transform
y(1) = handles.Region.Fascicle.TT.geofeatures(frame_no).alpha;

% if there is a manual estimate, add a second measurement
if isfinite(handles.Region(i).Fascicle(j).manual.fas_ang(frame_no))
    y(2) = handles.Region(i).Fascicle(j).manual.fas_ang(frame_no);
    R(2) = handles.UTT.KF.R_manual / (pi*handles.Region(i).Fascicle(j).manual.fas_length(frame_no)*handles.UTT.imHeight/handles.US.ID) * 180;
end

% previous state covariance
f.P_prev = P_prev(2);

% a posteriori variance estimate
f.P_minus = f.P_prev + f.Q;

% run kalman filter
for ii = 1:length(y)
    
    if ii == 2
        % update
        f.x_minus = F.x_plus;
        f.P_minus = F.P_plus;
    end
    
    f.y = y(ii);
    f.R = R(ii);
    
    F = run_kalman_filter(f);
    
end

% ascribe
alpha_minus = f.x_minus;
alpha_plus = F.x_plus;
fasP_plus = F.P_plus;
fasP_minus = f.P_minus;

if isinf(handles.UTT.KF.Q)
    alpha_plus = f.y;
    fasP_plus = f.R;
end

% save things
% state estimate
handles.Region(i).Fascicle(j).KF.X_plus{frame_no}  = [fasx2_plus alpha_plus];
handles.Region(i).Fascicle(j).KF.X_minus{frame_no} = [fasx2_minus alpha_minus];

% state covariance
handles.Region(i).Fascicle(j).KF.P_plus{frame_no} = [supP_plus fasP_plus];
handles.Region(i).Fascicle(j).KF.P_minus{frame_no} = [supP_minus fasP_minus];

% update deep point
deep_apo    = [handles.Region(i).deep_x{frame_no} handles.Region(i).deep_y{frame_no}];
deep_coef   = polyfit(deep_apo(:,1), deep_apo(:,2), 1);

% vertical location is fixed
fasy2 = handles.Region(i).Fascicle(j).fas_y{handles.UTT.frame0}(2);

% get the deep attachment point from the superficial point and the angle
fas_coef(1) = -tand(alpha_plus);
fas_coef(2) =  fasy2 - fas_coef(1) * fasx2_plus;

% deep
fasx1_end = (fas_coef(2) - deep_coef(2)) / (deep_coef(1) - fas_coef(1));
fasy1_end = deep_coef(2) + fasx1_end*deep_coef(1);

% update fascicle points
handles.Region(i).Fascicle(j).fas_x{frame_no}   = [fasx1_end; fasx2_plus];
handles.Region(i).Fascicle(j).fas_y{frame_no}   = [fasy1_end; fasy2];


function[handles] = update_Fascicle(handles,frame_no)
% gets fascicle tracking estimates from the state and tracked aponeuroses
i = 1;
j = 1;

% get the state
fasx2_plus = handles.Region(i).Fascicle(j).KF.X_plus{frame_no}(1);
alpha_plus = handles.Region(i).Fascicle(j).KF.X_plus{frame_no}(2);

% fit the current aponeurosis
super_apo   = [handles.Region(i).sup_x{frame_no} handles.Region(i).sup_y{frame_no}];
deep_apo    = [handles.Region(i).deep_x{frame_no} handles.Region(i).deep_y{frame_no}];
super_coef  = polyfit(super_apo(:,1), super_apo(:,2), 1);
deep_coef   = polyfit(deep_apo(:,1), deep_apo(:,2), 1);

% vertical location is fixed
fasy2 = handles.Region(i).Fascicle(j).fas_y{handles.UTT.frame0}(2);

% get the deep attachment point from the superficial point and the angle
fas_coef(1) = -tand(alpha_plus);
fas_coef(2) =  fasy2 - fas_coef(1) * fasx2_plus;

% deep
fasx1_end = (fas_coef(2) - deep_coef(2)) / (deep_coef(1) - fas_coef(1));
fasy1_end = deep_coef(2) + fasx1_end*deep_coef(1);

% superficial
fasx2_end = (fas_coef(2) - super_coef(2)) / (super_coef(1) - fas_coef(1));
fasy2_end = super_coef(2) + fasx2_end*super_coef(1);

% state and dependent variables
handles.Region(i).Fascicle(j).fas_x{frame_no}   = [fasx1_end; fasx2_end];
handles.Region(i).Fascicle(j).fas_y{frame_no}   = [fasy1_end; fasy2_end];

% calculate fascicle length and pennation
handles = calc_fascicle_length_and_pennation(handles,frame_no);


function[handles] = apo_state_estimator(handles,frame_no,prev_frame_no)

i = 1;
n = handles.UTT.imWidth;

% Apply warp
super_prev = [handles.Region(i).sup_x{prev_frame_no} handles.Region(i).sup_y{prev_frame_no}];
deep_prev = [handles.Region(i).deep_x{prev_frame_no} handles.Region(i).deep_y{prev_frame_no}];

w = handles.Region(i).UT.apo_warp(:,:,prev_frame_no);
super_new = transformPointsForward(w, super_prev);
deep_new = transformPointsForward(w, deep_prev);

apo_prev = [super_prev; deep_prev];
apo_new = [super_new; deep_new];

apo_new_y = apo_new(:,2);
apo_prev_y = apo_prev(:,2);

apo_plus = nan(size(apo_new_y));
P_plus = nan(size(apo_new_y));

apo_y = [handles.Region.Fascicle.TT.geofeatures(frame_no).super_pos'; handles.Region.Fascicle.TT.geofeatures(frame_no).deep_pos'];

% check whether manual tracking exists
if sum(isfinite(handles.Region(i).sup_y_manual{frame_no})) >= 4
    apo_y2 = [handles.Region(i).sup_y_manual{frame_no}; handles.Region(i).deep_y_manual{frame_no}];
end

Rs = handles.UTT.KF.R(2:end) * .01;

% loop over points (4)
for kk = 1:numel(apo_new_y)
    dapo = abs(apo_new_y(kk) - apo_prev_y(kk));
    
    % A priori state estimate
    x_minus = apo_new_y(kk);
    
    % State estimation superficial aponeurosis attachment
    % previous estimate covariance
    P_prev = handles.Region(i).KF.P_plus{prev_frame_no}(kk);
    
    % get the process noise and measurement noise covariance
    s.Q = getQ(handles, dapo);
    R(1) = Rs(kk);
    
    % a priori estimate from optical flow
    s.x_minus = x_minus;
    
    % 'measurement' is from TimTrack
    y(1) = apo_y(kk);
    
    if exist('apo_y2','var')
        y(2) = apo_y2(kk);
        R(2) = handles.UTT.KF.R_manual;
    end
    
    % previous state covariance
    s.P_prev = P_prev;
    
    % a posteriori variance estimate
    s.P_minus = s.P_prev + s.Q;
    
    % run kalman filter
    for ii = 1:length(y)
        
        if ii == 2
            % update
            s.x_minus = S.x_plus;
            s.P_minus = S.P_plus;
        end
        
        s.y = y(ii);
        s.R = R(ii);
        
        S = run_kalman_filter(s);
        
    end
    
    apo_plus(kk) = S.x_plus;
    P_plus(kk) = S.P_plus;
    
    if isinf(handles.UTT.KF.Q)
        apo_plus(kk) = apo_y(kk);
        P_plus(kk) = s.R;
    end
    
end

% Save things
handles.Region(i).KF.P_plus{frame_no} = P_plus;
handles.Region(i).sup_x{frame_no} = [1 n]';
handles.Region(i).sup_y{frame_no} = apo_plus(1:2);
handles.Region(i).deep_x{frame_no} = [1 n]';
handles.Region(i).deep_y{frame_no} = apo_plus(3:4);


%State estimator smoothener
function[handles] = state_smoothener(handles,frame_no,prev_frame_no)

i = 1;
j = 1;

Pcorr = handles.Region(i).Fascicle(j).KF.P_plus{frame_no};
Ppred = handles.Region(i).Fascicle(j).KF.P_minus{prev_frame_no};
Psmooth = handles.Region(i).Fascicle(j).KF.P_plus{prev_frame_no};

xcorr = handles.Region(i).Fascicle(j).KF.X_plus{frame_no};
xpred = handles.Region(i).Fascicle(j).KF.X_minus{prev_frame_no};
xsmooth = handles.Region(i).Fascicle(j).KF.X_plus{prev_frame_no};

for m = 1:2
    A           = Pcorr(m)/Ppred(m);
    A(isnan(A)) = 1;
    
    xsmooth(m)     = xcorr(m) + A*(xsmooth(m) - xpred(m));
    Psmooth(m)     = Pcorr(m) + A*(Psmooth(m) - Ppred(m))*A;
end

% overwrite previous estimates
handles.Region(i).Fascicle(j).KF.X_plus{frame_no} = xsmooth;
handles.Region(i).Fascicle(j).KF.P_plus{frame_no} = Psmooth;


function [K] = run_kalman_filter(k)
% this assumes we already have the aposteriori state estimate (k.x_minus),
% the measurement (k.y) and the process- and measurement noise covariances (k.R and k.Qvalue)

% adjust kalman gain based on measurement variance
K.K = k.P_minus / (k.P_minus + k.R);

if isnan(K.K)
    K.K = 0;
end

% check for weird gains
if (K.K < 0) || (K.K > 1)
    disp('warning: kalman gain outside 0-1 interval');
    
    K.K(K.K<0) = 0;
    K.K(K.K>1) = 1;
end

% update state
K.x_plus = k.x_minus + K.K * (k.y - k.x_minus);

% update variance
K.P_plus = (1-K.K) * k.P_minus;

function[handles] = estimate_variance(hObject, eventdata, handles)

geofeatures = handles.Region.Fascicle.TT.geofeatures;
x = nan(handles.US.NumFrames+handles.UTT.start_frame-1,5);

for f = handles.UTT.start_frame:handles.US.NumFrames+handles.UTT.start_frame-1
    x(f,1) = geofeatures(f).alpha;
    x(f,2) = geofeatures(f).super_pos(1);
    x(f,3) = geofeatures(f).super_pos(2);
    x(f,4) = geofeatures(f).deep_pos(1);
    x(f,5) = geofeatures(f).deep_pos(1);
end

Wn = 1.5*handles.UTT.KF.fc_lpf / (.5 * handles.US.FrameRate);
Wn(Wn>=1) = 1-1e-6;
Wn(Wn<=0) = 1e-6;
[b,a] = butter(2, Wn, 'high');

xcya = isnan(x(:,1));
x(xcya,:) = [];

y = nan(size(x));
if size(x,1) > 6
    for i = 1:size(x,2)
        y(:,i) = filtfilt(b,a,x(:,i));
    end
    
else
    y = x;
end

handles.UTT.KF.R = var(y) + [.1 0 0 0 0];

function[Q] = getQ(handles, dx)

% Optical flow error is proportional to flow
Q = handles.UTT.KF.Q  * dx^2;


function[handles] = calc_fascicle_length_and_pennation(handles,frame_no)
i = 1;
j = 1;

% deep aponeurosis angle
deep_apo =  [handles.Region(i).deep_x{frame_no} handles.Region(i).deep_y{frame_no}];
gamma = atan2d(-diff(deep_apo(:,2)), diff(deep_apo(:,1)));
handles.Region(i).Fascicle.UTT.fas_ang(frame_no,j) = atan2d(-diff(handles.Region(i).Fascicle(j).fas_y{frame_no}), diff(handles.Region(i).Fascicle(j).fas_x{frame_no}));
handles.Region(i).Fascicle.UTT.fas_pen(frame_no,j) = handles.Region(i).Fascicle.UTT.fas_ang(frame_no,j) - gamma;

fasx = handles.Region(i).Fascicle(j).fas_x{frame_no};
fasy = handles.Region(i).Fascicle(j).fas_y{frame_no};

handles.Region(i).Fascicle.UTT.fas_length(frame_no,j) = (handles.US.ID/handles.UTT.imHeight)*sqrt(diff(fasx).^2 + diff(fasy).^2);

fasx = handles.Region(i).Fascicle(j).fas_x_manual{frame_no};
fasy = handles.Region(i).Fascicle(j).fas_y_manual{frame_no};

handles.Region(i).Fascicle(j).manual.fas_length(frame_no,j) = (handles.US.ID/handles.UTT.imHeight)*sqrt(diff(fasx).^2 + diff(fasy).^2);
handles.Region(i).Fascicle(j).manual.fas_ang(frame_no,j) = atan2d(-diff(fasy), diff(fasx));
handles.Region(i).Fascicle(j).manual.fas_pen(frame_no,j) = atan2d(-diff(fasy), diff(fasx)) - gamma;


% --- Executes on button press in Auto_Detect.
function [handles] = Auto_Detect_Callback(hObject, eventdata, handles)
% hObject    handle to Auto_Detect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    set(handles.UTT.Bi, 'InteractionsAllowed','none')
    
    % handles.UTT.imWidth = length(handles.UTT.Bi.Position(1):(handles.UTT.Bi.Position(1)+handles.UTT.Bi.Position(3)-1));
    % handles.UTT.imHeight = length(handles.UTT.Bi.Position(2):(handles.UTT.Bi.Position(2)+handles.UTT.Bi.Position(4)-1));  
    
    % initialize
    N = handles.US.NumFrames + handles.UTT.start_frame - 1;
    n = handles.UTT.imWidth;
    i = 1;
    j = 1;
    
    %% Aponeurosis detection
    axes(handles.axes1);
    
    handles.UTT.TT.parms.apo.super.cut = ([handles.Region.S.Position(2) handles.Region.S.Position(2)+handles.Region.S.Position(4)] - handles.UTT.Bi.Position(2)) / handles.UTT.imHeight;
    handles.UTT.TT.parms.apo.deep.cut = ([handles.Region.D.Position(2) handles.Region.D.Position(2)+handles.Region.D.Position(4)] - handles.UTT.Bi.Position(2)) / handles.UTT.imHeight;

    set(handles.Region.S, 'EdgeAlpha',0,'FaceAlpha',0.1,'InteractionsAllowed','none')
    set(handles.Region.D, 'EdgeAlpha',0,'FaceAlpha',0.1,'InteractionsAllowed','none')

    % find the first frame
    frame_no = handles.UTT.start_frame + round(get(handles.frame_slider,'Value')) - 1;
    
    % % detect orientation
    B = round([1 handles.UTT.Bi.Position(2) handles.UTT.imWidth handles.UTT.Bi.Position(4)]);
    Im = handles.ImStack(B(2):(B(2)+B(4)-1), B(1):(B(1)+B(3)-1),frame_no);
    data = imresize(Im, 1/handles.UTT.TT.imresize_fac);
    
    % run TimTrack
    handles.UTT.TT.parms.fas.redo_ROI = 1;
    [geofeatures, ~, parms] = auto_ultrasound(data, handles.UTT.TT.parms);
    
    % save parms
    parms.fas.redo_ROI = 0;
    handles.UTT.TT.parms = parms;
    
    % scale
    geofeatures.thickness = geofeatures.thickness * handles.UTT.TT.imresize_fac;
    geofeatures.super_coef(2) = geofeatures.super_coef(2)     .* [handles.UTT.TT.imresize_fac];
    geofeatures.deep_coef(2) = geofeatures.deep_coef(2)       .* [handles.UTT.TT.imresize_fac];
    geofeatures.fas_coef(2) = geofeatures.fas_coef(2)         .* [handles.UTT.TT.imresize_fac];
    
    % save geofeatures
    handles.Region.Fascicle.TT.geofeatures(frame_no) = geofeatures;
    
    Deep_intersect_x = round((geofeatures.deep_coef(2) - geofeatures.fas_coef(2))   ./ (geofeatures.fas_coef(1) - geofeatures.deep_coef(1)));
    Super_intersect_x = round((geofeatures.super_coef(2) - geofeatures.fas_coef(2)) ./ (geofeatures.fas_coef(1) - geofeatures.super_coef(1)));
    Super_intersect_y = polyval(geofeatures.super_coef, Super_intersect_x);
    Deep_intersect_y = polyval(geofeatures.deep_coef, Deep_intersect_x);
    
    handles.Region(i).sup_x{frame_no} = [1 n]';
    handles.Region(i).sup_y{frame_no} = polyval(geofeatures.super_coef, [1 n]');
    
    handles.Region(i).deep_x{frame_no} = [1 n]';
    handles.Region(i).deep_y{frame_no} = polyval(geofeatures.deep_coef, [1 n]');
    
    handles.Region(i).sup_x_original{frame_no} = handles.Region(i).sup_x{frame_no};
    handles.Region(i).sup_y_original{frame_no} = handles.Region(i).sup_y{frame_no};
    handles.Region(i).deep_x_original{frame_no} = handles.Region(i).deep_x{frame_no};
    handles.Region(i).deep_y_original{frame_no} = handles.Region(i).deep_y{frame_no};
    
    handles.Region(i).UT.ROIx{frame_no} = [1 1 n n 1]';
    handles.Region(i).UT.ROIy{frame_no} = [polyval(geofeatures.super_coef, 1); polyval(geofeatures.deep_coef, [1 n]'); polyval(geofeatures.super_coef, [n 1]')];
    
    handles.Region(i).Fascicle(j).fas_x{frame_no} = [Deep_intersect_x Super_intersect_x]';
    handles.Region(i).Fascicle(j).fas_y{frame_no} = [Deep_intersect_y Super_intersect_y]';
    
    handles.Region(i).Fascicle(j).fas_x_original{frame_no} = handles.Region(i).Fascicle(j).fas_x{frame_no};
    handles.Region(i).Fascicle(j).fas_y_original{frame_no} = handles.Region(i).Fascicle(j).fas_y{frame_no};
    
    [handles] = calc_fascicle_length_and_pennation(handles,frame_no);
    
    % Update handles structure
    guidata(hObject, handles);
    
    show_image(hObject,handles);
    show_data(hObject, handles)


% --- Executes on button press in do_parfor.
function do_parfor_Callback(hObject, eventdata, handles)
% hObject    handle to do_parfor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of do_parfor
handles.do_parfor = get(hObject,'Value');

% --- Executes on button press in flipimage.
function flipimage_Callback(hObject, eventdata, handles)
% hObject    handle to flipimage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of flipimage
handles = do_flip(hObject, eventdata, handles);
%end

show_image(hObject,handles);
guidata(hObject, handles);

% ----- Function to perform flipping
function [handles] = do_flip(hObject, eventdata, handles)
% hObject    handle to do_state_estimation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles.flip = ~handles.flip;%change value of flip

if isfield(handles.UTT, "Bi")
    handles.UTT.Bi.Position(1) = handles.US.vidWidth - handles.UTT.Bi.Position(1) - handles.UTT.Bi.Position(3);
    
end

if isfield(handles,"Region")
    
    if isfield(handles.Region,'S') && isfield(handles.UTT, "Bi")
        handles.Region.S.Position(1) = handles.UTT.Bi.Position(1);
        handles.Region.D.Position(1) = handles.UTT.Bi.Position(1);
    end
    
    updateX = @(fas_x) flip(handles.UTT.imWidth - fas_x); %only here we need correction as axis starts from 1 (plotting)
    
    
    for i = 1:numel(handles.Region)
        if isfield(handles.Region(i),"ROIx") && isfield(handles.Region(i),"ROIy")
            %adjust ROI coordinates and logic mask image
            handles.Region(i).UT.ROIx = cellfun(updateX, handles.Region(i).UT.ROIx, 'UniformOutput', false);
            handles.Region(i).UT.ROIy = cellfun(@flip, handles.Region(i).UT.ROIy, 'UniformOutput', false);
        end
        
        if isfield(handles.Region(i),"deep_x") && isfield(handles.Region(i),"deep_y")
            handles.Region(i).sup_y = cellfun(@flip, handles.Region(i).sup_y , 'UniformOutput', false);
            handles.Region(i).deep_y = cellfun(@flip, handles.Region(i).deep_y , 'UniformOutput', false);
        end
        
        %adjust each fascicle's pts
        if isfield(handles.Region(i),"Fascicle")
            for j = 1:numel(handles.Region(i).Fascicle)
                handles.Region(i).Fascicle(j).fas_x = cellfun(updateX, handles.Region(i).Fascicle(j).fas_x, 'UniformOutput', false);
                handles.Region(i).Fascicle(j).fas_y = cellfun(@flip, handles.Region(i).Fascicle(j).fas_y, 'UniformOutput', false);

                if isfield(handles.Region(i).Fascicle(j),'fas_x_manual') %if estimator ran
                    if ~isempty(handles.Region(i).Fascicle(j).fas_x_manual)
                        handles.Region(i).Fascicle(j).fas_x_manual = cellfun(updateX, handles.Region(i).Fascicle(j).fas_x_manual, 'UniformOutput', false);
                        handles.Region(i).Fascicle(j).fas_y_manual = cellfun(@flip, handles.Region(i).Fascicle(j).fas_y_manual, 'UniformOutput', false);
                    end
                end
            end
        end
    end
end


% If statement not necessary, if tick flip else flip back, so everytime flipimage
% changes which depends on the callback, flip the image
%if handles.flipimage

if isfield(handles, 'ImStack')
    handles.ImStack = flip(handles.ImStack, 2);
end

% handles = AutoCrop_Callback(hObject, eventdata, handles);

% --- Function to check whether ParallelToolbox exists and run it
function chkParallelToolBox()
% First checks if Parallel Computing Toolbox exists and then
% Returns num of workers available for executing parallel computing

available_toolboxes = ver;
isexist_ParallelToolBox = false;

% Check if Parallel Computing Toolbox exists
for index = 1:size(available_toolboxes, 2)
    if convertCharsToStrings(available_toolboxes(index).Name) == "Parallel Computing Toolbox"
        isexist_ParallelToolBox = true;
        break;
    end
end

% If Parallel Computing Toolbox is available, start it if not already running
if isexist_ParallelToolBox
    if isempty(gcp('nocreate')) %if parallel is not running yet, start it
        myCluster = parcluster('Processes');
        
        % Function to start the Parallel Computing Toolbox pool
        disp('Parallel Computing Toolbox exists and it will be opened...');
        % Open parallel pool with no idle timeout
        parpool(myCluster, 'IdleTimeout', Inf);
    else
        disp('Parpool is already running!')
    end
    
end


% --- Executes when user attempts to close figure1 (i.e., using the close icon
% to close the GUI)
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check if Parallel Computing Toolbox is running and shut it down
delete(gcp('nocreate'));
% Hint: delete(hObject) closes the figure
delete(hObject);


% --------------------------------------------------------------------
function spatial_cal_Callback(hObject, eventdata, handles)
% hObject    handle to spatial_cal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'ImStack')
    
    % find current frame number from slider
    frame_no = round(get(handles.frame_slider,'Value'));
    
    % select two point for calculating the calibration mmperpx
    set(handles.axes1);
    [~,distanceInPixels]=ginputYellow(2);
    
    %create a simple dlg to type the real value
    %Ask the user for the real-world distance.
    userPrompt = {'Enter real distance in mm'};
    dialogTitle = 'Calibration';
    def = {''};
    answer = inputdlg(userPrompt, dialogTitle, 1, def);
    
    while isnan(str2double(answer{1}))  %check if it's non numeric
        answer = inputdlg(userPrompt, dialogTitle, 1, def);
    end
    %get the answer
    dist_mm = str2double(answer{1});
    
    %calculate mmperpx factor
    calibration_value = dist_mm /  abs(round(diff(distanceInPixels)));
    calibration_value = round(calibration_value,3); %round otherwise the conversion crash in the calculation (don't ask why)
    %update handles and GUI
    set(handles.ImDepthEdit,"String",string(calibration_value)); %this should automatically update the plots with Fascicle data
    ImDepthEdit_Callback(handles.ImDepthEdit, [], handles); % Manually call the callback function because it doesn't do automatically
end

% --- Executes on button press in Process_folder.
function [handles] = Process_folder_Callback(hObject, eventdata, handles)
% hObject    handle to Process_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dir_data = uigetdir(cd,'Select folder with video(s)');

if dir_data == 0 % no folder selected, just return
    return
end

cd(dir_data);
files = dir('*.mp4');

for k = 1:numel(files) %foreach file
    % First clean up some variables from any previously loaded files
    rfields = {'movObj','BIm','Bheader','ImStack','Region','crop_rect'};
    
    for j = 1:length(rfields)
        if isfield(handles, rfields{j})
            handles = rmfield(handles, rfields{j});
        end
    end

    % load video
    handles.US.fname = files(k).name;
    handles.US.pname = files(k).folder;
    
    handles = load_video(hObject, eventdata, handles);
    
    % process all based on what the ROI type is
    handles = process_all_Callback(hObject, eventdata, handles);
    
    % save
    save_video_Callback(hObject, eventdata, handles)
    Save_As_Mat_Callback(hObject, eventdata, handles)
    
end


function freq_lpf_Callback(hObject, eventdata, handles)
% hObject    handle to freq_lpf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_lpf as text
%        str2double(get(hObject,'String')) returns contents of freq_lpf as a double

handles.UTT.KF.fc_lpf = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% If we have estimates, run state estimation
if isfield(handles, 'Region')
    do_state_estimation(hObject, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function freq_lpf_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_lpf (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.UTT.KF.fc_lpf = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

function X_value_Callback(hObject, eventdata, handles)
% hObject    handle to X_value (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of X_value as text
%        str2double(get(hObject,'String')) returns contents of X_value as a double

handles.UTT.KF.X = str2double(get(hObject,'String'));

% If we have estimates, run state estimation
if isfield(handles, 'Region')
    handles = do_state_estimation(hObject, eventdata, handles);
end

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function X_value_CreateFcn(hObject, eventdata, handles)
% hObject    handle to X_value (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.UTT.KF.X = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

function resize_fac_Callback(hObject, eventdata, handles)
% hObject    handle to resize_fac (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of resize_fac as text
%        str2double(get(hObject,'String')) returns contents of resize_fac as a double

handles.UTT.TT.imresize_fac = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function resize_fac_CreateFcn(hObject, eventdata, handles)
% hObject    handle to resize_fac (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.UTT.TT.imresize_fac = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

function Qvalue_Callback(hObject, eventdata, handles)
% hObject    handle to Qvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Qvalue as text
%        str2double(get(hObject,'String')) returns contents of Qvalue as a double

handles.UTT.KF.Q = abs(str2double(get(hObject,'String')));

% If we have estimates ALL frames, run state estimation otherwise just
% update Q value
if isfield(handles, 'Region')
    if sum(~cellfun(@isempty, handles.Region.Fascicle.fas_x, 'UniformOutput', true)) >= handles.US.NumFrames
        handles = do_state_estimation(hObject, eventdata, handles);
    end
end

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function Qvalue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Qvalue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.UTT.KF.Q = abs(str2double(get(hObject,'String')));

% Update handles structure
guidata(hObject, handles);

function Nstat_Callback(hObject, eventdata, handles)
% hObject    handle to Nstat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Nstat as text
%        str2double(get(hObject,'String')) returns contents of Nstat as a double

handles.UTT.KF.NS = str2double(get(hObject,'String'));


if isfield(handles, 'Region')
    handles = do_state_estimation(hObject, eventdata, handles);
end

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function Nstat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Nstat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.UTT.KF.NS = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --------------------------------------------------------------------
function manu_set_block_size_Callback(hObject, eventdata, handles)
% hObject    handle to manu_set_block_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmp = set_block_size(handles.UTT.UT.BlockSize);


if sum(tmp ~= handles.UTT.UT.BlockSize) ~= 0 %if the Block changed, then check and run Opticflow
    
    handles.UTT.UT.BlockSize = tmp; % update blocksize according to the new values
    %re-run Optic flow automatically only if all frames were already
    %tracked
    if isfield(handles,'Region')
        
        for i = 1:length(handles.Region)
            
            %check whether all frames have been already tracked with
            %opticflow, if yes re-run it with the new block size
            if sum(~cellfun(@isempty, handles.Region.Fascicle.fas_x, 'UniformOutput', true)) >= handles.US.NumFrames
                %if size(handles.Region(i).Fascicle.analysed_frames,2) > 0 %double check this
                
                handles = process_all_UltraTrack(hObject, eventdata, handles);

                %try estimation (depending on hough tracked or not
                try
                    % State estimation
                    handles = do_state_estimation(hObject, eventdata, handles);
                catch
                    fprintf('No TimTrack, so no estimator ran\n')
                end
                % update the image and data using functions
                show_data(hObject, handles);
                show_image(hObject, handles);
            end
        end
        
    end
    % Update handles structure
    guidata(hObject, handles);
end


% --- Executes on selection change in ROI_type.
function ROI_type_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ROI_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ROI_type

ROI_options =  get(hObject,'String');
i = get(hObject, 'Value');

handles.UTT.UT.ROItype = ROI_options{i};

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function ROI_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROI_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

ROI_options =  get(hObject,'String');
i = get(hObject, 'Value');

handles.UTT.UT.ROItype = ROI_options{i};

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in SA.
function SA_Callback(hObject, eventdata, handles)
% hObject    handle to SA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Qlog = 10.^(-7:3);
Qlin1 = (1:9) * 10^-3;
Qlin2 = (1:9) * 10^-4;

Qs = [sort([Qlog Qlin1 Qlin2]) inf];

color = parula(length(Qs));

for i = 1:length(Qs)
    handles.UTT.KF.Q = Qs(i);
    
    handles = do_state_estimation(hObject, eventdata, handles);
    
    %         figure(2)
    FL(:,i) = handles.Region(i).Fascicle.UTT.fas_length(handles.UTT.start_frame:end);
    PEN(:,i) = handles.Region(i).Fascicle.UTT.fas_pen(handles.UTT.start_frame:end);
    
    % save
    Save_As_Mat_Callback(hObject, eventdata, handles)
    
end

N = size(FL,1);
dt = 1/ handles.US.FrameRate;
t = 0:dt:((N-1)*dt);

Wn = 1.5*handles.UTT.KF.fc_lpf / (.5 * handles.US.FrameRate);
Wn(Wn>=1) = 1-1e-6;
Wn(Wn<=0) = 1e-6;
[b,a] = butter(2, Wn, 'high');

PEN_low = filtfilt(b,a,PEN);
FL_low = filtfilt(b,a,FL);

% noise = [std(FL_low, 0,1); std(PEN_low, 0,1)];
noise = [mean(abs(diff(diff(FL)))); mean(abs(diff(diff(PEN))))];
drift = [abs(trapz(t, FL-FL(:,end))); abs(trapz(t, PEN-PEN(:,end)))] / max(t);

%%
if ishandle(2), close(2); end; figure(2)
subplot(521)
set(gca,'colororder',parula(length(Qs))); hold on
plot(t, FL,'linewidth',2);
xlabel('Time (s)')
ylabel('Length (mm)');
title('Fascicle length')

subplot(522)
set(gca,'colororder',parula(length(Qs))); hold on
plot(t, PEN,'linewidth',2);
xlabel('Time (s)')
ylabel('Angle (deg)');
title('Fascicle angle')

units = {'(mm)', '(deg)'};
c = 0:.1:1;
colors = cool(length(c));

for j = 1:2
    subplot(5,2,2+j);
    semilogx(Qs, drift(j,:),'linewidth',2)
    xlabel('Q value')
    ylabel(['Drift ', units(j)]);
    
    subplot(5,2,4+j);
    semilogx(Qs, noise(j,:),'linewidth',2);
    xlabel('Q value')
    ylabel(['Noise ', units(j)]);
    
    drift_n = drift ./ std(drift,1,2);
    noise_n = noise ./ std(noise,1,2);
    
    cost = c(:) * drift_n(j,1:end-1) + (1-c(:))*noise_n(j,1:end-1);
    
    [mcost, id] = min(cost, [], 2);
    
    subplot(5,2,6+j);
    set(gca,'colororder', cool(length(c)),'xscale','log'); hold on
    semilogx(Qs(1:end-1), cost,'linewidth',2); hold on
    
    for i = 1:length(c)
        semilogx(Qs(id(i)), mcost(i),'o','color',colors(i,:).^2,'markerfacecolor',colors(i,:).^2)
    end
    
    xlabel('Q value')
    ylabel('Drift + Noise');
    
    subplot(5,2,8+j)
    semilogy(c, Qs(id),'linewidth',2);
    
    xlabel('Drift weighting')
    ylabel('Optimal Q');
    
end


for i = 1:10
    subplot(5,2,i)
    box off
    axis tight
end


% --------------------------------------------------------------------
function set_Tim_Track_Callback(hObject, eventdata, handles)
% hObject    handle to set_Tim_Track (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%if the cross is pressed nothing is updated anyway
parms = adjust_hough_parameters(handles.UTT.TT.parms);
%overwrite updated TimTrack parms in the main UTT folder
filename = [mfilename,'.m'];
fullpath = which(filename);
mainfoldername = erase(fullpath,filename);
handles.UTT.TT.parms = parms;
save([mainfoldername 'TimTrack_parms.mat'],'parms');
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in manual_estimate.
function manual_estimate_Callback(hObject, eventdata, handles)
% hObject    handle to manual_estimate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'h')
    if ~isvalid(handles.h)
        handles = rmfield(handles, 'h');
    end
end
if isfield(handles,'d')
    if ~isvalid(handles.d)
        handles = rmfield(handles, 'd');
    end
end
if isfield(handles,'s')
    if ~isvalid(handles.s)
        handles = rmfield(handles, 's');
    end
end


i = 1;
j = 1;

frame_no = handles.UTT.start_frame + round(get(handles.frame_slider,'Value')) - 1;

if ~isfield(handles, 'Region')
    handles = Auto_Detect_Callback(hObject, eventdata, handles);
end

% first time "Set manual" is pushed
if ~isfield(handles, 'h') || ~isfield(handles, 'd') || ~isfield(handles, 's')
    
    Supex = handles.Region(i).sup_x{frame_no} + handles.UTT.Bi.Position(1);
    Supey = handles.Region(i).sup_y{frame_no} +  handles.UTT.Bi.Position(2);
    Deepx = handles.Region(i).deep_x{frame_no} + handles.UTT.Bi.Position(1);
    Deepy = handles.Region(i).deep_y{frame_no} +  handles.UTT.Bi.Position(2);
    Fasx = handles.Region(i).Fascicle(j).fas_x{frame_no} + handles.UTT.Bi.Position(1);
    Fasy = handles.Region(i).Fascicle(j).fas_y{frame_no} + handles.UTT.Bi.Position(2);


    axes(handles.axes1)
    handles.h = drawline('Position', [Fasx(1) Fasy(1); Fasx(2) Fasy(2)], 'color', 'red', 'linewidth',2,'StripeColor','w');
    handles.s = drawline('Position', [Supex(1) Supey(1); Supex(2) Supey(2)], 'color', 'blue', 'linewidth',2,'StripeColor','w');
    handles.d = drawline('Position', [Deepx(1) Deepy(1); Deepx(2) Deepy(2)], 'color', 'green', 'linewidth',2,'StripeColor','w');

else  % second time "Set manual" is pushed

    handles = extract_estimates(hObject, eventdata, handles);

    % if the first or last frame or in TimTrack mode, accept manual tracking
    if frame_no == handles.UTT.frame0 || handles.TimTrack_mode.Value
        handles.Region(i).Fascicle(j).fas_x{frame_no} = handles.Region(i).Fascicle(j).fas_x_manual{frame_no};
        handles.Region(i).Fascicle(j).fas_y{frame_no} = handles.Region(i).Fascicle(j).fas_y_manual{frame_no};

        handles.Region(i).sup_x{frame_no} = handles.Region(i).sup_x_manual{frame_no};
        handles.Region(i).sup_y{frame_no} = handles.Region(i).sup_y_manual{frame_no};

        handles.Region(i).deep_x{frame_no} = handles.Region(i).deep_x_manual{frame_no};
        handles.Region(i).deep_y{frame_no} = handles.Region(i).deep_y_manual{frame_no};

    end

    handles = calc_fascicle_length_and_pennation(handles,frame_no);

    if ~handles.TimTrack_mode.Value
        try
            handles = do_state_estimation(hObject, eventdata, handles);
        catch
            disp('Estimation avaiable only with ROI Type "Hough - Local" or "Hough - global"')
        end
    else
        [handles] = minimize_extrapolation(hObject, eventdata, handles);
        handles.Region(i).Fascicle(j).fas_x_manual{frame_no} = handles.Region(i).Fascicle(j).fas_x{frame_no};
        handles.Region(i).Fascicle(j).fas_y_manual{frame_no} = handles.Region(i).Fascicle(j).fas_y{frame_no};
    end

    delete(handles.h)
    delete(handles.d)
    delete(handles.s)

    handles = rmfield(handles, 'h');
    handles = rmfield(handles, 'd');
    handles = rmfield(handles, 's');
end

show_data(hObject, handles);
show_image(hObject, handles);

guidata(hObject, handles);

    
function [handles] = extract_estimates(hObject, eventdata, handles)

i = 1;
j = 1;
frame_no = handles.UTT.start_frame + round(get(handles.frame_slider,'Value')) - 1;

handles.Region(i).sup_x_manual{frame_no} = handles.s.Position(:,1) - handles.UTT.Bi.Position(1);
handles.Region(i).sup_y_manual{frame_no} = handles.s.Position(:,2) - handles.UTT.Bi.Position(2);

handles.Region(i).deep_x_manual{frame_no} = handles.d.Position(:,1) - handles.UTT.Bi.Position(1);
handles.Region(i).deep_y_manual{frame_no} = handles.d.Position(:,2) - handles.UTT.Bi.Position(2);

handles.Region(i).ROIx_manual{frame_no} = [handles.s.Position(1,1); handles.d.Position([1 2],1); handles.s.Position([2 1],1)] - handles.UTT.Bi.Position(1);
handles.Region(i).ROIy_manual{frame_no} = [handles.s.Position(1,2); handles.d.Position([1 2],2); handles.s.Position([2 1],2)] - handles.UTT.Bi.Position(2);

handles.Region(i).Fascicle(j).fas_x_manual{frame_no} = handles.h.Position(:,1) - handles.UTT.Bi.Position(1);
handles.Region(i).Fascicle(j).fas_y_manual{frame_no} = handles.h.Position(:,2) - handles.UTT.Bi.Position(2);

handles = calc_fascicle_length_and_pennation(handles,frame_no);

% Update handles structure
guidata(hObject, handles);


function manual_variance_Callback(hObject, eventdata, handles)
% hObject    handle to manual_variance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of manual_variance as text
%        str2double(get(hObject,'String')) returns contents of manual_variance as a double

handles.UTT.KF.R_manual = abs(str2double(get(hObject,'String')));

try
    handles = do_state_estimation(hObject, eventdata, handles);
catch
    disp('No tracking yet')
end

show_data(hObject, handles);
show_image(hObject, handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function manual_variance_CreateFcn(hObject, eventdata, handles)
% hObject    handle to manual_variance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.UTT.KF.R_manual = abs(str2double(get(hObject,'String')));

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in clear_manual.
function [handles] = clear_manual_Callback(hObject, eventdata, handles)
% hObject    handle to clear_manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

i = 1;
j = 1;

N = handles.US.NumFrames + handles.UTT.start_frame - 1;
handles.Region(i).Fascicle(j).manual.fas_length    = nan(N,1);
handles.Region(i).Fascicle(j).manual.fas_pen       = nan(N,1);

rmfields = {'sup_x_manual', 'sup_y_manual','deep_x_manual','deep_y_manual','ROIx_manual','ROIy_manual','fas_ang_manual'};
for k = 1:length(rmfields)
    handles.Region(i).(rmfields{k}) = [];
end

rmfields = {'fas_x_manual','fas_y_manual'};
for k = 1:length(rmfields)
    handles.Region(i).Fascicle(j).(rmfields{k}) = [];
end

show_data(hObject, handles);
show_image(hObject, handles);

try
    handles = do_state_estimation(hObject, eventdata, handles);
catch
    disp('No tracking yet')
end

% Update handles structure
guidata(hObject, handles);


% --------------------------------------------------------------------
function Spatial_calibration_Callback(hObject, eventdata, handles)
% hObject    handle to Spatial_calibration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%just grub the shown frame even tho it's not strictly necessary for
%calibration, any frame would be fine (Ideally people don't change setting
%during a recording).

if isfield(handles,'ImStack')
    % find current frame number from slider
    frame_no = round(get(handles.frame_slider,'Value'));
    
    %msgbox('Please click twice to define length on the image')
    % select two point for calculating the calibration mmperpx
    set(handles.axes1);
    [~,distanceInPixels]=ginputYellow(2);
    
    %create a simple dlg to type the real value
    %Ask the user for the real-world distance.
    userPrompt = {'Enter real distance in mm'};
    dialogTitle = 'Calibration';
    def = {''};
    answer = inputdlg(userPrompt, dialogTitle, 1, def);
    
    while isnan(str2double(answer{1}))  %check if it's non numeric
        answer = inputdlg(userPrompt, dialogTitle, 1, def);
    end
    %get the answer
    dist_mm = str2double(answer{1});
    
    %calculate mmperpx factor
    calibration_value = dist_mm /  abs(round(diff(distanceInPixels)));
    calibration_value = round(calibration_value,3); %round otherwise the conversion crash in the calculation (don't ask why)
    
    ImDepth = handles.UTT.imHeight .* calibration_value; %calculate img_depth
    %update handles and GUI
    set(handles.ImDepthEdit,"String",string(ImDepth)); %this should automatically update the plots with Fascicle data
    ImDepthEdit_Callback(handles.ImDepthEdit, [], handles); % Manually call the callback function because it doesn't do automatically, this also updates the field and the plot
else
    warndlg('No video loaded')
end


% --- Executes during object creation, after setting all properties.
function trackbck_chkBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trackbck_chkBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

i = get(hObject, 'Value');

if i == 0
    handles.UTT.frame0 = 1;
    handles.UTT.direction = 1; % forward direction
else
    handles.UTT.frame0 = handles.US.NumFrames;
    handles.UTT.direction = -1; % backward direction
end

% Update handles structure
guidata(hObject, handles);
    

% --- Executes on button press in trackbck_chkBox.
function trackbck_chkBox_Callback(hObject, eventdata, handles)
% hObject    handle to trackbck_chkBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~handles.trackbck_chkBox.Value
    handles.UTT.frame0 = handles.UTT.start_frame;
    handles.UTT.direction = 1; % forward direction
else
    handles.UTT.frame0 = handles.UTT.start_frame + handles.US.NumFrames - 1;
    handles.UTT.direction = -1; % backward direction
end


% Update handles structure
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of trackbck_chkBox


% --------------------------------------------------------------------
function menu_load_images_Callback(hObject, eventdata, handles)
% hObject    handle to menu_load_images (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% First clean up some variables from any previously loaded files
if isfield(handles,'movObj')
    %handles = rmfield(handles,'mov');
    handles = rmfield(handles,'movObj');
end
if isfield(handles,'BIm')
    handles=rmfield(handles,'BIm');
    handles=rmfield(handles,'Bheader');
end

if isfield(handles,'ImStack')
    handles=rmfield(handles,'ImStack');
end

if isfield(handles,'Region')
    handles = rmfield(handles,'Region');
end

dir_data = uigetdir(cd,'Select folder with images(s)');

if dir_data == 0 %no folder selected, just return
    return
end

files = dir(dir_data);

image_formats = {'.b32';'.b8';'.mat';'.jpg';'.png';'.bmp';'.jpeg';'.tiff'};% add some options that we can use

ind_toRemove = [];
for n_file = 1 : numel(files)
    [~,~,ext] = fileparts(files(n_file).name);
    %save indexes of thefile that are not videos
    if sum(strcmp(image_formats,ext)) == 0
        ind_toRemove = [ind_toRemove n_file];
    end
end

files(ind_toRemove) = []; %keep images

for k = 1:numel(files) %foreach file
    
    handles.US.fname = files(k).name;
    handles.US.pname = [files(k).folder,'/'];
    handles.UTT.start_frame = 1;
    cd(handles.US.pname)
    
    imgRGB = imread([handles.US.pname handles.US.fname]);
    
    if size(imgRGB,3)>1
        img = rgb2gray(imgRGB);
    else
        img = imgRGB;
    end
    
    handles.ImStack(:,:,k) = img;
    
end

handles.US.vidHeight = size(handles.ImStack,1);
handles.US.vidWidth = size(handles.ImStack,2);
handles.US.NumFrames = size(handles.ImStack,3);

handles = AutoCrop_Callback(hObject, eventdata, handles);

% crop
% handles = AutoCrop_Callback(hObject, eventdata, handles);

% display the path and name of the file in the filename text box
set(handles.filename,'String',[handles.US.pname handles.US.fname])

% set the string in the frame_number box to the current frame value (1)
set(handles.frame_number,'String',num2str(1))

% allows Cut_frames_before_Callback to work
handles.UTT.start_frame = 1;

% arbitrary
handles.US.FrameRate = 100;

% set the limits on the slider - use number of frames to set maximum (min =
% 1)
set(handles.frame_slider,'Min',1);
set(handles.frame_slider,'Max',handles.US.NumFrames);
set(handles.frame_slider,'Value',1);
set(handles.frame_slider,'SliderStep',[1/handles.US.NumFrames 10/handles.US.NumFrames]);
set(handles.frame_rate,'String',handles.US.FrameRate(1))
set(handles.vid_width,'String',handles.US.vidWidth(1))
set(handles.vid_height,'String',handles.US.vidHeight(1))

% use TimTrack mode (assuming images are independent)
set(handles.TimTrack_mode, 'Value', 1);

% update the image axes using show_image function (bottom)
show_data(hObject, handles);

handles = menu_clear_tracking_Callback(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);

% update the image axes using show_image function (bottom)
show_image(hObject, handles);


% --- Executes on button press in TimTrack_mode.
function TimTrack_mode_Callback(hObject, eventdata, handles)
% hObject    handle to TimTrack_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TimTrack_mode
% [handles] = minimize_extrapolation(hObject, eventdata, handles);

% update the image axes using show_image function (bottom)
show_data(hObject, handles);

% update the image axes using show_image function (bottom)
show_image(hObject, handles);

% Update handles structure
guidata(hObject, handles);

function[handles] = minimize_extrapolation(hObject, eventdata, handles)

n = handles.US.NumFrames;
m = handles.UTT.imWidth;
i = 1;

for frame_no = 1:n
    
    super_apo   = [handles.Region(i).sup_x{frame_no} handles.Region(i).sup_y{frame_no}];
    deep_apo    = [handles.Region(i).deep_x{frame_no} handles.Region(i).deep_y{frame_no}];
    super_coef  = polyfit(super_apo(:,1), super_apo(:,2), 1);
    deep_coef   = polyfit(deep_apo(:,1), deep_apo(:,2), 1);
    
    Mx = round(m/2);
    My = mean([polyval(deep_coef, Mx) polyval(super_coef, Mx)]);
    
    alpha =  handles.Region.Fascicle.UTT.fas_ang(frame_no);
    
    fas_coef(1) = -tand(alpha);
    fas_coef(2) =  My - Mx * fas_coef(1);
    
    x = round(fzero(@(x) polyval(deep_coef(:)-fas_coef(:),x),0));
    
    % extract variables
    beta = -atan2d(super_coef(1),1);
    T = (polyval(deep_coef,x) - polyval(super_coef,x)) * cosd(beta);
    faslen =  T ./ sind(alpha-beta);
    
    apo_intersect = [x                           polyval(deep_coef,x);
        x + faslen * cosd(alpha)     polyval(super_coef,x + faslen * cosd(alpha))];
    
    handles.Region.Fascicle.fas_x{frame_no} = apo_intersect(:,1);
    handles.Region.Fascicle.fas_y{frame_no} = apo_intersect(:,2);
    
    handles = calc_fascicle_length_and_pennation(handles,frame_no);
    
end


function [I_fmasked, I_amasked] = get_masked_image(im, f, handles)

    % make a copy
    I_fmasked = im;
    I_amasked = im;
    im1 = im;
    
    i = 1;
    m = handles.UTT.imHeight;

    % if Hough local, get mask from Hough
    if isfield(handles.Region.Fascicle.TT,'geofeatures') && strcmp(handles.UTT.UT.ROItype, 'Hough - local')
        M = zeros(size(im1,1), size(im1,2), handles.UTT.TT.parms.fas.npeaks);

        for j = 1:handles.UTT.TT.parms.fas.npeaks
            x1 = handles.Region.Fascicle.TT.geofeatures(f).x(j,1) * handles.UTT.TT.imresize_fac;
            y1 = handles.Region.Fascicle.TT.geofeatures(f).y(j,1) * handles.UTT.TT.imresize_fac;

            x2 = handles.Region.Fascicle.TT.geofeatures(f).x(j,2) * handles.UTT.TT.imresize_fac;
            y2 = handles.Region.Fascicle.TT.geofeatures(f).y(j,2) * handles.UTT.TT.imresize_fac;

            dy = 5; % pixels around fascicle line

            ROIx = [x1 x1 x2 x2 x1];
            ROIy = [y1-dy y1+dy y2+dy y2-dy y1-dy]';

            if sum(isfinite(ROIx)) == length(ROIx) && sum(isfinite(ROIy)) == length(ROIy)
                M(:,:,j) = poly2mask(ROIx,ROIy, size(im1,1), size(im1,2));
            end
        end

        % mask
        fmask = sum(M,3);
        fmask(fmask>1) = 1;

        I_fmasked(fmask~=1) = 0;
    end

    % if Hough-based ROI, get current ROI from Hough
    if contains(handles.UTT.UT.ROItype, 'Hough')

        % get ROI
        ROIy = handles.Region(i).UT.ROIy{f};
        ROIx = handles.Region(i).UT.ROIx{f};
        
        % mask
        fmask = poly2mask(ROIx, ROIy, size(im,1), size(im,2));
        I_fmasked(fmask~=1) = 0;

        s = handles.UTT.TT.parms.apo.super.cut;
        ROIys = [s(1) s(2) s(2) s(1) s(1)] * m;

        d = handles.UTT.TT.parms.apo.deep.cut;
        ROIyd = [d(1) d(2) d(2) d(1) d(1)] * m;

        dmask =  poly2mask(ROIx, ROIyd, size(im,1), size(im,2));
        smask =  poly2mask(ROIx, ROIys, size(im,1), size(im,2));

        amask = dmask + smask;
        amask(amask > 1) = 1;
        I_amasked(amask~=1) = 0;
    end
    
    
function[handles] = PreAllocate_Tracking(hObject, eventdata, handles)

i = 1;
j = 1;

for f = 1:handles.US.NumFrames
    handles.Region(i).sup_x{f} = nan(2,1);
    handles.Region(i).sup_y{f} = nan(2,1);
    handles.Region(i).deep_x{f} = nan(2,1);
    handles.Region(i).deep_y{f} = nan(2,1);
    
    handles.Region(i).sup_x_original{f} = nan(2,1);
    handles.Region(i).sup_y_original{f} = nan(2,1);
    handles.Region(i).deep_x_original{f} = nan(2,1);
    handles.Region(i).deep_y_original{f} = nan(2,1);
    
    handles.Region(i).sup_x_manual{f} = nan(2,1);
    handles.Region(i).sup_y_manual{f} = nan(2,1);
    handles.Region(i).deep_x_manual{f} = nan(2,1);
    handles.Region(i).deep_y_manual{f} = nan(2,1);
    
    handles.Region(i).UT.ROIx{f} = nan(5,1);
    handles.Region(i).UT.ROIy{f} = nan(5,1);
    handles.Region(i).UT.fas_points{f} = nan(5,2);
    
    handles.Region(i).Fascicle(j).fas_x{f} = nan(2,1);
    handles.Region(i).Fascicle(j).fas_y{f} = nan(2,1);
    handles.Region(i).Fascicle(j).fas_x_original{f} = nan(2,1);
    handles.Region(i).Fascicle(j).fas_y_original{f} = nan(2,1);
    
    handles.Region(i).Fascicle(j).fas_x_manual{f} = nan(2,1);
    handles.Region(i).Fascicle(j).fas_y_manual{f} = nan(2,1);
    
end

handles.Region(i).Fascicle(j).UTT.fas_length = nan(handles.US.NumFrames,1);
handles.Region(i).Fascicle(j).UTT.fas_pen = nan(handles.US.NumFrames,1);
handles.Region(i).Fascicle(j).UTT.fas_ang = nan(handles.US.NumFrames,1);


handles.Region(i).Fascicle(j).manual.fas_length = nan(handles.US.NumFrames,1);
handles.Region(i).Fascicle(j).manual.fas_pen = nan(handles.US.NumFrames,1);
handles.Region(i).Fascicle(j).manual.fas_ang = nan(handles.US.NumFrames,1);




% --- Executes on button press in cut_frames_before.
function cut_frames_before_Callback(hObject, eventdata, handles)
% hObject    handle to cut_frames_before (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'movObj')||isfield(handles,'BIm')||isfield(handles,'ImStack')
    
    % reset start_frame to the current frame and adjust NumFrames
    handles.UTT.start_frame = handles.UTT.start_frame + round(get(handles.frame_slider,'Value'));
    handles.US.NumFrames = handles.US.NumFrames-handles.UTT.start_frame+1;

    if ~handles.trackbck_chkBox.Value
        handles.UTT.frame0 = handles.UTT.start_frame;
    else
        handles.UTT.frame0 = handles.UTT.start_frame + handles.US.NumFrames - 1;
    end
    
    handles.US.Time = handles.US.Time(handles.UTT.start_frame:handles.UTT.start_frame + handles.US.NumFrames-1);
    
    set(handles.frame_slider,'Min',1);
    set(handles.frame_slider,'Max',handles.US.NumFrames);
    set(handles.frame_slider,'Value',1);
    set(handles.frame_slider,'SliderStep',[1/handles.US.NumFrames 5/handles.US.NumFrames]);
    
    % set the string in the frame_number to 1
    set(handles.frame_number,'String',1);
    
    % update the image axes using show_image function (bottom)
    show_image(hObject,handles);
end

% --- Executes on button press in cut_frames_after.
function cut_frames_after_Callback(hObject, eventdata, handles)
% hObject    handle to cut_frames_after (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'movObj')||isfield(handles,'BIm')||isfield(handles,'ImStack')
    frame_no = round(get(handles.frame_slider,'Value'));
    
    handles.US.NumFrames = frame_no;
    
    if ~handles.trackbck_chkBox.Value
        handles.UTT.frame0 = handles.UTT.start_frame;
        handles.UTT.direction = 1; % forward direction
    else
        handles.UTT.frame0 = handles.UTT.start_frame + handles.US.NumFrames - 1;
        handles.UTT.direction = -1; % backward direction
    end

    set(handles.frame_slider,'Min',1);
    set(handles.frame_slider,'Max',handles.US.NumFrames);
    set(handles.frame_slider,'Value',handles.US.NumFrames);
    set(handles.frame_slider,'SliderStep',[1/handles.US.NumFrames 5/handles.US.NumFrames]);
    
    % set the string in the frame_number to 1
    set(handles.frame_number,'String',frame_no);
    
    % update the image axes using show_image function (bottom)
    show_image(hObject,handles);
end

% --- Executes on slider movement.
function frame_slider_Callback(hObject, eventdata, handles)
% hObject    handle to frame_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get the current value from the slider (round to ensure it is integer)
frame_no = round(get(handles.frame_slider,'Value'));

% set the string in the frame_number box to the current frame value
set(handles.frame_number,'String',num2str(frame_no));

% update the image axes using show_image function (bottom)
show_image(hObject,handles);

% --- Executes during object creation, after setting all properties.
function frame_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frame_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function frame_number_Callback(hObject, eventdata, handles)
% hObject    handle to frame_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frame_number as text
%        str2double(get(hObject,'String')) returns contents of frame_number as a double

frame_no = str2num(get(handles.frame_number,'String'));
set(handles.frame_slider,'Value',round(frame_no));

% update the image axes using show_image function (bottom)
show_image(hObject,handles);

% --- Executes during object creation, after setting all properties.
function frame_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frame_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function File_Callback(hObject, eventdata, handles)
% hObject    handle to File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Image_Callback(hObject, eventdata, handles)
% hObject    handle to Image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Tracking_Callback(hObject, eventdata, handles)
% hObject    handle to Tracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Fascicle_Callback(hObject, eventdata, handles)
% hObject    handle to Fascicle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Settings_Callback(hObject, eventdata, handles)
% hObject    handle to Settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function save_settings_Callback(hObject, eventdata, handles)
% hObject    handle to save_settings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ImageDepth = handles.US.ID;
Position = get(gcf,'Position');
Default_Directory = cd;

[directory, ~, ~] = fileparts(mfilename('fullpath'));

save(fullfile(directory, 'ultrasound_tracking_settings.mat'), 'ImageDepth', ...
    'Position', 'Default_Directory');

msgbox('Settings saved')

% --------------------------------------------------------------------
function[handles] = menu_clear_tracking_Callback(hObject, eventdata, handles)
% hObject    handle to menu_clear_tracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'ImStack')
    
    if isfield(handles,'Region')
        handles = rmfield(handles,'Region');
    end
 
    % set current frame to 1
    set(handles.frame_slider,'Value',1);
    set(handles.frame_number,'String',1);
    
    % clear axes
    cla(handles.length_plot)
    cla(handles.mat_plot)
    cla(handles.axes1) %clean image data
    
    % save .S and .D
%     show_image(hObject,handles);
    
    % Update handles structure
    guidata(hObject, handles);
    
end





