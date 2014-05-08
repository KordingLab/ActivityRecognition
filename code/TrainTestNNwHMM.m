%% TRAIN RF AND HMM ON A COMPLETE DATASET (Do not use k-fold) AND TEST ON A NEW UNLABELED DATASET
%!UNLABELED VERSION (USE UNLABELED DATA FOR TEST PHASE)
% MATLAB Toolbox is used for RF

clc; clear all; close all;             

slashdir = '/';     %set to '/' for Linux and Mac, '\' for Windows

currentDir = pwd;
addpath([pwd slashdir 'sub']); %create path to helper scripts
addpath(genpath([slashdir 'Traindata'])); %add path for train data

%% INIT
%Load Train data
load('train_data'); %Data from the kfold experiment is used here solely for training

%Clip threshold options
clipThresh = 0.8; %to be in training set, clips must have >X% of label

% statistical normalization of features
cData = trainingClassifierData;
cData.features = scaleFeatures_v2(cData.features);

%remove any clips that don't meet the training set threshold
[cData, removeInd] = removeDataWithActivityFraction(cData,clipThresh);

%create local variables for often used data
features     = cData.features; %features for classifier
subjects     = cData.subject;  %subject number
uniqSubjects = unique(subjects); %list of subjects
statesTrue = cData.activity;     %all the classifier data
uniqStates  = unique(statesTrue);  %set of states we have


%How many clips of each activity type we removed
for i = 1:length(uniqStates)
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

%% TRAIN RF with standard parameters and save results 
% disp('RF Train');
% ntrees = 800;
% RFmodel = TreeBagger(ntrees,features,codesTrue', 'OOBVarImp', 'off');
% [codesRF,P_RF] = predict(RFmodel,features);
% codesRF = str2num(cell2mat(codesRF));
% statesRF = uniqStates(codesRF);

disp('NN Train');
net = patternnet([24],'trainlm','sse');
% Normalizing features prior to applying them to the NN
% features = features - ones(size(features,1),1)*mean(features);
% features = features./(ones(size(features,1),1)*std(features));
net = train(net, features', ind2vec(codesTrue));
P_NN = net(features');


%% TRAIN HMM (i.e. create HMM and set the emission prob as the RF output)
disp('HMM Train');

PTrain = P_NN';         %The Emission Probabilities of the HMM are the RF output prob on the train dataset

%load the transition matrix (A)
transitionFile = 'A_6Activity.xls';

A = xlsread(transitionFile);

%inialize parameters for hmm
d       = length(uniqStates);   %number of symbols (=#states)
nstates = d;                    %number of states
mu      = zeros(d,nstates);     %mean of emission distribution
sigma   = zeros(d,1,nstates);   %std dev of emission distribution
Pi      = ones(length(uniqStates),1) ./ length(uniqStates); %uniform prior
sigmaC  = .1;                   %use a constant std dev

%create emission probabilities for HMM
PBins  = cell(d,1);

%for each type of state we need a distribution
for bin = 1:d
    clipInd         = strcmp(uniqStates{bin},statesTrue);
    PBins{bin,1}    = PTrain(clipInd,:);
    mu(:,bin)       = mean(PBins{bin,1}); %mean
    sigma(:,:,bin)  = sigmaC; %set std dev
end

%create distribution for pmtk3 package
emission        = struct('Sigma',[],'mu',[],'d',[]);
emission.Sigma  = sigma;
emission.mu     = mu;
emission.d      = d;

%construct HMM using pmtk3 package
HMMmodel           = hmmCreate('gauss',Pi,A,emission);
HMMmodel.emission  = condGaussCpdCreate(emission.mu,emission.Sigma);
HMMmodel.fitType   = 'gauss';


%% TEST ON THE UNLABELED DATASET
clear trainingClassifierData cData features                  %clear old data

%load Test dataset(features) for classifier 
load('test_data');

% statistical normalization of features
cData = trainingClassifierData;
cData.features = scaleFeatures_v2(cData.features);

%create again local variables for often used data
features     = cData.features; %features for classifier
subjects     = cData.subject;  %subject number
uniqSubjects = unique(subjects); %list of subjects
uniqStates  = unique(statesTrue);  %set of states we have

%Run NN on the new test data and generate predictions
disp('Predict activites with NN - UNLABELED Dataset')
% Normalizing features prior to applying them to the NN
% features = features - ones(size(features,1),1)*mean(features);
% features = features./(ones(size(features,1),1)*std(features));
P_NN = net(features');
codesNN = vec2ind(P_NN);

PTest = P_NN';               %the observations of the HMM for the test data
statesNN = uniqStates(codesNN); %predicted states by the RF
disp('Done')

%% predict the states using the HMM
disp('Predict activites with HMM - UNLABELED Dataset')
[gamma, ~, ~, ~, ~]   = hmmInferNodes(HMMmodel,PTest');
[statesHmm, codesHmm] = getPredictedStates(gamma',uniqStates);
disp('Done')

%% GET ALL THE RESULTS

results.stateCodes = StateCodes;
results.codesRF = codesNN;
results.codesHmm = codesHmm;
results.statesRF = statesNN;
results.statesHmm = statesHmm;

%% PLOT PREDICTED AND ACTUAL STATES

clip_duration = 2;      %TO BE INCLUDED IN ClassifierData structure
t = 0:clip_duration:2*length(codesHmm)-clip_duration;
h=figure; hold on
set(h,'position',[2416         583         791         620]);
subplot 311; hold on;
imagesc(t, 1:size(features,2), features');
colormap gray;
axis tight;
subplot 312; hold on;
plot(t, codesNN, '.-r');
plot(t,codesHmm,'.-b');
xlabel('Time elapsed');
set(gca,'YTick',unique(codesNN));
set(gca,'YTickLabel',StateCodes(unique(codesNN),1));
legend('NN','HMM');
axis tight;
subplot 313; hold on;
plot(t/60,max(gamma));   %plot Max posterior for the class (HMM)
plot(t/60,max(P_NN',[],2),'r');   %plot Max posterior for the class (RF)
legend('HMM','NN')
axis tight;

%Display % of each activity over all predictions  
Activity = StateCodes;
ActivityTrue = StateCodes;

for i = 1:size(StateCodes,1)
    ind = strcmp(results.statesHmm,Activity{i,1});
    Activity{i,2} = sum(ind)./size(ind,1);
end
h=figure;
set(h,'position',[3219         582         560         420]);
bar(cell2mat(Activity(:,2)));
set(gca,'XTickLabel',Activity(:,1))

