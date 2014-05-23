% This function extracts data from a cell array based on its time stamp
% data (first cell) and the start and end times specified in the arguments.

function [data_clipped, empty] = getClip(data, startWindow, endWindow)

% data_clipped = cell(length(data),1);
data_clipped = [];

% first column contains timestamps
data_time = data(:,1);

% finding closest data timestamps to desired start and end time
[~, startInd] = min(abs(data_time-startWindow));
[~, endInd] = min(abs(data_time-endWindow));

% return with empty if not enough data points are found inside the window
% otherwise extract the clip
if isempty(startInd)||isempty(endInd)||(endInd-startInd<=4*2),  % we must have at least two points in each dimension for interpolation in getFeatures function
    empty = 1;
else
    data_clipped = data(startInd:endInd,:);
    empty = 0;
end
end