%% NEW RF-HMM CODE for Train/Test - 1 Location Only (Belt)
%Rev by Luca Lonini 11.18.2013
%ver2: Save RF and HMM models and accuracies
%ver3: Shows how many clips of each activity type we are removing
%Init HMM Emission Prob with PTrain from the RF
%and Run the RF+HMM on ALL data
%ver TIME: grab data for folds sequentially over time

%Random Forest Toolbox Syntax
%function Y_hat = classRF_predict(X,model)
%requires 2 arguments
%X: data matrix
%model: generated via classRF_train function

%function model = classRF_train(X,Y,ntree,mtry, extra_options)
%requires 2 arguments and the rest 2 are optional
%X: data matrix
%Y: target values
%ntree (optional): number of trees (default is 500)
%mtry (default is max(floor(D/3),1) D=number of features in X)
%there are about 14 odd options for extra_options. Refer to tutorial_ClassRF.m to examine them

%% LOAD DATA AND INITIALIZE PARAMETERS

%Prepare Data (extract Clips and Features)
% dataPreprocessing
%Aggregate Data into a Struct
% classifierDataCreate

clc; clear all; close all;               %clean up
currentDir = pwd; 
addpath([pwd '\sub']); %create path to helper scripts
addpath(genpath('\Traindata')); %add path for train data

tic;                                     %start timer

folds = 3;                              %number of folds to perform
plotON = 1;                             %draw plots
drawplot.activities = 0;
drawplot.accuracy = 0;
drawplot.actvstime = 1;
drawplot.confmat = 1;

%additional options
clipThresh = 0.8; %to be in training set, clips must have >X% of label

%The HMM Transition Matrix (A)
transitionFile = 'A_5ActivityNSS.xlsx';
% transitionFile = 'A_7Activity.xlsx';
% transitionFile = 'A_6Activity_New2.xlsx';
% transitionFile = 'A_5Activity.xlsx';
A = xlsread(transitionFile);


%% LOAD DATA TO ANALYZE
load Traindata\7Activites\trainData_LL_12_03_12_05_2013NSS.mat

%% FILTER DATA FOR APPROPRIATE CLASSIFICATION RUNTYPE

cData = scaleFeatures(trainingClassifierData); %scale to [0 1]

%remove data from other locations if required (old datasets)
cData = removeDataWithoutLocation(cData,'Belt');


%create local variables for often used data
features     = cData.features; %features for classifier
subjects     = cData.subject;  %subject number
uniqSubjects = unique(subjects); %list of subjects
statesTrue = cData.activity;     %all the classifier data
uniqStates  = unique(statesTrue);          %set of states we have

%remove any clips that don't meet the training set threshold
%this is the %80 threshold in the paper
[cData, removeInd] = removeDataWithActivityFraction(cData,clipThresh);

%How many clips of each activity type we removed
for i = 1:length(uniqStates)
    indr = find(strcmp(trainingClassifierData.activity(removeInd),uniqStates(i)));
    indtot = find(strcmp(trainingClassifierData.activity,uniqStates(i)));
    removed = length(indr)/length(indtot)*100;
    disp([num2str(removed) ' % of ' uniqStates{i} ' Train data removed (<' num2str(clipThresh) '% of clip)'])
end

%% SORT THE DATA FOR K-FOLDS + RF TRAIN/TEST


%indices for test set
%set all to 0, we will specify test set soon
testSet     = false(length(statesTrue),1);

%get codes for the true states (i.e. make a number code for each state)
%and save code and state
codesTrue     = zeros(1,length(statesTrue));
for i = 1:length(statesTrue)
    codesTrue(i) = find(strcmp(statesTrue{i},uniqStates));
end

%Store Code and label of each unique State
StateCodes = cell(length(uniqStates),2);
StateCodes(:,1) = uniqStates;
StateCodes(:,2) = num2cell(1:length(uniqStates)); %sorted by unique

%bin all of the states so we can sample an equal number in kfolds
% stateBin      = cell(length(uniqStates),1);
% for i = 1:length(uniqStates)
%     stateBin{i} = find(strcmp(uniqStates{i},statesTrue));
% end

%do k fold cross validation for RF
for k = 1:folds
    
    
    %% Create Train and Test vector - Split dataset into k-folds
    testSet  = zeros(length(statesTrue),1);
    Nsamples = floor(length(statesTrue)/folds);   %# of samples in each fold
    testSet((k-1)*Nsamples+1:k*Nsamples) = 1;
    testSet = logical(testSet);
    
    %remove clips that are a mix of activities from training set
    %these were the clips that did not meet the 80% threshold
    TrainingSet = ~testSet;
    TrainingSet(removeInd) = 0;   %remove clips
    
    %% RF TRAINING AND TESTING
    
    %TRAIN RF
    ntrees = 100;
    mtry = 10;   %number of predictors sampled for spliting at each node.

    disp(['RF Train - fold '  num2str(k)]);
    RFmodel = classRF_train(features(TrainingSet,:),codesTrue(TrainingSet)',ntrees,mtry);
    
    %TEST RF (ENTIRE dataset)
    test_options.predict_all = 1; %returns prediction per tree AND votes
    [codesRF, votes, prediction_per_tree] = classRF_predict(features,RFmodel,test_options);
    P_RF = votes./RFmodel.ntree;  %Prob of each class (RF output)
    statesRF = uniqStates(codesRF);
    
    
    %% HMM INIT AND TESTING
    
    %inialize parameters for hmm
    d       = length(uniqStates);   %number of symbols (=#states)
    nstates = d;                    %number of states
    mu      = zeros(d,nstates);     %mean of emission distribution
    sigma   = zeros(d,1,nstates);   %std dev of emission distribution
    Pi      = ones(length(uniqStates),1) ./ length(uniqStates); %uniform prior
    sigmaC  = .1;                   %use a constant std dev
    PTrain = P_RF(TrainingSet,:);   %Emission prob = RF class prob for training data (! <80% threshold data is excluded)
    
    
    %create emission probabilities for HMM
    PBins  = cell(d,1);
    
    %for each type of state we need a distribution
    for bin = 1:d
        clipInd         = strcmp(uniqStates{bin},statesTrue(TrainingSet));
        PBins{bin,1}    = PTrain(clipInd,:);    %The emission probability of the HMM is the RF prob over training data
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
    
    %% predict the states on Testdata using the HMM
    disp(['HMM Train - fold '  num2str(k)]);
    
    PTest = P_RF(testSet,:);        %The observation sequence (Test data)
    [gamma, ~, ~, ~, ~]   = hmmInferNodes(HMMmodel,PTest');
    [statesHmm, codesHmm] = getPredictedStates(gamma',uniqStates);
    
    
    %% RESULTS for each k-fold
    %entire classification matrix (HMM prediction is run only on Test data)
    [matRF,accRF,labels] = createConfusionMatrix(codesTrue(testSet),codesRF(testSet));
    [matHmm,accHmm,labels] = createConfusionMatrix(codesTrue(testSet),codesHmm);
    
    results(k).stateCodes        = StateCodes;
    %OVERALL ACCURACY
    results(k).accRF             = accRF;
    results(k).accHmm            = accHmm;
    %CONFUSION MATRICES
    results(k).matRF             = matRF;
    results(k).matHmm            = matHmm;
    %PRED and ACTUAL CODES AND STATES
    results(k).treepred         = PTest;  %RF output on test dataset
    results(k).statesRF         = statesRF(testSet);
    results(k).statesHmm        = statesHmm;
    results(k).statesTrue         = statesTrue(testSet);
    results(k).trainingSet      = TrainingSet;
    results(k).testSet          = testSet;
%     results(k).codesTrue       = codesTrue(testSet);
%     results(k).codesRF         = codesRF(testSet);
%     results(k).codesHmm        = codesHmm;
%     
    disp(['accRF = ' num2str(accRF)]);
    disp(['accHmm = ' num2str(accHmm)]);
    
    
    %% PLOT PREDICTED AND ACTUAL STATES
    if plotON

        if drawplot.actvstime
            
            figure('name',['k-fold ' num2str(k)]); hold on
            plot(codesTrue(testSet),'.-g')
            plot(codesRF(testSet)+.1,'.-r')
            plot(codesHmm+.2,'.-b')
            legend('True','RF','HMM')
            ylim([0.5 nstates+0.5]);
            set(gca,'YTick',cell2mat(StateCodes(:,2))')
            set(gca,'YTickLabel',StateCodes(:,1))
        end
        
        %display Accuracies
        %         disp(results(k))
        if drawplot.accuracy
            
            figure;
            bar([accRF accHmm]);
            if accRF > 0.85 && accHmm > 0.85
                ylim([0.8 1])
            end
            set(gca,'XTickLabel',{'RF','RF+HMM'})
        end
        
        %Display % of each activity over all predictions
        if drawplot.activities
            
            Activity = StateCodes;
            ActivityTrue = StateCodes;
            
            for i = 1:size(StateCodes,1)
                ind = strcmp(results(k).statesHmm,Activity{i,1});
                Activity{i,2} = sum(ind)./size(ind,1)*100;
            end
            figure('name',['k-fold ' num2str(k)])
            bar(cell2mat(Activity(:,2)));
            set(gca,'XTickLabel',Activity(:,1))
            ylabel('% of time spent')
        end
        
        
        %Display Normalized Confusion matrices
        %change name for plotting
        % StateCodes{3,1} = 'Stairs';
        if drawplot.confmat
            
            figure('name',['k-fold ' num2str(k)]); hold on
            correctones = sum(matRF,2);
            correctones = repmat(correctones,[1 size(StateCodes,1)]);
            subplot(121); imagesc(matRF./correctones); colorbar
            set(gca,'XTickLabel',StateCodes(:,1))
            set(gca,'YTickLabel',StateCodes(:,1))
            axis square
            subplot(122); imagesc(matHmm./correctones); colorbar
            set(gca,'XTickLabel',StateCodes(:,1))
            set(gca,'YTickLabel',StateCodes(:,1))
            axis square
        end
    end
end

%Average accuracy over all folds
accRF = 0; accHmm = 0;
for i = 1:folds
    accRF = accRF + results(i).accRF;
    accHmm = accHmm + results(i).accHmm;
end
accRF = accRF/folds;
accHmm = accHmm/folds;
disp(['Mean (k-fold) accRF = ' num2str(accRF)]);
disp(['Mean (k-fold) accHmm = ' num2str(accHmm)]);


%% SAVE TRAINED MODELS
Results.results = results;
Results.RFmodel = RFmodel;
Results.HMMmodel = HMMmodel;
filename = ['Results_' cData.subject{1}];
save(filename,'Results');

toc