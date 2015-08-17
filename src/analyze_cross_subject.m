clear;
close all;

subjects = {'SC', 'ED', 'MG', 'LL', 'PL', 'ML', 'DM', 'ES', 'DR', 'AR', 'SM', 'RK', 'BC', 'AT', 'MD'};

features_dir = '~/Dropbox/Data/FTC/features/archive/';

% clipping beginning and the end (in seconds)
clip_start = 1;
clip_end = 0;

% RF parameters
n_tree = 200;

% Running parameters
calculate_accuracies = false;
calculate_importance = true;
write_results = true;

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

for subj = 1:length(subjects),
    
    fprintf('Subject %d/%d\n', subj, length(subjects));
   
    % building the test sets
    if calculate_accuracies,
        k= 0;
        for subj_test = [1:(subj-1),(subj+1):length(subjects)],
            k = k+1;
            features_test{k} = [];
            labels_test{k} = [];
            for trial = 2:n_trial(subj_test),
                features_test{k} = [features_test{k}; features_sit{subj_test}{trial}; features_walk{subj_test}{trial}];
                labels_test{k} = [labels_test{k}; 2*ones(size(features_sit{subj_test}{trial},1),1); 1*ones(size(features_walk{subj_test}{trial},1),1)];
            end
        end
    end
    
    features_train = [];
    labels_train = [];
    
    for trial = 1:n_trial(subj),
        
        features_train = [features_train; features_sit{subj}{trial}; features_walk{subj}{trial}];
        labels_train = [labels_train; 2*ones(size(features_sit{subj}{trial},1),1); 1*ones(size(features_walk{subj}{trial},1),1)];
        
        if calculate_importance,
            RFmodel{subj}{trial} = TreeBagger(n_tree, features_train, labels_train, 'OOBVarImp', 'on');
        else
            RFmodel{subj}{trial} = TreeBagger(n_tree, features_train, labels_train, 'OOBVarImp', 'off');
        end
        
        % evaluating the model on test sets
        
        if calculate_accuracies,
            
            accuracy = zeros(1,length(subjects)-1);
            
            for subj_test = 1:length(subjects)-1,
                
                [labelsRF,~] = predict(RFmodel{subj}{trial},features_test{subj_test});
                labelsRF = str2double(labelsRF);
                
                acc = (labelsRF==labels_test{subj_test});
                accuracy(subj_test) = mean(acc);
                
            end
            
            accuracy_mean{subj}{trial} = mean(accuracy);
            accuracy_median{subj}{trial} = median(accuracy);
            accuracy_std{subj}{trial} = std(accuracy);
            accuracy_low{subj}{trial} = prctile(accuracy,5);
            accuracy_high{subj}{trial} = prctile(accuracy,95);
        
        end
        
    end
    
end

if write_results,
    if calculate_accuracies,
        save('accuracy_cross_subject', 'accuracy_mean', 'accuracy_median', 'accuracy_std', 'accuracy_low', 'accuracy_high', 'subjects');
    end
    if calculate_importance,
        load('~/Dropbox/Data/FTC/features/archive/baseline/F1_accgyr_baseline2.mat');
        features_labels=features_data.feature_labels;
        save('feature_importance', 'RFmodel', 'features_labels');
    end
end

