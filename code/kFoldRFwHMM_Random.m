%% NEW RF-HMM CODE for Train/Test - 1 Location Only (Belt) 
%Rev by Luca Lonini 11.18.2013
%ver2: Save RF and HMM models and accuracies
%ver3: Shows how many clips of each activity type we are removing
%Init HMM Emission Prob with PTrain from the RF and Run the RF+HMM on ALL data

%NOTE: Run initPmtk3.m after starting MATLAB

%Uses Matlab's RF

%% LOAD DATA AND INITIALIZE PARAMETERS

%Prepare Data (extract Clips and Features)
% dataPreprocessing
%Aggregate Data into a Struct
% classifierDataCreate

clc; clear all; close all;               %clean up

slashdir = '/';

currentDir = pwd; 
addpath([pwd slashdir 'sub']); %create path to helper scripts
addpath(genpath([slashdir 'Traindata'])); %add path for train data

tic;                                     %start timer


%hyper-parameters for SVM with radial basis functions
crossValType = 'kfold'; %subject or kfold
switch crossValType
    case 'kfold'
        c     = 10; %soft slack parameter
        g     = 1;  %width
        kfold = 3;  %number of folds to perform
    case 'subject'
        c = 10;
        g = 1;
        %number of folds is auto set to # of subjects
    otherwise
        error('improper cross validation type');
end

%additional options
clipThresh = 0.8; %to be in training set, clips must have >X% of label

%load the transition matrix (A)
% transitionFile = 'A_6Activity.xls';
transitionFile = 'A_8Activity.xls';
fprintf('HMM: Setting transition matrix according to %s\n', transitionFile);
A = xlsread(transitionFile);


%% LOAD DATA TO ANALYZE
% filename = 'trainData_LL_12_03_12_05_2013_7a';
% load (['Traindata' slashdir '7Activites' slashdir filename]);
load('train_data');

    %% FILTER DATA FOR APPROPRIATE CLASSIFICATION RUNTYPE
    
    cData = scaleFeatures(trainingClassifierData); %scale to [0 1]
       
    %remove data from other locations if required (old datasets)
%     cData = removeDataWithoutLocation(cData,'Belt');

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
    
    %specify the folds based on cross validation type
    switch crossValType
        case 'kfold'
            folds = kfold;
        case 'subject'
            folds = length(uniqSubjects);
        otherwise
            error('improper cross validation type');
    end
    
    %% SORT THE DATA FOR K-FOLDS OR SBJ-WISE + RF TRAIN/TEST
    

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
    stateBin      = cell(length(uniqStates),1);
    for i = 1:length(uniqStates)
        stateBin{i} = find(strcmp(uniqStates{i},statesTrue));
    end
    
    %do k fold cross validation for RF
    for k = 1:folds
        
        %begin making test set indices, every kth clip
        testInd       = zeros(ceil(length(statesTrue)/folds),1);
        testCount     = 1;
        count         = k; %shift count using k so we get a new test set every iteration
        testSet       = zeros(length(statesTrue),1);
        
        %create our test vector, grab every kth sample in each bin
        %this means we bin each type of state, then grab every kth sample
        %from within that bin. this prevents us from missing infreqeunt
        %states such as stand to sit and sit to stand
        switch crossValType
            case 'kfold'
                for i = 1:length(stateBin)
                    for j = 1:length(stateBin{i})
                        if mod(count,folds) == 0
                            testInd(testCount) = stateBin{i}(j);
                            testCount = testCount + 1;
                        end
                        count = count + 1;
                    end
                end
                
                %create a logical vector to indicate for clips in test set
                for i = 1:length(testSet)
                    if any(i == testInd)
                        testSet(i) = 1;
                    end
                end
                testSet = logical(testSet);
            case 'subject'
                testSet = strcmp(uniqSubjects{k},subjects);
        end
        
        %remove clips that are a mix of activities from training set
        %these were the clips that did not meet the 80% threshold
        TrainingSet = ~testSet;
        TrainingSet(removeInd) = 0;   %remove clips
        TrainingSet = logical(TrainingSet);
        
        %% RF TRAINING AND TESTING

        %TRAIN RF
        ntrees = 400;
        disp(['RF Train: ' crossValType ' ' num2str(k)]);
        RFmodel = TreeBagger(ntrees,features(TrainingSet,:),codesTrue(TrainingSet)');

        %RF Prediction and RF class probabilities for ENTIRE dataset. This is
        %for initializing the HMM Emission matrix (P_RF(TrainSet)) and for
        %computing the observations of the HMM (P_RF(TestSet))
        [codesRF,P_RF] = predict(RFmodel,features);
        codesRF = str2num(cell2mat(codesRF));
        statesRF = uniqStates(codesRF);
                
        %% RESULTS
        
        %create a confusion matrix of RF results (Test data)
        [matRF,accRF] = createConfusionMatrix(codesTrue(testSet),codesRF(testSet));

        %save true and predicted results as well as other runtype
        %information
        RFResults(k).model = RFmodel;  %save trained RF 
        RFResults(k).matRF = matRF;
        RFResults(k).accRF = accRF;
        RFResults(k).codesRF = codesRF;
        RFResults(k).codesTrue = codesTrue;
        RFResults(k).testSet = testSet;
        RFResults(k).trainSet = TrainingSet;
        RFResults(k).P_RF_Train = P_RF(TrainingSet,:); %class prob for training data (<80% threshold data is excluded)
        RFResults(k).P_RF_Test = P_RF(testSet,:);   %class prob for test data (k-th fold)
        
    end
    
    %% RUN HMM ON ALL DATA USING ONE OF THE ALREADY TRAINED RF
    
    disp('Run HMM')
    %Grab one trained RF
    k = 1;
    RFmodel = RFResults(k).model;
    %Grab train and test set to run the HMM
    TrainingSet = RFResults(k).trainSet;     %the Train set of the RF - remeber it does not contain below 80%thres clips
    PTrain = RFResults(k).P_RF_Train;         %The Emission Probabilities of the HMM

    %obtain predictions for all the data sequence    
    disp('Predict all data with the RF')
    [codesRF,P_RF] = predict(RFmodel,features);
    codesRF = str2num(cell2mat(codesRF));
    statesRF = uniqStates(codesRF);
    PTest = P_RF;
    
    %% HMM INIT AND TESTING
    

    %inialize parameters for hmm
    d       = length(uniqStates);   %number of symbols (=#states)
    nstates = d;                    %number of states
    mu      = zeros(d,nstates);     %mean of emission distribution
    sigma   = zeros(d,1,nstates);   %std dev of emission distribution
    Pi      = ones(length(uniqStates),1) ./ length(uniqStates); %uniform prior
    sigmaC  = .1;                   %use a constant std dev
    
    %create emission probabilities for HMM
    PBins  = cell(d,1);
%     PTrain = P_RF;
    
    %for each type of state we need a distribution
    for bin = 1:d
        clipInd         = strcmp(uniqStates{bin},statesTrue(TrainingSet));
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
       
    %% predict the states using the HMM
    disp('Predict all data using the HMM')
    [gamma, ~, ~, ~, ~]   = hmmInferNodes(HMMmodel,PTest');
    [statesHmm, codesHmm] = getPredictedStates(gamma',uniqStates);
    
    %% GET ALL THE RESULTS
    
    %entire classification matrix
    [matRF,accRF,labels] = createConfusionMatrix(codesTrue,codesRF);
    [matHmm,accHmm,labels] = createConfusionMatrix(codesTrue,codesHmm);
    
    results.stateCodes         = StateCodes;
%   OVERALL ACCURACY
    results.accHmm             = accHmm;
    results.accRF             = accRF;
    %CONFUSION MATRICES
    results.matRF             = matRF;
    results.matHmm             = matHmm;
    %PRED and ACTUAL CODES AND STATES
    results.codesRF           = codesRF;
    results.codesHmm           = codesHmm;
    results.codesTrue          = codesTrue;
    results.statesRF          = statesRF;
    results.statesHmm          = statesHmm;
    results.statesTrue         = statesTrue;


%% PLOT PREDICTED AND ACTUAL STATES
figure; hold on
plot(codesTrue,'.-g')
plot(codesRF+.1,'.-r')
plot(codesHmm+.2,'.-b')
legend('True','RF','HMM')
ylim([0.5 nstates+0.5]);
set(gca,'YTickLabel',StateCodes(:,1))

%display Accuracies
disp(results)
figure
bar([results.accRF results.accHmm]);
ylim([0.9 1])
set(gca,'XTickLabel',{'RF','RF+HMM'})

%Display % of each activity over all predictions  
Activity = StateCodes;
ActivityTrue = StateCodes;

for i = 1:size(StateCodes,1)
    ind = strcmp(results.statesHmm,Activity{i,1});
    Activity{i,2} = sum(ind)./size(ind,1)*100;
end
figure
bar(cell2mat(Activity(:,2)));
set(gca,'XTickLabel',Activity(:,1))
ylabel('% of time spent')

%Display Normalized Confusion matrices
%change name for plotting
% StateCodes{3,1} = 'Stairs';
correctones = sum(matRF,2);
correctones = repmat(correctones,[1 size(StateCodes,1)]);
figure; subplot(211); imagesc(matRF./correctones); colorbar
set(gca,'XTickLabel',StateCodes(:,1))
set(gca,'YTickLabel',StateCodes(:,1))
axis square
subplot(212); imagesc(matHmm./correctones); colorbar
set(gca,'XTickLabel',StateCodes(:,1))
set(gca,'YTickLabel',StateCodes(:,1))
axis square


%% SAVE TRAINED MODELS
Results.results = results;
Results.RFmodel = RFmodel;
Results.HMMmodel = HMMmodel;
% filename = ['Results_' cData.subject{1}]; 
% save(filename,'Results');

toc;