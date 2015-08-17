clear;
close all;

% subjects = {'DM','DR','ED','ES','LL','MG','ML','PL','SC'};
subjects = {'SC', 'ED', 'MG', 'LL', 'PL', 'ML', 'DM', 'ES', 'DR', 'AR', 'SM', 'RK', 'BC', 'AT', 'MD'};

features_dir = '~/Dropbox/Data/FTC/features/archive/';
models_dir = '~/Dropbox/Data/FTC/models/';

% clipping parameters
clip_start = 1;
clip_end = 0;

% RF parameters
n_tree = 100;

write_results = true;
calculate_importance = false;

%% loading data

n_trial = zeros(1,length(subjects));
features_sit = cell(1,length(subjects));
features_walk = cell(1,length(subjects));

for subj = 1:length(subjects),
   
    subject_dir = [features_dir, subjects{subj}, '/'];
    files = what(subject_dir);
    n_trial(subj) = (length(files.mat)+1)/2;
    
    features_sit{subj} = cell(1,n_trial(subj));
    features_walk{subj} = cell(1,n_trial(subj));
    
    for trial = 0:n_trial(subj)-1,
        
        % sitting data for trial #0 is taken from baseline dataset
        if trial==0,
            load('~/Dropbox/Data/FTC/features/archive/baseline/F1_accgyr_baseline2.mat');
        else
            load([subject_dir,sprintf('F1_accgyr_%sS%d.mat', subjects{subj}, trial)]);
        end
        features_sit{subj}{trial+1} = features_data.features(clip_start:end-clip_end,:);
    
        load([subject_dir,sprintf('F1_accgyr_%sW%d.mat', subjects{subj}, trial)]);
        features_walk{subj}{trial+1} = features_data.features(clip_start:end-clip_end,:);
        
    end
    
end

clear features_data;

%% cross-validation across subjects

RFmodels_before = cell(length(subjects),1);
RFmodels_after = cell(length(subjects),1);
accuracy_before = zeros(length(subjects),1);
accuracy_after = zeros(length(subjects),1);

% Run it only once
% parpool(3);

for subj = 1:length(subjects),
    
    fprintf('Subject %d/%d\n', subj, length(subjects));
   
    features_test = [];
    labels_test = [];
    
    % building the test sets
    for trial = 2:n_trial(subj),
        features_test = [features_test; features_sit{subj}{trial}; features_walk{subj}{trial}];
        labels_test = [labels_test; 2*ones(size(features_sit{subj}{trial},1),1); 1*ones(size(features_walk{subj}{trial},1),1)];
    end
    
    %training on normal walk and sit trials
    
    features_train = [];
    labels_train = [];
    
    for subj_train = [1:(subj-1), (subj+1):length(subjects)],
        features_train = [features_train; features_sit{subj_train}{1}; features_walk{subj_train}{1}];
        labels_train = [labels_train; 2*ones(size(features_sit{subj_train}{1},1),1); 1*ones(size(features_walk{subj_train}{1},1),1)];
    end
    
    n_train_normal = size(features_train, 1);
    
    inds = randsample(1:size(features_train,1), n_train_normal);
    features_train = features_train(inds, :);
    labels_train = labels_train(inds, :);
    
    RFmodels_before{subj} = TreeBagger(n_tree, features_train, labels_train, 'OOBVarImp', 'off');
    
    [labelsRF,~] = predict(RFmodels_before{subj}, features_test);
    labelsRF = str2double(labelsRF);
    
    acc = (labelsRF==labels_test);
    accuracy_before(subj) = mean(acc);
    
    %training on all trials
    
    features_train_sit = [];
    labels_train_sit = [];
    features_train_walk = [];
    labels_train_walk = [];
    
    for subj_train = [1:(subj-1), (subj+1):length(subjects)],
        for trial = 1:n_trial(subj_train),
            features_train_sit = [features_train_sit; features_sit{subj_train}{trial}];
            labels_train_sit = [labels_train_sit; 2*ones(size(features_sit{subj_train}{trial},1),1)];
            features_train_walk = [features_train_walk; features_walk{subj_train}{trial}];
            labels_train_walk = [labels_train_walk; 1*ones(size(features_walk{subj_train}{trial},1),1)];
        end
    end
    inds = randsample(1:size(features_train_sit, 1),  round(n_train_normal/2));
    features_train = features_train_sit(inds, :);
    labels_train = labels_train_sit(inds, :);
    inds = randsample(1:size(features_train_walk, 1),  round(n_train_normal/2));
    features_train = [features_train; features_train_walk(inds, :)];
    labels_train = [labels_train; labels_train_walk(inds, :)];
    
    RFmodels_after{subj} = TreeBagger(n_tree, features_train, labels_train, 'OOBVarImp', 'off');
    
    [labelsRF,~] = predict(RFmodels_after{subj}, features_test);
    labelsRF = str2double(labelsRF);

    acc = (labelsRF==labels_test);
    accuracy_after(subj) = mean(acc);

%     accuracy_mean{subj}{trial} = mean(accuracy);
%     accuracy_median{subj}{trial} = median(accuracy);
%     accuracy_std{subj}{trial} = std(accuracy);
%     accuracy_low{subj}{trial} = prctile(accuracy,5);
%     accuracy_high{subj}{trial} = prctile(accuracy,95);
    
end

if write_results,
    save('accuracy_cross_subject_loocv', 'accuracy_before', 'accuracy_after', 'subjects');
    if calculate_importance,
        load('~/Dropbox/Data/FTC/features/archive/baseline/F1_accgyr_baseline2.mat');
        features_labels=features_data.feature_labels;
        save('feature_importance_loocv', 'RFmodels', 'features_labels');
    end
end
