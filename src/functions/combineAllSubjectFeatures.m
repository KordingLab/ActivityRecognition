%% V2: run_mode added
% in tran mode, only *_c.mat files are combined.
% in test mode, only *_t.mat files are combined.

function classifierData = combineAllSubjectFeatures(featureDir)

files = dir([featureDir '/*.mat']);
if isempty(files),
    error('No feature files found.');
end

features = [];
activity = [];
wearing = [];
identifier = [];
subject = [];
activityFrac = [];
for file = 1:length(files)
    
    filename = files(file).name;
    if files(file).isdir || filename(1) == '.' || ...
        strcmp(filename,'options.mat') || strcmp(filename,'classifierData.mat')
        continue;
    end
    
    readfile = [featureDir filename];
    load(readfile);
    features =  [features; features_data.features];
    activity = char(activity, char(features_data.activity_labels));
    wearing = char(wearing, char(features_data.wearing_labels));
    identifier = char(identifier, char(features_data.identifier));
    subject = char(subject, char(features_data.subject));
    activityFrac = [activityFrac; features_data.activity_fraction'];
end

activity = cellstr(activity(2:end,:));
wearing = cellstr(wearing(2:end,:));
identifier = cellstr(identifier(2:end,:));
subject = cellstr(subject(2:end,:));

classifierData.activity = activity;
classifierData.wearing = wearing;
classifierData.identifier = identifier;
classifierData.subject = subject;
classifierData.features = features;
classifierData.featureLabels = features_data.feature_labels;
classifierData.activityFrac = activityFrac;
end