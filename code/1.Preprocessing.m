%% CREATE CLIPS AND GET FEATURES
% V2:   Overlap option added to the getTestClips function
% V3:   Uses getTestClips_v3 which extract clips from multiple probes at the
%       same time
%       Added classifierDataCreate to the end
clc; 
clear all; 
close all;

cleanup; % deletes temporary clip and feature files from previous simulations

run_mode = 'train';
% run_mode = 'test';

% probes = {'acc','gyr','lac','rot','mag'};    % probes to be used
probes = {'acc','bar'};

currentDir = pwd;
addpath([pwd '/sub']); %create path to helper scripts
dataDir = ['~/Dropbox/Data/Cornell_adapted/'];
tempDir = ['~/Dropbox/Data/temp/'];
trainingFeatureDir = [tempDir 'features/'];
clipDir = [tempDir 'clips/'];
dirList = dir(dataDir);

% sorting probe names alphabetically
G = cell(size(probes));
for ii = 1:size(probes,1),
    G(ii,1:size(probes,2)) = sort(probes(ii,:));
end
probes = G;

%options for extracting clips and features
options.secs = 4;
options.overlap = 0.75;
options.rate = 10;  % sampling frequency to interpolate to in getFeatures
options.activity_columns = 2;   % activity+location
options.activity_fraction = 0;
options.forceFileRewrite = 1;

patientDir = {};
controlDir = {};
testDir = {};

for directory = 1:length(dirList)
    dirName = dirList(directory).name;
    %skip hidden files
    if dirName(1) == '.'
        continue
    elseif strcmp(dirName(end),'p') %patient data
        patientDir{end+1} = dirName;
    elseif strcmp(dirName(end),'c') %control data
        controlDir{end+1} = dirName;
    elseif strcmp(dirName(end),'t') %test data
        testDir{end+1} = dirName;
    end
end

%Select which directories to use for feature extraction:
if strcmp(run_mode, 'train'),
    rawDirs = {controlDir{:}};
elseif strcmp(run_mode, 'test'),
    rawDirs = {testDir{:}};
end

if isempty(rawDirs),
    error(['No appropriate data directory found for ', run_mode, ' run mode.']);
end

filePathName = 'filepath';

%% Get the clips

%clips directory must already exists under parent folder

uniqueStates = {};

for subject = 1:length(rawDirs)
    
    %set up data directories we are going to use
    subjectDir = rawDirs{subject};
    dataFilePrefix = [dataDir subjectDir];
    for prb = 1:length(probes),
        clipFile{prb} = [clipDir cell2mat(probes(prb)) '_' subjectDir '.mat'];
    end
    
    %skip files if they already exist and we don't want to rewrite them
    %only the first probe is checked!
    if exist(clipFile{1},'file') && ~options.forceFileRewrite
        disp(['Skipping:' subjectDir]);
    else
        date = [];
        %get the clips based on our options, for the accelerometer probe
        [values, labels, percentTimeSpent] = getTestClips(dataFilePrefix, ...
            'secs',options.secs,...
            'overlap',options.overlap,...
            'activity_columns',options.activity_columns,...
            'activity_fraction',options.activity_fraction,...
            'probes', probes);
        
        for prb = 1:length(probes),
            
            %begin making our clip data structure
            clip_data = [];
            clip_data.values = values{prb};
            clip_data.identifier = {dataFilePrefix(end)};
            clip_data.activity_fraction = percentTimeSpent{prb};
            
            %current options for labels are:
            %{1} activity labels
            %{2} location label
            %if the location label is empty
            if size(labels{prb},1) == 1
                clip_data.act_label = labels{prb}{1};
                clip_data.wearing_label = {};
            elseif size(labels{prb},1) == 2
                clip_data.act_label = labels{prb}{1};
                clip_data.wearing_label = labels{prb}{2};
            end
            for i = 1:length(clip_data.act_label)
                clip_data.states{i} = [clip_data.wearing_label{i} '/' clip_data.act_label{i}];
            end
            uniqClipStates = unique(clip_data.states);
            
            %save our results
            save(clipFile{prb}, 'clip_data');
        end
    end
end


%% Calculate features for training data

% create a cell matrix of file names for each feature (row) and each
% subject (column) in in the clips directoty
files = {};
files_all = what(clipDir);
files_all = files_all.mat;
num_files = zeros(length(probes),1);
for file = 1:length(files_all),
    for prb = 1:length(probes),
        if strmatch(probes{prb}, files_all{file}),
            num_files(prb) = num_files(prb) + 1;
            files{prb,num_files(prb)} = files_all{file};
        end
    end
end

for file_subj = 1:size(files,2)
    
    filename = files{1,file_subj}; % NOTE: all probe features (acc, gyr, etc.) at the moment are saved under the name acc_*!
    filename = filename(find(files{1}=='_',1,'first')+1:end);
    
    disp('Calculating features...')
    
    %i do not use reflections on the signal, but the option is still there
    %         reflections = [1, 1, 1, 1];
    %         num_reflections = size(reflections,1);
    
    act_labels = {};
    wearing_labels = {};
    identifier = {};
    subject = {};
    x_data = [];
    activity_fraction = [];
    
    features_data.features = [];
    features_data.feature_labels = [];
    
    for file_prb = 1:size(files,1),
        
        readfile = [clipDir files{file_prb, file_subj}];
        load(readfile);
        % num_samples counting all the reflections
        num_samples = length(clip_data.values);
        
        act_labels = {};
        wearing_labels = {};
        identifier = {};
        subject = {};
        x_data = [];
        activity_fraction = [];
        for Index = 1:num_samples
            % cycle through the reflections
            % this should be done only for 3-axis sensors
            %                 for reflection = 1:num_reflections
            %                     len = size(clip_data.values{Index},2);
            %                     refl = clip_data.values{Index}.* repmat(reflections(reflection,:)',1,len);
            %                     refl = clip_data.values{Index};
            %                     [x_vec, x_labels] = getFeatures_v2(refl, options.secs, options.rate);
            [x_vec, x_labels, feature_set] = getFeatures(clip_data.values{Index}, probes{file_prb});
            x_data = [x_data; x_vec];
            act_labels{end+1} = clip_data.act_label{Index};
            identifier{end+1} = clip_data.identifier{1};
            subject{end+1} = filename(1:end-4);
            activity_fraction(end+1) = clip_data.activity_fraction(Index);
            if ~isempty(clip_data.wearing_label)
                wearing_labels{end+1} = clip_data.wearing_label{Index};
            else
                wearing_labels{end+1} = 'unlabeled';
            end
            %                 end
        end
        
        features_data.subject = subject;
        features_data.feature_labels = [features_data.feature_labels; x_labels];
        features_data.features = [features_data.features, x_data];  %concatenating features coming from different probes
        features_data.activity_labels = act_labels;
        features_data.wearing_labels = wearing_labels;
        features_data.identifier = identifier;
        features_data.activity_fraction = activity_fraction;
        
    end
    
    filename = [feature_set '_' cell2mat(probes) '_' filename];
    disp(['Writing to file ' filename]);
    writefile = [trainingFeatureDir filename];
    if exist(writefile,'file') && ~options.forceFileRewrite
        disp(['File ' filename ' exists. Skipping...']);
    else
        save(writefile, 'features_data');
    end
    
    clear features_data;
    
end

  
