%Plotting the feature vectors that are currentlt in the Features directory

clear all;
close all;

feature_set = 'F3.1';
probes = {'acc', 'gyr'};
subject = 'SS_c';
feature_dir = '~/Dropbox/Data/ActivityRecognition/features_archive/';

% sorting probe names alphabetically
G = cell(size(probes));
for ii = 1:size(probes,1),
    G(ii,1:size(probes,2)) = sort(probes(ii,:));
end
probes = G;

addpath('sub/');

files = {[feature_set '_' cell2mat(probes) '_' subject '.mat']};
% files = what(feature_dir);
% files = files.mat;

for f = 1:length(files),

    file = files(f);
    load([feature_dir cell2mat(file)]);
    N = length(features_data.feature_labels);

    figure;
    
    subplot(4,1,[1 2]);
    features = features_data.features;
    num_samp = size(features,1);
    features_normalized = scaleFeatures_v2(features);
    imagesc(features_normalized');
    colormap gray;
    set(gca, 'ytick', 1:N, 'yticklabel', features_data.feature_labels);
    
    subplot 413;
    h = plot(cell2vec(features_data.activity_labels), 'k', 'linewidth', 3);
    set(gca, 'ytick', 1:length(unique(features_data.activity_labels)), 'yticklabel', unique(features_data.activity_labels));
    axis tight;
    grid on;

    subplot 414;
    h = plot(cell2vec(features_data.wearing_labels), 'k', 'linewidth', 3);
    set(gca, 'ytick', 1:length(unique(features_data.wearing_labels)), 'yticklabel', unique(features_data.wearing_labels));
    axis tight;
    grid on;

end
