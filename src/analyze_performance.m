clear;
close all;

subjects = {'SC', 'ED', 'MG', 'LL', 'PL', 'ML', 'ES', 'DR', 'AR', 'SM', 'RK', 'BC', 'AT', 'MD'};

features_dir = 'C:\\Users\\Sohrob\\Dropbox\Data\\FTC\\features\\archive\\';
models_dir = 'C:\\Users\\Sohrob\\Dropbox\\Data\FTC\models\\';

h = figure(1);
set(h, 'position', [2639         291         668         363]);
hold on;

colors = hsv(length(subjects));

for subj = 1:length(subjects),
    
    files = dir([models_dir, subjects{subj}]);
    n_trial = (length(files)-3)/2;
    
    for trial = 1:n_trial,

        % sitting session
        if strcmp(subjects{subj},'LL'),
            load([models_dir, sprintf('%s\\%sW%d',subjects{subj},subjects{subj},trial)]);
        else
            load([models_dir, sprintf('%s\\%sW%d',subjects{subj},subjects{subj},trial-1)]);
        end
        load([features_dir, sprintf('%s\\F1_accgyr_%sS%d',subjects{subj},subjects{subj},trial)]);
        y = predict(RFmodel, features_data.features);
        perf_sit{subj}(trial) = sum(strcmp(y,'1'))/length(y);

        % walking session
        if strcmp(subjects{subj},'LL'),
            load([models_dir, sprintf('%s\\%sS%d',subjects{subj},subjects{subj},trial-1)]);
        else
            load([models_dir, sprintf('%s\\%sS%d',subjects{subj},subjects{subj},trial)]);
        end
        load([features_dir, sprintf('%s\\F1_accgyr_%sW%d',subjects{subj},subjects{subj},trial)]);
        y = predict(RFmodel, features_data.features);
        perf_walk{subj}(trial) = sum(strcmp(y,'2'))/length(y);
        
        perf_min{subj}(trial) = min(perf_sit{subj}(trial), perf_walk{subj}(trial));
        
    end
    
    plot(perf_min{subj}, 'color', colors(subj,:), 'linewidth', 2);
%     plot(length(perf_min{subj}), perf_min{subj}(end), '.', 'color', colors(subj,:), 'markersize', 18);
    
end

xminmax = xlim;
plot([xminmax(1) xminmax(2)], [.5 .5], '--', 'color', [.65 .65 .65], 'linewidth', 2);
set(gca, 'xtick', 1:xminmax(2));
xlabel('Trial');
ylabel('Performance');
legend(subjects);