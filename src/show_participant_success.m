clear;
close all;

load 'subject_performance.mat';

perf_sit{end}(2) = [];
perf_walk{end}(2) = [];

colors = parula(length(subjects));

h = figure;
set(h, 'position', [0         0         672         432]);
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
xlabel('Retraining Round #', 'fontsize', 14);
ylabel('Average Success Rate (%)', 'fontsize', 14);
% legend(subjects);
set(gca, 'xtick', 1:4);
xlim([.7 4.3]);
legend('S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13','S14',...
    'location', 'eastoutside');