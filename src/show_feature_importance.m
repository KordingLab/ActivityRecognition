clear;
close all;

load('feature_importance.mat');

for subj = 1:length(RFmodel),
    
    % beginning
    subplot(2, length(RFmodel), subj);
    [~,ind] = sort(RFmodel{subj}{1}.OOBPermutedVarDeltaError, 'descend');
    ind = ind(1:16);
    imagesc(RFmodel{subj}{1}.OOBPermutedVarDeltaError(ind)');
    set(gca, 'ytick', 1:length(ind), 'yticklabel', features_labels(ind), 'TickLabelInterpreter', 'none', 'fontsize', 7);
    set(gca, 'xtick', []);
    title(sprintf('subject %d', subj));
    if subj==1,
        ylabel('beginning');
    end
    
    % end
    subplot(2, length(RFmodel), subj+length(RFmodel));
    [~,ind] = sort(RFmodel{subj}{end}.OOBPermutedVarDeltaError, 'descend');
    ind = ind(1:16);
    imagesc(RFmodel{subj}{end}.OOBPermutedVarDeltaError(ind)');
    set(gca, 'ytick', 1:length(ind), 'yticklabel', features_labels(ind), 'TickLabelInterpreter', 'none', 'fontsize', 7);
    set(gca, 'xtick', []);
    if subj==1,
        ylabel('end');
    end
    
end