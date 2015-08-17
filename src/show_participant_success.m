clear;
close all;

load 'subject_performance.mat';

perf_sit{end}(2) = [];
perf_walk{end}(2) = [];

colors = parula(length(subjects));

h = figure;
set(h, 'position', [2124         445         672         432]);
hold on;

for subj = 1:length(subjects),
    
    for trial = 1:length(perf_sit{subj}),

        perf_min{subj}(trial) = min(perf_sit{subj}(trial), perf_walk{subj}(trial));
        perf_avg{subj}(trial) = (perf_sit{subj}(trial) + perf_walk{subj}(trial))/2;
        
    end
    
    plot(100*perf_avg{subj}, '.-', 'color', colors(subj,:), 'linewidth', 1, 'markersize', 20);
    
end

% xminmax = xlim;
% plot([xminmax(1) xminmax(2)], [.5 .5], '--', 'color', [.65 .65 .65], 'linewidth', 2);
% set(gca, 'xtick', 1:xminmax(2));
xlabel('Trial #');
ylabel('Average Sitting/Walking Success Rate (%)');
% legend(subjects);
set(gca, 'xtick', 1:4);
xlim([.7 4.3]);