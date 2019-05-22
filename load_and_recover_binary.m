%Script for loading and recovering the binary file

fn_bin= 'timeline_04-05-2019_11-22.bin'
ts_bin= 'timeline_04-05-2019_11-22_ts.bin'
labels = {'fUS', 'stim'}
n_channels = 2

% Read in the data and Save as .mat
disp('LOADING IN DATA....')
fid2 = fopen(fn_bin,'r');
[data,~] = fread(fid2,[n_channels,inf],'single');
data = single(data);
fclose(fid2);

fid2 = fopen(ts_bin,'r');
[timestamps,~] = fread(fid2,[1,inf],'double');
fclose(fid2);

disp('WRITING DATA TO MAT FILE....')
save([fn_bin(1:end-4), '.mat'], 'timestamps', 'data', 'labels', '-v7.3')
disp('DONE WRITING DATA TO MAT FILE.....')