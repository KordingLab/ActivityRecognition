clear;
close all;

os = 'lin';
% os = 'win';

subjects = {'SC', 'ED', 'MG', 'LL', 'PL', 'ML', 'DM', 'ES', 'DR', 'AR', 'SM', 'RK', 'BC', 'AT', 'MD'};

if strcmp(os, 'lin'),
    features_dir = '~/data/archive/';
    models_dir = '~/data/models/';
    slsh = '/';
elseif strcmp(os, 'win'),
    features_dir = 'C:\\Users\\Sohrob\\Dropbox\\Data\\FTC\\features\\archive\\';
    models_dir = 'C:\\Users\\Sohrob\\Dropbox\\Data\\FTC\\models\\';
    slsh = '\\';
else
    error('Unknown OS');
end

% clipping parameters
clip_start = 10;
clip_end = 0;

% RF parameters
n_tree = 200;

n_btstp = 14;

write_results = true;

%% loading data

n_trial = zeros(1,length(subjects));
features_sit = cell(1,length(subjects));
features_walk = cell(1,length(subjects));

for subj = 1:length(subjects),
   
    subject_dir = [features_dir, subjects{subj}, slsh];
    files = what(subject_dir);
    n_trial(subj) = (length(files.mat)+1)/2;
    
    features_sit{subj} = cell(1,n_trial(subj));
    features_walk{subj} = cell(1,n_trial(subj));
    
    for trial = 0:n_trial(subj)-1,
        
        % sitting data for trial #0 is taken from baseline dataset
        if trial==0,
            load([features_dir, 'baseline', slsh, 'F1_accgyr_baseline2.mat']);
        else
            load([subject_dir, sprintf('F1_accgyr_%sS%d.mat', subjects{subj}, trial)]);
        end
        features_sit{subj}{trial+1} = features_data.features(clip_start:end-clip_end,:);
    
        load([subject_dir,sprintf('F1_accgyr_%sW%d.mat', subjects{subj}, trial)]);
        features_walk{subj}{trial+1} = features_data.features(clip_start:end-clip_end,:);
        
    end
    
end

clear features_data;

%% cross-validation across subjects

accuracy_baseline = zeros(length(subjects)-1, length(subjects), n_btstp);
accuracy_expert = zeros(length(subjects)-1, length(subjects), n_btstp);

for n_subj_train = 1:length(subjects)-1,
   
%     fprintf('No. Training Subjects %d\n', n_subj_train);
   
    accuracy_baseline_subjtest = zeros(length(subjects), n_btstp);
    accuracy_expert_subjtest = zeros(length(subjects), n_btstp);
    
    parfor subj_test = 1:length(subjects),
        
        fprintf('No. Training %d, test subject %d/%d\n', n_subj_train, subj_test, length(subjects));
        
        %% building the test set (on deceptive data)
        features_test = [];
        labels_test = {};
        for trial = 2:n_trial(subj_test),
            features_test = [features_test; features_sit{subj_test}{trial}; features_walk{subj_test}{trial}];
            labels_test = [labels_test; repmat({'2'},size(features_sit{subj_test}{trial},1),1); repmat({'1'},size(features_walk{subj_test}{trial},1),1)];
        end
               
       %% buidling the training sets

       train_set_original = [1:(subj_test-1), (subj_test+1):length(subjects)];
       
       train_set_all = nchoosek(train_set_original, n_subj_train);
       
       if n_btstp<=size(train_set_all,1),
            ind_train_set = randsample(1:size(train_set_all,1), n_btstp);
            train_set = train_set_all(ind_train_set, :);
       else
           train_set = zeros(n_btstp, n_subj_train);
           for i = 1:n_btstp,
               train_set(i,:) = randsample(train_set_original, n_subj_train, true);
           end
       end
       
       %% training the baseline models
       accuracy_btstp = zeros(n_btstp, 1);
       for i = 1:n_btstp,
           
           % building training feature sets
           features_train_sit = [];
           features_train_walk = [];
           for j=1:n_subj_train,
               features_train_sit = [features_train_sit; features_sit{train_set(i,j)}{1}];
               features_train_walk = [features_train_walk; features_walk{train_set(i,j)}{1}];
           end
           
           RF = TreeBagger(n_tree, [features_train_sit; features_train_walk], ...
               [repmat({'2'},size(features_train_sit,1),1); repmat({'1'},size(features_train_walk,1),1)]);
           
           [labelsRF, ~] = predict(RF, features_test);
           acc = strcmp(labelsRF,labels_test);
           
           accuracy_btstp(i) = mean(acc);
           
       end
       
       accuracy_baseline_subjtest(subj_test,:) = accuracy_btstp;
       
       %% training the expert models
       accuracy_btstp = zeros(n_btstp, 1);
       for i = 1:n_btstp,
           
           % building training feature sets
           features_train_sit = [];
           features_train_walk = [];
           for j=1:n_subj_train,
               for k = 1:n_trial(train_set(i,j)),
                   features_train_sit = [features_train_sit; features_sit{train_set(i,j)}{k}];
                   features_train_walk = [features_train_walk; features_walk{train_set(i,j)}{k}];
               end
           end
           
           RF = TreeBagger(n_tree, [features_train_sit; features_train_walk], ...
               [repmat({'2'},size(features_train_sit,1),1); repmat({'1'},size(features_train_walk,1),1)]);
           
           [labelsRF, ~] = predict(RF, features_test);
           acc = strcmp(labelsRF,labels_test);
           
           accuracy_btstp(i) = mean(acc);
           
       end
       
       accuracy_expert_subjtest(subj_test,:) = accuracy_btstp;
       
       
       
    end
    
    accuracy_baseline(n_subj_train, :, :) = accuracy_baseline_subjtest;
    accuracy_expert(n_subj_train, :, :) = accuracy_expert_subjtest;
    
    
end

if write_results,
    save('accuracy_paper', 'accuracy_baseline', 'accuracy_expert');
end