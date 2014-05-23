function [values, activities, activity_fraction] = getTestClips(accdata, varargin)
% extracts clips of activity samples from recorded accleration data

% options: secs, resample_secs, datetime_format, data_columns
% secs - length of the samples in seconds
% resample_secs - how often to resample
% datetime_columns - 1 if datetime stamp, 2 if date then time columns
% activity_columns - number of columns used to collect labelled activities
% activity_fraction - how much of a sample needs to be one activity to have that label
% probes - which probes to use (default: accelerometer only)

% returns as cell arrays:
% ret_acc  - 4 row matrix with time in seconds, then x,y,z accelerations
% ret_date - cell of Java format date time stamp (date/time separated by a space
% ret_act  - activity_columns wide cell array

% file formats include
% time in sec, x, y, z, 1-2 date/time columns, 0-2 activity columns
% file may or may not be contiguous in time, and activities may or may
% not change throughout

% V2: Added the probes option -- which probe files to look into for clip
% extraction
% V3: changed the start-time for each clip such that all data streams use
% a single window for clipping
% V4: Reading the new file format which does not contain text (it contains
% class/location codes instead) - Also able to read from sensors with
% variable number of values

options = struct('secs',10, 'overlap', 0, ...
    'activity_columns', 1, ...
    'activity_fraction', 0.8, ...
    'probes', 'acc');

optionNames = fieldnames(options);
nArgs = length(varargin);
if round(nArgs/2)~=nArgs/2
    error('extract_features needs propertyName/propertyValue pairs')
end
for pair = reshape(varargin,2,[]) %# pair is {propName;propValue}
    inpName = lower(pair{1}); %# make case insensitive
    if any(strmatch(inpName,optionNames))
        options.(inpName) = pair{2};
    else
        error('%s is not a recognized parameter name',inpName)
    end
end

for prb = 1:length(options.probes),
    activity_fraction{prb} = [];
    values{prb} = {};   % the acceleration vector that gets returned
    activities{prb} = cell(options.activity_columns,1);
end

% generate a list of data files for all probes and trials
for prb = 1:length(options.probes),
    datafiles{prb} = expandFilenames(accdata, ['/', options.probes{prb}, '_*.csv']);
    if isempty(datafiles{prb})
        error(['No data files found for probe ', options.probes{prb}]);
    end
end

% check if data files exist for all of the probes
for prb = 2:length(options.probes),
    if length(datafiles{prb})~=length(datafiles{prb-1}),
        error('Data files don''t exist for some of the probes!');
    end
end

class_info_file = 'class_info_FTC.xls';
location_info_file = 'location_info.xls';
fprintf('getTestClips: Assigning class names according to %s\n', class_info_file);
fprintf('getTestClips: Assigning location names according to %s\n', location_info_file);
[class_codes, class_labels] = xlsread(class_info_file);
[loc_codes, loc_labels] = xlsread(location_info_file);

for file = 1:length(datafiles{1}),
    
    for prb = 1:length(options.probes),
        
        filename = datafiles{prb}{file};
        data{prb} = load(filename);
        if isempty(data{prb}),
            error(['Data file for probe '], options.probes{prb}, [' is empty.']);
        end
        
        num_rows(prb) = size(data{prb},1); 
  
    end
    
    startTime = min(data{prb}(:,1)); % startTime and endTime are determined based on the lead (first) probe
    endTime = max(data{prb}(:,1));
    startWindow = startTime - options.secs*(1-options.overlap);
    endWindow = startWindow + options.secs;
    
%     num_rows
    cnt = 0;
    
    format longg
    
    while endWindow < endTime,
        
        cnt = cnt+1;
        
        % marking the beginning and the end of clipping
        startWindow = startWindow + options.secs*(1-options.overlap);
        endWindow = startWindow + options.secs;
        
%         disp([endTime, endWindow])
        
        % extracting the clip
        empty = zeros(length(options.probes),1);
        for prb = 1:length(options.probes),
            [data_clipped{prb}, empty(prb)] = getClip(data{prb}, startWindow, endWindow);
        end
        % checking if any of the probes data is empty (look at getClip)
        if sum(empty)~=0,
            continue;
        end
        
        % now check if transition has occured
        transition_occured = false;
        for prb = 1:length(options.probes),
            if (data_clipped{prb}(end,end)~=data_clipped{prb}(1,end))||(data_clipped{prb}(end,end-1)~=data_clipped{prb}(1,end-1)),
                transition_occured = true;
            end
        end
        if transition_occured,
            continue;
        end
        
        
        for prb = 1:length(options.probes),
            
            % extracting the time and value columns
%             val = data_clipped{prb}(:,1:end-options.activity_columns)';
%             values{prb}{end+1} = val;
            values{prb}{end+1} = data_clipped{prb}(:,1:end-options.activity_columns)';
            
            % assigning mid-way activity/loc label to all (good idea?)
%             for act_i = 1:options.activity_columns,
%                 activities{prb}{act_i}{end+1} = data_clipped{prb}(round(end/2), end-options.activity_columns+act_i);
%             end
            % activity label:
            code = data_clipped{prb}(round(end/2), end-options.activity_columns+1);
            activities{prb}{1}{end+1} = cell2mat(class_labels(find(class_codes==code),2));
%             activities{prb}{1}{end+1} = class_labels(code+1,2);
            % location label:
            code = data_clipped{prb}(round(end/2), end-options.activity_columns+2);
            activities{prb}{2}{end+1} = cell2mat(loc_labels(find(loc_codes==code),2));
%             activities{prb}{2}{end+1} = loc_labels(code+1,2);

            activity_fraction{prb}(end+1) = 1; % activity fraction currently disabled
            
        end

    end
end
