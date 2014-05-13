%% TRAIN RF AND HMM ON SEPARATE DATASETS

% MATLAB's toolbox is used for RF
% pmtk3 package is used for HMM

clc; clear all; close all;             

tic;

ntrees = 400;

addpath([pwd '/sub']); %create path to helper scripts

%% INIT
%Load Train data
load('train_data');

%Clip threshold options
clipThresh = 0.8; %to be in training set, clips must have >X% of label

% statistical normalization
trainingClassifierData.features = scaleFeatures(trainingClassifierData.features);

%remove any clips that don't meet the training set threshold
[trainingClassifierData, removeInd] = removeDataWithActivityFraction(trainingClassifierData,clipThresh);

%create local variables for often used data
features     = trainingClassifierData.features;
statesTrue = trainingClassifierData.activity;   
uniqStates  = unique(statesTrue); 

%How many clips of each activity type we removed
for i = 1:length(uniqStates),
    indr = find(strcmp(trainingClassifierData.activity(removeInd),uniqStates(i)));
    indtot = find(strcmp(trainingClassifierData.activity,uniqStates(i)));
    removed = length(indr)/length(indtot)*100;
    disp([num2str(removed) ' % of ' uniqStates{i} ' data removed'])
end

%get codes for the true states (i.e. make a number code for each state)
%and save code and state
codesTrue = zeros(1,length(statesTrue));
for i = 1:length(statesTrue)
    codesTrue(i) = find(strcmp(statesTrue{i},uniqStates));
end
%Store Code and label of each unique State
StateCodes = cell(length(uniqStates),2);
StateCodes(:,1) = uniqStates;
StateCodes(:,2) = num2cell(1:length(uniqStates)); %sorted by unique

%% TRAIN RF with standard parameters
disp(['RF Train with ' num2str(ntrees) ' trees...']);
RFmodel = TreeBagger(ntrees, features, codesTrue', 'OOBVarImp', 'off');
[codesRF, P_RF] = predict(RFmodel,features);  %Only probabilities are needed to train the HMM
codesRF = str2num(cell2mat(codesRF));

%% TRAIN HMM (i.e. create HMM and set the emission prob as the RF posteriors)
disp('HMM Train...');

%load the transition matrix
% transitionFile = 'A_6Activity.xls';
transitionFile = 'A_8Activity.xls';
% fprintf('HMM: Setting transition matrix according to %s\n', transitionFile);
A = xlsread(transitionFile);
% 
% %inialize parameters for hmm
% d       = length(uniqStates);   %number of symbols (=#states)
% nstates = d;                    %number of states
% mu      = zeros(d,nstates);     %mean of emission distribution
% sigma   = zeros(d,1,nstates);   %std dev of emission distribution
% Pi      = ones(length(uniqStates),1) ./ length(uniqStates); %uniform prior
% sigmaC  = .1;                   %use a constant std dev
% 
% %create emission probabilities for HMM
% % PBins  = cell(d,1);
% 
% %for each type of state we need a distribution
% for bin = 1:d
%     clipInd         = strcmp(uniqStates{bin},statesTrue);
% %     PBins{bin,1}    = P_RF(clipInd,:); %The Emission Probabilities of the HMM are the RF output prob on the train dataset
%     mu(:,bin)       = mean(P_RF(clipInd,:)); % training for means: setting emission dist. means to the means of probabilities given by RF
%     sigma(:,:,bin)  = sigmaC; % no training for std
% end
% 
% %set the parameters for pmtk3 package
% emission        = struct('Sigma',[],'mu',[],'d',[]);
% emission.Sigma  = sigma;
% emission.mu     = mu;
% emission.d      = d;
% 
% %construct HMM using pmtk3 package
% HMMmodel           = hmmCreate('gauss',Pi,A,emission);
% % what are the following two lines doing?
% HMMmodel.emission  = condGaussCpdCreate(emission.mu,emission.Sigma);
% HMMmodel.fitType   = 'gauss';

[TR, EM] = hmmestimate(codesRF, codesTrue);

%% TEST ON THE UNLABELED DATASET
clear trainingClassifierData cData features;

%load Test dataset(features) for classifier 
load('test_data');

%create local variables for often used data
features = trainingClassifierData.features; %features for classifier
activity = trainingClassifierData.activity;

%statistical normalization
features = scaleFeatures(features);

% Run RF on test data
disp('Predict activites with RF');
[codesRF,P_RF] = predict(RFmodel,features);
codesRF = str2num(cell2mat(codesRF));
statesRF = uniqStates(codesRF); %predicted states by the RF

%% predict the states using the HMM
disp('Predict activites with HMM');
% [gamma, ~, ~, ~, ~]   = hmmInferNodes(HMMmodel, P_RF');
% [statesHmm, codesHmm] = getPredictedStates(gamma',uniqStates);

% TR(TR==0) = eps;
TR = A;
EM = (eye(8,8)*(.5-.5/7)) + .5/7;
codesHmm = hmmviterbi(codesRF, TR, EM);

%% PLOT PREDICTED AND ACTUAL STATES

time_Res = 1;      %TO BE INCLUDED IN ClassifierData structure
t = 0:time_Res:time_Res*(length(codesHmm)-1);

h=figure; hold on;
set(h,'position',[2416         583         791         620]);

subplot 311; hold on;
imagesc(t, 1:size(features,2), features');
colormap gray;
set(gca, 'ytick', 1:size(features,2), 'yticklabel', trainingClassifierData.featureLabels);
axis tight;

subplot 312; hold on;
codesTrue = zeros(1,length(activity));
for i = 1:length(activity)
    codesTrue(i) = find(strcmp(activity{i},uniqStates));
end
plot(t,codesTrue,'.-g');
plot(t, codesRF, '.-r');
plot(t,codesHmm,'.-b');
xlabel('Time elapsed');
set(gca,'YTick',unique(codesRF));
set(gca,'YTickLabel',StateCodes(unique(codesRF),1));
legend('RF','HMM');
axis tight;

subplot 313; hold on;
plot(t/60,max(gamma));   %plot Max posterior for the class (HMM)
plot(t/60,max(P_RF,[],2),'r');   %plot Max posterior for the class (RF)
legend('HMM','RF');
axis tight;

%Display % of each activity over all predictions  
Activity_Percentage = StateCodes;
for i = 1:size(StateCodes,1)
    ind = strcmp(statesHmm, Activity_Percentage{i,1});
    Activity_Percentage{i,2} = sum(ind)./size(ind,1);
end
h=figure;
set(h,'position',[3216         671         560         420]);
bar(cell2mat(Activity_Percentage(:,2)));
set(gca,'XTickLabel',Activity_Percentage(:,1))

%Display the confusion matrix
h = figure;
set(h,'position',[3217         163         560         420]);
mat = confusionmat(codesTrue, codesHmm);
imagesc(mat);
colormap gray;
textStrings = num2str(mat(:),'%0.2f');
textStrings = strtrim(cellstr(textStrings));  % Remove any space padding
[x,y] = meshgrid(1:size(mat,1));   % Create x and y coordinates for the strings
hStrings = text(x(:),y(:),textStrings(:),...      % Plot the strings
                'HorizontalAlignment','center');
midValue = mean(get(gca,'CLim'));  % Get the middle value of the color range
textColors = repmat(mat(:) < midValue,1,3);  % Choose white or black for the
                                             % text color of the strings so
                                             % they can be easily seen over
                                             % the background color
set(hStrings,{'Color'},num2cell(textColors,2));
xlabel('Predicted'); ylabel('True');
set(gca, 'xtick', 1:length(unique(codesTrue)), 'xticklabel', uniqStates(unique(codesTrue)));
set(gca, 'ytick', 1:length(unique(codesTrue)), 'yticklabel', uniqStates(unique(codesTrue)));

%printing RF accuracy, precision and recall for each class
fprintf('\n**************** RF accuracy:\n');
k = 0;
activities = StateCodes(unique(codesTrue),1);
for i=unique(codesTrue),
    k = k+1;
    tp = sum(codesTrue(codesRF==i)==i);
    tn = sum(codesTrue(codesRF~=i)~=i);
    fp = sum(codesTrue(codesRF==i)~=i);
    fn = sum(codesTrue(codesRF~=i)==i);
    prec(k) = tp/(tp+fp);
    rec(k) = tp/(tp+fn);
    acc(k) = (tp+tn)/(tp+tn+fp+fn);
    fprintf('%s:\n', activities{k});
    fprintf('Accuracy = %.2f  ', acc(k));
    fprintf('Precision = %.2f  ', prec(k));
    fprintf('Recall = %.2f  ', rec(k));
    fprintf('F1 score = %.2f\n', 2*prec(k)*rec(k)/(prec(k)+rec(k)));
end
fprintf('Overall:\n');
fprintf('   Accuracy = %.2f\n', sum(codesRF==codesTrue')/length(codesTrue));
fprintf('   Avg Class Accuracy = %.2f\n', mean(acc));
fprintf('   Precision = %.2f\n', mean(prec));
fprintf('   Recall = %.2f\n', mean(rec));
fprintf('   F1 score = %.2f\n', 2*mean(prec)*mean(rec)/(mean(prec)+mean(rec)));

%printing HMM accuracy, precision and recall for each class
fprintf('\n**************** HMM accuracy:\n');
k = 0;
for i=unique(codesTrue),
    k = k+1;
    tp = sum(codesTrue(codesHmm==i)==i);
    tn = sum(codesTrue(codesHmm~=i)~=i);
    fp = sum(codesTrue(codesHmm==i)~=i);
    fn = sum(codesTrue(codesHmm~=i)==i);
    prec(k) = tp/(tp+fp);
    rec(k) = tp/(tp+fn);
    acc(k) = (tp+tn)/(tp+tn+fp+fn);
    fprintf('%s:\n', activities{k});
    fprintf('Accuracy = %.2f  ', acc(k));
    fprintf('Precision = %.2f  ', prec(k));
    fprintf('Recall = %.2f  ', rec(k));
    fprintf('F1 score = %.2f\n', 2*prec(k)*rec(k)/(prec(k)+rec(k)));
end
fprintf('Overall:\n');
fprintf('   Accuracy = %.2f\n', sum(codesHmm==codesTrue')/length(codesTrue));
fprintf('   Avg Class Accuracy = %.2f\n', mean(acc));
fprintf('   Precision = %.2f\n', mean(prec));
fprintf('   Recall = %.2f\n', mean(rec));
fprintf('   F1 score = %.2f\n', 2*mean(prec)*mean(rec)/(mean(prec)+mean(rec)));

toc;