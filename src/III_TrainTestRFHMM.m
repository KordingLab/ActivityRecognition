%% TRAIN AND TEST RF+HMM ON SEPARATE DATASETS

% MATLAB's toolbox is used for RF
% MATLAB's toolbox is used for HMM

clc; clear all; close all;

tic;

ntrees = 50;   %number of trees for Random Forest

addpath([pwd '/sub']); %Add path to helper scripts

send_to_server = true;

%% INIT
%Load Train data
load('train_data');

%Clip threshold options
clipThresh = 0.8; %to be in training set, clips must have >X% of label

% remove any clips that don't meet the training set threshold
[TrainData, removeInd] = removeDataWithActivityFraction(TrainData,clipThresh);

% create local variables for often used data
features     = TrainData.features;
featureLabels = TrainData.featureLabels;
statesTrue = TrainData.activity;
uniqStates  = unique(statesTrue);

% How many clips of each activity class have we removed?
for i = 1:length(uniqStates),
    indr = find(strcmp(statesTrue(removeInd), uniqStates(i)));
    indtot = find(strcmp(statesTrue, uniqStates(i)));
    removed = length(indr)/length(indtot)*100;
    disp([num2str(removed) ' % of ' uniqStates{i} ' data removed'])
end

%Normalization
% features = scaleFeatures(features);

%get codes for the true states
codesTrue = zeros(1,length(statesTrue));
for i = 1:length(statesTrue)
    codesTrue(i) = find(strcmp(statesTrue{i}, uniqStates));
end

%Store code and label of each unique State
StateCodes = cell(length(uniqStates),2);
StateCodes(:,1) = uniqStates;
StateCodes(:,2) = num2cell(1:length(uniqStates)); %sorted by unique

%% TRAIN RF with standard parameters
disp(['Training RF model with ' num2str(ntrees) ' trees ...']);
RFmodel = TreeBagger(ntrees, features, codesTrue', 'PredictorNames', upper(featureLabels), 'OOBVarImp', 'off');
% RFmodel = fitensemble(features, codesTrue', 'AdaBoostM1', ntrees, 'Tree');
[codesRF, P_RF] = predict(RFmodel,features);  %Only probabilities are needed to train the HMM
codesRF = str2num(cell2mat(codesRF));

%% TRAIN HMM (i.e. create HMM and set the emission prob as the RF posteriors)
disp('Training HMM ...');

%load the transition matrix
transitionFile = 'A_8Activity.xls';
fprintf('HMM: Setting transition matrix according to %s\n', transitionFile);
A = xlsread(transitionFile);

% training HMM on train data
% [TR, EM] = hmmestimate(codesRF, codesTrue);

%% TEST ON THE UNLABELED DATASET
clear trainingClassifierData cData features;

%load Test dataset(features) for classifier 
load('test_data');

%create local variables for often used data
features = TestData.features; %features for classifier
activity = TestData.activity;

%statistical normalization
% features = scaleFeatures(features);

% Run RF on test data
disp('Predict activites with RF');
[codesRF,P_RF] = predict(RFmodel,features);
codesRF = str2num(cell2mat(codesRF));
statesRF = uniqStates(codesRF); %predicted states by the RF

%% predict the states using the HMM
disp('Predict activites with HMM');

% discarding the trained transition and emission matrices, and using
% hand-crafted ones (basically, using the HMM as an LPF)
TR = A;
EM = (eye(8,8)*(.5-.5/7)) + .5/7;
codesHmm = hmmviterbi(codesRF, TR, EM);

%% VISUALIZATION

time_Res = 1;      %TO BE INCLUDED IN ClassifierData structure
t = 0:time_Res:time_Res*(length(codesHmm)-1);

h=figure; hold on;
set(h,'position',[2416         583         791         620]);

subplot 311; hold on;
imagesc(t, 1:size(features,2), features');
colormap gray;
set(gca, 'ytick', 1:size(features,2), 'yticklabel', TestData.featureLabels);
axis tight;

subplot 312; hold on;
codesTrue = zeros(1,length(activity));
for i = 1:length(activity)
    codesTrue(i) = find(strcmp(activity{i},uniqStates));
end
plot(t,codesTrue,'*g','markersize',5);
plot(t, codesRF, '.-r');
plot(t,codesHmm,'.-b');
xlabel('Time elapsed');
set(gca,'YTick',unique(codesRF));
set(gca,'YTickLabel',StateCodes(unique(codesRF),1));
legend('True','RF','HMM');
axis tight;
grid on;

subplot 313; hold on;
% plot(t/60,max(gamma));   %plot Max posterior for the class (HMM)
post = max(P_RF,[],2);
plot(t/60, post, 'r');   %plot Max posterior for the class (RF)
plot(t/60, smooth(post, 100));
% legend('HMM','RF');
axis tight;
ylabel('confidence');

%Display % of each activity over all predictions  
Activity_Percentage = StateCodes;
for i = 1:size(StateCodes,1)
    ind = strcmp(uniqStates(codesHmm), Activity_Percentage{i,1});
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
fprintf('   Accuracy = %.2f\n', sum(codesHmm==codesTrue)/length(codesTrue));
fprintf('   Avg Class Accuracy = %.2f\n', mean(acc));
fprintf('   Precision = %.2f\n', mean(prec));
fprintf('   Recall = %.2f\n', mean(rec));
fprintf('   F1 score = %.2f\n', 2*mean(prec)*mean(rec)/(mean(prec)+mean(rec)));

if send_to_server,
    result = SendToServer(RFmodel, TrainData, sum(codesHmm==codesTrue)/length(codesTrue));
    disp('JSON object created.');
end

toc;