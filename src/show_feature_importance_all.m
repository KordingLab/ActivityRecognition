clear;
close all;

load('feature_importance.mat');

importance_start = [];
importance_end = [];

ind = randsample(1:260, 260);

for subj = 1:length(RFmodel),
    
    % beginning
    importance_start = [importance_start; zscore(RFmodel{subj}{1}.OOBPermutedVarDeltaError(ind))];
    
    % end
    importance_end = [importance_end; zscore(RFmodel{subj}{end}.OOBPermutedVarDeltaError(ind))];
    
end
subplot 211;
imagesc(importance_start);
% set(gca, 'ytick', 1:length(ind), 'yticklabel', features_labels(ind), 'TickLabelInterpreter', 'none', 'fontsize', 7);
% set(gca, 'xtick', []);

subplot 212;
imagesc(importance_end);
% set(gca, 'ytick', 1:length(ind), 'yticklabel', features_labels(ind), 'TickLabelInterpreter', 'none', 'fontsize', 7);
% set(gca, 'xtick', []);
