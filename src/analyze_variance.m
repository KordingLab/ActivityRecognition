clear;
close all;

% subjects = {'AR','DM','DR','ED','ES','LL','MG','ML','PL','SC'};

subjects = {'SC', 'ED', 'MG', 'LL', 'PL', 'ML', 'DM', 'ES', 'DR', 'AR', 'SM', 'RK', 'BC', 'AT', 'MD'};

features_dir = 'C:\Users\Sohrob\Dropbox\Data\FTC\features\archive\';
models_dir = 'C:\Users\Sohrob\Dropbox\Data\FTC\models\';

h = figure(1);
set(h, 'position', [2639         291         668         363]);
hold on;
% subplot 211;
% hold on;
% subplot 212;
% hold on;

colors = hsv(4);

for subj = 1:length(subjects),
    
    files = dir([features_dir, subjects{subj}]);
    n_trial = (length(files)-3)/2
    
    load([features_dir, sprintf('%s\\F1_accgyr_%sW0',subjects{subj},subjects{subj})]);
    features_successful = features_data.features;
    
    variance = [];
    variance(1) = mean(var(features_successful));
    
    for trial = 1:n_trial-1,

        if strcmp(subjects{subj},'LL'),
            load([models_dir, sprintf('%s\\%sW%d',subjects{subj},subjects{subj},trial)]);
        else
            load([models_dir, sprintf('%s\\%sW%d',subjects{subj},subjects{subj},trial-1)]);
        end

        % sitting session
        load([features_dir, sprintf('%s\\F1_accgyr_%sS%d',subjects{subj},subjects{subj},trial)]);
        
        y = predict(RFmodel, features_data.features);
        features_successful = [features_successful; features_data.features(strcmp(y,'1'),:)];
        
        variance(trial+1) = mean(var(features_successful));
        
    end
    
    plot(0:n_trial-1, variance, '-*', 'color', colors(n_trial, :));
        
end

xlim([0 4]);