%% CLASSIFIER DATA CREATE
% This program combines all feature files ending with '_c.mat' (presumably
% training data features) in the features temporary directory into
% 'train_data.mat'; and files ending with '_t.mat'
% (test data features) into 'test_data.mat'.

clear all;
close all;

% Run Mode:
% train: only use feature files ending with '_c.mat' for aggregation
% test: only use feature files ending with '_t.mat' for aggregation
run_mode = 'train';

addpath([pwd '/sub']); %create path to helper scripts
tempDir = ['~/Dropbox/Data/temp/'];
FeatureDir = [tempDir 'features/']; %features directory to build classifier data from

classifierData = combineAllSubjectFeatures(FeatureDir, run_mode);
classifierData = combineLocations(classifierData,'Pocket');
classifierData = combineLocations(classifierData,'Belt');
classifierData = combineLocations(classifierData,'Bag');
classifierData = combineLocations(classifierData,'Hand');

classifierData.states = createStateList(classifierData);

classifierData = removeDataWithNaNs(classifierData);

trainingClassifierData = classifierData;

if strcmp(run_mode, 'train'),
    save('train_data','trainingClassifierData');
    fprintf('Train data file with %d subject(s) created.\n',length(unique(trainingClassifierData.subject)));
elseif strcmp(run_mode, 'test'),
    save('test_data','trainingClassifierData');
    fprintf('Test data file with %d subject(s) created.\n',length(unique(trainingClassifierData.subject)));
else
    disp('Run mode unknown. No data file created!');
end