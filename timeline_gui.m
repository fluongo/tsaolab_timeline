function varargout = timeline_gui(varargin)
% TIMELINE_GUI MATLAB code for timeline_gui.fig
%      TIMELINE_GUI, by itself, creates a new TIMELINE_GUI or raises the existing
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

% Last Modified by GUIDE v2.5 03-Jul-2018 18:27:37

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
% varargin   command line arguments to timeline_gui (see VARARGIN)

% Choose default command line output for timeline_gui
handles.output = hObject;

daqreset
try
    handles.s = daq.createSession('ni');
    handles.nChannels_to_use = 8;
    [ch, idx] = addAnalogInputChannel(handles.s,'Dev4',0:handles.nChannels_to_use-1,'Voltage');
catch
    handles.s = daq.createSession('mcc');
    handles.nChannels_to_use = 8;
    [ch, idx] = addAnalogInputChannel(handles.s,'Board0',0:handles.nChannels_to_use-1,'Voltage');

end
handles.s.Rate = 5000;
handles.s.DurationInSeconds = 200;


for i = 1:length(idx)
    ch(idx(i)).TerminalConfig = 'SingleEnded'
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes timeline_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


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
dir_to_write = pwd;
handles.log_fn = fullfile(dir_to_write, sprintf('test_%s.bin', datestr(now,'mm-dd-yyyy HH-MM')));
handles.timestamps_fn = [handles.log_fn(1:end-4), '_ts.bin']

handles.fid_data = fopen(handles.log_fn,'w');
handles.fid_ts = fopen(handles.timestamps_fn,'w');

handles.s.NotifyWhenDataAvailableExceeds =3*5000;
handles.lh = addlistener(handles.s,'DataAvailable', @(src,event) quick_plot_sub(event.TimeStamps, event.Data, handles));
handles.lh2 = addlistener(handles.s,'DataAvailable',@(src, event)log_data_sub(src, event, handles.fid_data, handles.fid_ts));

handles.s.IsContinuous = true;
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

function log_data_sub(src, evt, fid_data, fid_ts)
% Add the time stamp and the data values to data. To write data sequentially,
% transpose the matrix.

% Write the data with low precision and the timestamps with high..
% Remember to transpose data so it is read out appropriately..
fwrite(fid_data,evt.Data','uint8');
fwrite(fid_ts, evt.TimeStamps, 'double');

% --- Executes on button press in stop_button.
function stop_button_Callback(hObject, eventdata, handles)
% hObject    handle to stop_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.s.stop;
delete(handles.lh);delete(handles.lh2)
fclose(handles.fid_data);fclose(handles.fid_ts);

% Update handles structure
guidata(hObject, handles);

