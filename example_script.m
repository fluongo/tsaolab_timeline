% Initial script for interfacing between MC 1208-fs DAQ, whicvh will allow
% the sampling of 8 analog signals at 5000Hz
clear all
devices = daq.getDevices

%% Single Channel example...
clear all
daqreset
s = daq.createSession('mcc');
s.Rate = 5000;
s.DurationInSeconds = 200;

nChannels_to_use = 8;

[ch, idx] = addAnalogInputChannel(s,'Board0',0:nChannels_to_use-1,'Voltage');

for i = 1:length(idx)
    ch(idx(i)).TerminalConfig = 'SingleEnded'
end

%%

log_fn = 'c:\Users\ernie\Desktop\log7_test.bin'
timestamps_fn = [log_fn(1:end-4), '_ts.bin']

fid_data = fopen(log_fn,'w');
fid_ts = fopen(timestamps_fn,'w');

s.NotifyWhenDataAvailableExceeds =2*5000;
lh = addlistener(s,'DataAvailable', @(src,event) quick_plot(event.TimeStamps, event.Data));
lh2 = addlistener(s,'DataAvailable',@(src, event)log_data(src, event, fid_data, fid_ts));

s.IsContinuous = true;
s.startBackground;
 pause(100)
s.stop;
delete(lh);delete(lh2)
fclose(fid_data);fclose(fid_ts);

%% Read in the file


fid2 = fopen(log_fn,'r');
[data,~] = fread(fid2,[nChannels_to_use,inf],'uint8');
fclose(fid2);

fid2 = fopen(timestamps_fn,'r');
[timestamps,~] = fread(fid2,[1,inf],'double');
fclose(fid2);


%%
data = startForeground(s);

%% Multipel channel example

