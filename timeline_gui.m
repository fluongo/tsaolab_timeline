function varargout = timeline_gui(varargin)
% TIMELINE_GUI MATLAB code for timeline_gui.fig
%      TIMELINE_GUI, by itself, creates a new TIMELINdsaE_GUI or raises the existing
%      singleton*.
%
%      H = TIMELINE_GUI returns the handle to a new TIMELINE_GUI or the handle to
%      the existing singleton*.
%
%      TIMELINE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TIMELINE_GUI.M with the given input arguments.
%
%      TIMELINE_GUI('Property','Value',...) creates a new TIMELINE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before timeline_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to timeline_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help timeline_gui

% Last Modified by GUIDE v2.5 04-Dec-2018 18:07:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @timeline_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @timeline_gui_OutputFcn, ...
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


% --- Executes just before timeline_gui is made visible.
function timeline_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ti  meline_gui (see VARARGIN)

% Choose default command line output for timeline_gui
handles.output = hObject;

try
    handles.s = daq.createSession('ni');
    handles.device_type = 'ni';
catch
    handles.s = daq.createSession('mcc');
    handles.device_type = 'mcc';
end

% Set the save directory
handles.save_dir = uigetdir('SELECT THE SAVE DIRECTORY');
cd(handles.save_dir)
set(handles.text_savedir, 'String', handles.save_dir)


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes timeline_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function open_udp_server(hObject, eventdata, handles)
% Opens the udp server
try
    disp('here')
    set(handles.text_prev_msg, 'String', 'NEW SESSION')
    global sb_server
    sb_server=udp('localhost', 'LocalPort', 7000);
    fopen(sb_server);
    % Clear any old messages otherwise they get appended to first message
    if sb_server.BytesAvailable > 0
        disp('clearing old messages')
        tmp = fgetl(sb_server);
    end
    
    % For keeping server messages
    global messages messages_count
    messages_count = 0;
    messages = [];
    guidata(hObject, handles);
    disp('Succesfully opened server on port 7000')
catch
    disp('ERROR: Could not open udp server')
end

function close_udp_server(hObject, eventdata, handles)
try 
    global sb_server
    fclose(sb_server)
    disp('successfully closed udp server')
catch
    disp('ERROR: Could not close udp server')
end


function read_udp_server(handles)
% Handles incoming messages  
global messages messages_count sb_server

if sb_server.BytesAvailable > 0
    m = fgetl(sb_server);
    if messages_count == 0
        disp(fprintf('Received message || %s || at time 3.2%f seconds after start', m, toc))
        messages.m = m;
        messages.t = toc;
        messages_count = messages_count+2;
    else
        disp(fprintf('Received message || %s || at time 3.2%f seconds after start', m, toc))
        messages(messages_count).m = m;
        messages(messages_count).t = toc;
        messages_count = messages_count+1;
    end
    % Update the box
    set(handles.text_prev_msg, 'String', char(messages.m));
end


% --- Outputs from this function are returned to the command line.
function varargout = timeline_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start_button.
function start_button_Callback(hObject, eventdata, handles)
% hObject    handle to start_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Initialize the channels in the session that will need to be used here....


% Initialize the session
daqreset
handles.s = daq.createSession(handles.device_type);
tmp = daq.getDevices;
handles.device_id = tmp.ID;
handles.nChannels_to_use = str2num(get(handles.n_chan_record, 'String'));
[ch, idx] = addAnalogInputChannel(handles.s,handles.device_id,0:handles.nChannels_to_use-1,'Voltage');

% Set the rate to distribute all channels
handles.s.Rate = floor(40/length(idx))*1000;
handles.s.IsContinuous = true;

for i = 1:length(idx)
    ch(idx(i)).TerminalConfig = 'SingleEnded';
end

% Open the udp server
open_udp_server(hObject, eventdata, handles)

handles.fn_sub = sprintf('timeline_%s', datestr(now,'mm-dd-yyyy_HH-MM'));
% Set write directory and make
handles.dir_write = fullfile(handles.save_dir, handles.fn_sub);
mkdir(handles.dir_write); % Make directory
set(handles.text_savefn, 'String', handles.fn_sub); % Update the directory

handles.log_fn = fullfile(handles.dir_write, [handles.fn_sub, '.bin']);
handles.timestamps_fn = [handles.log_fn(1:end-4), '_ts.bin'];

handles.fid_data = fopen(handles.log_fn,'w');
handles.fid_ts = fopen(handles.timestamps_fn,'w');

handles.s.NotifyWhenDataAvailableExceeds =3*handles.s.Rate; % Make this 3 seconds each time
handles.lh = addlistener(handles.s,'DataAvailable', @(src,event) quick_plot_sub(event.TimeStamps, event.Data, handles));
handles.lh2 = addlistener(handles.s,'DataAvailable',@(src, event)log_data_sub(src, event, handles.fid_data, handles.fid_ts, handles));

% Initiate tic..
tic
handles.is_running = 1;
handles.s.startBackground;


% Update handles structure
guidata(hObject, handles);

function [outputArg1,outputArg2] = quick_plot_sub(x,y, handles)
%QUICK_PLOT Summary of this function goes here
%   Detailed explanation goes here

nChannels = size(y, 2);
rng(1);colors = rand(8, 3);
for i = 1:nChannels
    plot(handles.(sprintf('axes%d', i)), x, y(:,i), 'Color',colors(i,:));
    %title(sprintf('Channel %d', i)); ylim([-0.5 5.5])
end

% Do a quick read of the server and update messages...\
read_udp_server(handles)

function log_data_sub(src, evt, fid_data, fid_ts, handles)
% Add the time stamp and the data values to data. To write data sequentially,
% transpose the matrix.

% Write the data with low precision and the timestamps with high..
% Remember to transpose data so it is read out appropriately..
fwrite(fid_data,evt.Data','single');
fwrite(fid_ts, evt.TimeStamps, 'double');

% Update elapsed time for experiment..
e_time = round(toc);
set(handles.text_elapsed_exp_time, 'String', sprintf('Elapsed experimental time is %d minutes and %d seconds, recording %d channels at %d Hz', ...
    floor(e_time/60), mod(e_time, 60) , handles.nChannels_to_use, handles.s.Rate) )



% --- Executes on button press in stop_button.
function stop_button_Callback(hObject, eventdata, handles)
% hObject    handle to stop_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.s.stop;

% Tell the sensor to stop acquiring in case it still is...
handles.is_running = 1;
guidata(hObject, handles);


delete(handles.lh);delete(handles.lh2)
fclose(handles.fid_data);fclose(handles.fid_ts);

% Close the udp server
close_udp_server(hObject, eventdata, handles)


% Read in the data and Save as .mat
disp('LOADING IN DATA....')
fid2 = fopen(handles.log_fn,'r');
[data,~] = fread(fid2,[handles.nChannels_to_use,inf],'single');
data = single(data);
fclose(fid2);

fid2 = fopen(handles.timestamps_fn,'r');
[timestamps,~] = fread(fid2,[1,inf],'double');
fclose(fid2);

% Load in the labels callback
labels = cell(1, handles.nChannels_to_use);
for i = 1:handles.nChannels_to_use
    labels{i} = get(handles.(sprintf('edit%d', i)), 'String');
end

global messages

disp('WRITING DATA TO MAT FILE....')
save(fullfile(handles.dir_write, [handles.fn_sub, '.mat']), 'timestamps', 'data', 'labels', 'messages', '-v7.3')
disp('DONE WRITING DATA TO MAT FILE.....')

% Update handles structure
guidata(hObject, handles);



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit7_Callback(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in running_checkbox.
function running_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to running_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.running_checkbox, 'Value') == 1
    disp('Connecting to sensor')
    handles.m = MotionSensor(get(handles.adns_port, 'String'));
    guidata(hObject, handles);
else
    disp('disabling sensor')
    handles.m.delete
    guidata(hObject, handles);
end
% Hint: get(hObject,'Value') returns toggle state of running_checkbox



function adns_port_Callback(hObject, eventdata, handles)
% hObject    handle to adns_port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% Hints: get(hObject,'String') returns contents of adns_port as text
%        str2double(get(hObject,'String')) returns contents of adns_port as a double


% --- Executes during object creation, after setting all properties.
function adns_port_CreateFcn(hObject, eventdata, handles)
% hObject    handle to adns_port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function n_chan_record_Callback(hObject, eventdata, handles)
% hObject    handle to n_chan_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of n_chan_record as text
%        str2double(get(hObject,'String')) returns contents of n_chan_record as a double


% --- Executes during object creation, after setting all properties.
function n_chan_record_CreateFcn(hObject, eventdata, handles)
% hObject    handle to n_chan_record (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
