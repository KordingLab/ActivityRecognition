%% A tool to compare features extracted by the Android app and by MATLAB.

clear all;
close all;

feature_set = 'F2';
probes = {'acc', 'gyr'};
subject = 'FTC_TW2';
% feature_dir = '~/Dropbox/Data/ActivityRecognition/features_archive/';
feature_dir = '~/Dropbox/Data/temp/features/train/';

% sorting probe names alphabetically to mactch the way they have been
% produced by I_Preprocessing.m

G = cell(size(probes));
for ii = 1:size(probes,1),
    G(ii,1:size(probes,2)) = sort(probes(ii,:));
end
probes = G;

addpath('sub/');

file = {[feature_set '_' cell2mat(probes) '_' subject '.mat']};


load([feature_dir cell2mat(file)]);
N = length(features_data.feature_labels);
features = features_data.features;

figure;
ax(1) = subplot(1,2,1);
imagesc(features'); colormap gray;
set(gca, 'ytick', 1:N, 'yticklabel', features_data.feature_labels', 'TickLabelInterpreter', 'none');

ax(2) = subplot(1,2,2);
% features_app = load('features.csv');
features_app = load('mtp://[usb:003,006]/Internal%20storage/Android/data/edu.northwestern.sohrob.activityrecognition.activityrecognition/files');
imagesc(features_app'); colormap gray;
set(gca, 'ytick', 1:N, 'yticklabel', features_data.feature_labels', 'TickLabelInterpreter', 'none');

linkaxes(ax, 'y');