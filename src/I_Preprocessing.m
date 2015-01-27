%% CREATE CLIPS AND GET FEATURES
% Modifications:
% The new version of getTestClips() extracts clips from multiple probes at the same time
% overlap option is also now available for getTestClips()

clear; 
close all;

subjects = {'baseline0','baseline1','baseline2','SK0','SK1','PL'};

% probes = {'acc','gyr','lac','rot','mag'};    % probes to be used
probes = {'acc','gyr'};

cleanup; % deletes temporary clip and feature files from previous simulations

do_reflection = true;

currentDir = pwd;
addpath([pwd '/sub']); %create path to additional scripts

% input dir
dataDir = ['~/Dropbox/Data/FTC/raw/'];

% output dir
trainingFeatureDir = ['~/Dropbox/Data/FTC/features/train/'];

% temporary dirs
tempDir = ['~/Dropbox/Data/temp/'];
clipDir = [tempDir 'clips/'];

% sorting probe names alphabetically
G = cell(size(probes));
for ii = 1:size(probes,1),
    G(ii,1:size(probes,2)) = sort(probes(ii,:));
end
probes = G;

%options for extracting clips and features
options.secs = 4;
options.overlap = 0.75;
options.rate = 50;  % sampling frequency to interpolate to in getFeatures
options.activity_columns = 2;   % activity+location
options.activity_fraction = 0;
options.forceFileRewrite = 0;


%% Get the clips

%clips directory must already exists under parent folder

uniqueStates = {};

for subject = 1:length(subjects),
    
    fprintf('Extracting clips %d/%d (%d sec, %d%% overlap)...\n', subject, length(subjects), options.secs, options.overlap*100);

    %set up data directories we are going to use
    subjectDir = subjects{subject};
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
            'secs', options.secs,...
            'overlap', options.overlap,...
            'activity_columns', options.activity_columns,...
            'activity_fraction', options.activity_fraction,...
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

for file_subj = 1:size(files,2),
    
    filename = files{1,file_subj}; % NOTE: all probe features (acc, gyr, etc.) at the moment are saved under the name acc_*!
    filename = filename(find(files{1}=='_',1,'first')+1:end);
    
    %fprintf('\nCalculating features %d/%d (Interpolation at %dHz)... ', file_subj, size(files,2), options.rate);
    fprintf('\nCalculating features %d/%d (no interpolation)... ', file_subj, size(files,2));
    
    %i do not use reflections on the signal, but the option is still there
    if do_reflection,
        reflections = [1, 1, 1, 1; 1, -1, 1, 1; 1, 1, -1, 1; 1, 1, 1, -1; 1, -1 -1 1; 1, -1 1 -1; 1, 1 -1 -1; 1, -1 -1 -1];
    else
        reflections = [1, 1, 1, 1];
    end
    
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
            for reflection = 1:size(reflections,1),
                refl = clip_data.values{Index}.*repmat(reflections(reflection, :)',1,size(clip_data.values{Index},2));
                [x_vec, x_labels, feature_set] = getFeatures(refl, probes{file_prb}, options.secs, options.rate);
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
            end
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
    writefile = [trainingFeatureDir filename];
    if exist(writefile,'file') && ~options.forceFileRewrite
        fprintf(2, ['File ' filename ' exists. Skipping!\n']);
    else
        disp(['Writing to file ' filename]);
        save(writefile, 'features_data');
    end
    
    clear features_data;
    
end

  
% disp('Now go to /FTC/features and sort the training and test features.');