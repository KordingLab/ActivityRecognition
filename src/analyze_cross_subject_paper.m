clear;
close all;

os = 'lin';
% os = 'win';

subjects = {'SC', 'ED', 'MG', 'LL', 'PL', 'ML', 'DM', 'ES', 'DR', 'AR', 'SM', 'RK', 'BC', 'AT', 'MD'};

if strcmp(os, 'lin'),
    features_dir = '~/Dropbox/Data/FTC/features/archive/';
    models_dir = '~/Dropbox/Data/FTC/models/';
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

write_results = false;

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

n_subj_train_range = [1 13];%1:length(subjects)-1;

accuracy_baseline = zeros(length(n_subj_train_range), length(subjects), n_btstp);

accuracy_expert = zeros(length(n_subj_train_range), length(subjects), n_btstp);
precision_walk = zeros(length(n_subj_train_range), length(subjects), n_btstp);
precision_sit = zeros(length(n_subj_train_range), length(subjects), n_btstp);
recall_walk = zeros(length(n_subj_train_range), length(subjects), n_btstp);
recall_sit = zeros(length(n_subj_train_range), length(subjects), n_btstp);

cnt = 1;

for n_subj_train = n_subj_train_range,
   
    accuracy_baseline_subjtest = zeros(length(subjects), n_btstp);
    
    accuracy_expert_subjtest = zeros(length(subjects), n_btstp);
    precision_walk_expert_subjtest = zeros(length(subjects), n_btstp);
    precision_sit_expert_subjtest = zeros(length(subjects), n_btstp);
    recall_walk_expert_subjtest = zeros(length(subjects), n_btstp);
    recall_sit_expert_subjtest = zeros(length(subjects), n_btstp);
    
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
%        accuracy_btstp = zeros(n_btstp, 1);
%        for i = 1:n_btstp,
%            
%            % building training feature sets
%            features_train_sit = [];
%            features_train_walk = [];
%            for j=1:n_subj_train,
%                features_train_sit = [features_train_sit; features_sit{train_set(i,j)}{1}];
%                features_train_walk = [features_train_walk; features_walk{train_set(i,j)}{1}];
%            end
%            
%            RF = TreeBagger(n_tree, [features_train_sit; features_train_walk], ...
%                [repmat({'2'},size(features_train_sit,1),1); repmat({'1'},size(features_train_walk,1),1)]);
%            
%            [labelsRF, ~] = predict(RF, features_test);
%            acc = strcmp(labelsRF,labels_test);
%            
%            accuracy_btstp(i) = mean(acc);
%            
%        end
%        
%        accuracy_baseline_subjtest(subj_test,:) = accuracy_btstp;
       
       %% training the expert models
       accuracy_btstp = zeros(n_btstp, 1);
       precision_walk_btstp = zeros(n_btstp, 1);
       recall_walk_btstp = zeros(n_btstp, 1);
       precision_sit_btstp = zeros(n_btstp, 1);
       recall_sit_btstp = zeros(n_btstp, 1);
       
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
           
           % n_x_y : number of 'x' states detected as 'y'
           n_walk_walk = sum(strcmp(labelsRF(strcmp(labels_test, '1')),'1'));
           n_walk_sit = sum(strcmp(labelsRF(strcmp(labels_test, '1')),'2'));
           n_sit_sit = sum(strcmp(labelsRF(strcmp(labels_test, '2')),'2'));
           n_sit_walk = sum(strcmp(labelsRF(strcmp(labels_test, '2')),'1'));

           accuracy_btstp(i) = (n_walk_walk + n_sit_sit)/length(labels_test);
           precision_walk_btstp(i) = n_walk_walk/(n_walk_walk+n_sit_walk);
           recall_walk_btstp(i) = n_walk_walk/(n_walk_walk+n_walk_sit);
           precision_sit_btstp(i) = n_sit_sit/(n_walk_sit+n_sit_sit);
           recall_sit_btstp(i) = n_sit_sit/(n_sit_walk+n_sit_sit);
           
       end
       
       accuracy_expert_subjtest(subj_test,:) = accuracy_btstp;
       precision_walk_expert_subjtest(subj_test,:) = precision_walk_btstp;
       precision_sit_expert_subjtest(subj_test,:) = precision_sit_btstp;
       recall_walk_expert_subjtest(subj_test,:) = recall_walk_btstp;
       recall_sit_expert_subjtest(subj_test,:) = recall_sit_btstp;
       
    end
    
    accuracy_baseline(cnt, :, :) = accuracy_baseline_subjtest;
    
    accuracy_expert(cnt, :, :) = accuracy_expert_subjtest;
    precision_walk(cnt, :, :) = precision_walk_expert_subjtest;
    precision_sit(cnt, :, :) = precision_sit_expert_subjtest;
    recall_walk(cnt, :, :) = recall_walk_expert_subjtest;
    recall_sit(cnt, :, :) = recall_sit_expert_subjtest;
    
    cnt = cnt+1;
    
end

if write_results,
    save('accuracy_paper.mat', 'accuracy_baseline', 'accuracy_expert');
end

save('accuracy_1_13_paper.mat', 'accuracy_expert', 'precision_walk', 'precision_sit', 'recall_walk', 'recall_sit');