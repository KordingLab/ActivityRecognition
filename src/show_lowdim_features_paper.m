clear;
close all;

os = 'lin';

n_trial = 4;
recalculate_coefs = false;

if strcmp(os,'win'),
    features_dir = 'C:\\Users\\Sohrob\\Dropbox\\Data\\FTC\\features\\archive\\LL\\';
    models_dir = 'C:\\Users\\Sohrob\\Dropbox\\Data\\FTC\\models\\LL\\';
    baseline_dir = 'C:\\Users\\Sohrob\\Dropbox\\Data\\FTC\\features\\archive\\baseline\\';
elseif strcmp(os,'lin'),
    features_dir = '~/Dropbox/Data/FTC/features/archive/LL/';
    models_dir = '~/Dropbox/Data/FTC/models/LL/';
    baseline_dir = '~/Dropbox/Data/FTC/features/archive/baseline/';
else
    error('Unknown OS option.');
end


clip_start = 1;
xmin = -1000;
xmax = 15000;
ymin = -2000;
ymax = 2000;
dot_size = 20;

% loading normal walk data (from subject)
load([features_dir, 'F1_accgyr_LLW0.mat']);
data_nwalk = features_data.features(clip_start:end,:);
label_nwalk = ones(size(features_data.features(clip_start:end,:),1),1)*[0 0 1];

% loading normal still data (from baseline)
load([baseline_dir, 'F1_accgyr_baseline2.mat']);
data_nsit = features_data.features(clip_start:end,:);
label_nsit = ones(size(features_data.features(clip_start:end,:),1),1)*[0 0 1];

if recalculate_coefs,
    % PCA
%     [coefs, ~] = pca([data_nwalk; data_nsit]);
%     coefs = coefs(:,1:2);
    
    % Sparse PCA
    % gamma=0.01*ones(1,3);
    % coefs = GPower([data_nwalk; data_nsit], gamma, 3 ,'l1',0);
    
    % Factor Analysis
    coefs = factoran([data_nwalk; data_nsit], 2);
%     coefs_psinv = inv(coefs'*coefs)*coefs';
%     coefs = coefs_psinv';
else
    load('coefs_lowdim.mat');
end

% score = [data_nwalk; data_nsit]*coefs;
% score = [data_nwalk; data_nsit]*coefs;
% label = [label_nwalk; label_nsit];



h = figure;
set(h, 'position', [2058          46        1295         704]);

% subplot(2, n_trial, 1);
% scatter(score(:,1), score(:,2), dot_size, label, 'filled');

% xlim([xmin xmax]);
% ylim([ymin ymax]);
% set(gca, 'xticklabel', []);
% set(gca, 'yticklabel', []);

% loading deceptive walk (fake still)

score_plotly_walk = [data_nsit]*coefs;
label_plotly_walk = [label_nsit*0];
score_plotly_sit = [data_nwalk]*coefs;
label_plotly_sit = [label_nwalk*0];

colors = jet(n_trial-1);

for i=1:(n_trial-1),
    
    %% deceptive walking
    
    load([features_dir, sprintf('F1_accgyr_LLW%d.mat',i)]);
    data_dwalk = features_data.features(clip_start:end,:);
    load([models_dir, sprintf('LLS%d.mat',i-1)]);
    [RFout, ~] = predict(RFmodel, data_dwalk);
    %label_dwalk = strcmp(RFout, '1')*[1 0 0] + strcmp(RFout, '2')*[1 .6 .6];
    success_dwalk = sum(strcmp(RFout, '2'))/length(RFout);
    data_dwalk = data_dwalk(strcmp(RFout, '2'), :);
    label_dwalk = ones(size(data_dwalk,1),1)*[1 .5 .5];
    data = [data_nsit; data_dwalk];
    score = data*coefs;
    score_nsit = data_nsit*coefs;
    score_dwalk = data_dwalk*coefs;
    
    subplot(2, n_trial-1, i);
%     scatter(score(:,1), score(:,2), dot_size, [label_nsit; label_dwalk], 'filled');
    plot(score_nsit(:,1), score_nsit(:,2), '.', 'color', [0 .5 0],'markersize',dot_size); hold on;
    plot(score_dwalk(:,1), score_dwalk(:,2), '.', 'color', [.5 .5 .5],'markersize',dot_size);
    %scatter3(score(:,1), score(:,2), score(:,3), dot_size, [label_nsit; label_dwalk], 'filled');
    xlim([-1000 15000]);
    ylim([-2000 2000]);
    set(gca, 'xticklabel', []);
    set(gca, 'yticklabel', []);
    xlabel('Factor 1');
    ylabel('Factor 2');
    
%     title(['Trial ', num2str(i)]);
    
    if i==n_trial-1,
        legend('True Activity','Fake Activity');
    end
    
    %% deceptive sitting
    
    load([features_dir, sprintf('F1_accgyr_LLS%d.mat',i)]);
    data_dsit = features_data.features(clip_start:end,:);
    load([models_dir, sprintf('LLW%d.mat',i)]);
    [RFout, ~] = predict(RFmodel, data_dsit);
    %label_dsit = strcmp(RFout, '2')*[0 0 1] + strcmp(RFout, '1')*[.6 .6 1];
    success_dsit = sum(strcmp(RFout, '1'))/length(RFout);
    data_dsit = data_dsit(strcmp(RFout, '1'),:);
    label_dsit = ones(size(data_dsit,1),1)*[1 .5 .5];
    data = [data_nwalk; data_dsit];
    score = data*coefs;
    score_nwalk = data_nwalk*coefs;
    score_dsit = data_dsit*coefs;
    
    subplot(2, n_trial-1, n_trial-1+i);
    %scatter(score(:,1), score(:,2), dot_size, [label_nwalk; label_dsit], 'filled');
    plot(score_nwalk(:,1), score_nwalk(:,2), '.', 'color', [0 .5 0],'markersize',dot_size); hold on;
    plot(score_dsit(:,1), score_dsit(:,2), '.', 'color', [.5 .5 .5],'markersize',dot_size);
    %scatter3(score(:,1), score(:,2), score(:,3), dot_size, [label_nwalk; label_dsit], 'filled');
    xlim([0 15000]);
    ylim([-2000 1500]);
    set(gca, 'xticklabel', []);
    set(gca, 'yticklabel', []);
    xlabel('Factor 1');
    ylabel('Factor 2');

    
end

if recalculate_coefs,
    save('coefs_lowdim.mat','coefs');
end