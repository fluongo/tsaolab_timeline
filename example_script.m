% Initial script for interfacing between MC 1208-fs DAQ, whicvh will allow
% the sampling of 8 analog signals at 5000Hz

devices = daq.getDevices

%% Single Channel example...
clear all
daqreset
s = daq.createSession('mcc');
s.Rate = 5000;
s.DurationInSeconds = 20;

[ch, idx] = addAnalogInputChannel(s,'Board0',0:7,'Voltage');

%%
for i = 1:length(idx)
    ch(idx(i)).TerminalConfig = 'SingleEnded'
end

s.NotifyWhenDataAvailableExceeds =2*5000;
lh = addlistener(s,'DataAvailable', @(src,event) quick_plot(event.TimeStamps, event.Data));

data = startForeground(s);

%% Multipel channel example

