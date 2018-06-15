function logData(src, evt, fid_data, fid_ts)
% Add the time stamp and the data values to data. To write data sequentially,
% transpose the matrix.

%   Copyright 2011 The MathWorks, Inc.

% Write the data with low precision and the timestamps with high..
% Remember to transpose data so it is read out appropriately..
fwrite(fid_data,evt.Data','uint8');
fwrite(fid_ts, evt.TimeStamps, 'double');

end

