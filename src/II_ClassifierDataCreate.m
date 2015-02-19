%% CLASSIFIER DATA CREATE
% This program combines all feature files inside the 'train' directory into
% 'train_data.mat'; and files in the 'test' directory into 'test_data.mat'.

clear;
close all;

addpath([pwd '/sub']); %create path to helper scripts

FeatureDir = '~/Dropbox/Data/FTC/features/';

% training and test data dirs
TrainDir = [FeatureDir 'train/'];
TestDir = [FeatureDir 'test/'];

% aggregating and writing training data
TrainData = combineAllSubjectFeatures(TrainDir);
TrainData.states = createStateList(TrainData);
TrainData = removeDataWithNaNs(TrainData);
save('train_data','TrainData');
fprintf('Train data file with %d subject(s) created.\n',length(unique(TrainData.subject)));

% aggregating and writing test data
TestData = combineAllSubjectFeatures(TestDir);
TestData.states = createStateList(TestData);
TestData = removeDataWithNaNs(TestData);
save('test_data','TestData');
fprintf('Test data file with %d subject(s) created.\n',length(unique(TestData.subject)));
