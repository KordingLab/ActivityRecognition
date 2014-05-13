%% CLASSIFIER DATA CREATE
% This program combines all feature files ending with _c.mat (presumably
% training data features) into 'train_data.mat' and files ending with _t.mat
% (test data features) into 'test_data.mat'.

clear all;
close all;

run_mode = 'train';

addpath([pwd '/sub']); %create path to helper scripts
tempDir = ['~/Dropbox/Data/temp/'];
FeatureDir = [tempDir 'features/'];

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
    disp('Training data file created.');
elseif strcmp(run_mode, 'test'),
    save('test_data','trainingClassifierData');
    disp('Test data file created.');
else
    disp('Run mode unknown. No data file created!');
end