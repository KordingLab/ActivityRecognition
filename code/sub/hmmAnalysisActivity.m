%% CLEAN UP AND LOADING
clear all
close all
clc

%Types of models we want to run. All includes all wearing configurations
runTypes = {'Bag','Belt','Hand','Pocket'};
% runTypes = {'Activity'};
%Do you want to see plots?
doPlot = 1;
doSvmDisplay = 0;
doHmmDisplay = 0;
doFinalDisplay = 1;
%% CREATING HMMS AND TEST OUT OF FIRST SVM
svmCon = zeros(5);
hmmCon = zeros(5);
%cycle through each type of wearing configuration
for m = 1:length(runTypes)
    
    runType = runTypes{m};                  %select the current run type
    load(['CV_' runType]);                  %load file with classifiers
    load(['uniqueStates' runType]);         %load associated state vector
    
    %cycle through each subject (this is across subject validation)
    %the SVM we load and the HMM we build changes each time
    for k = 1:12
        
        %display subject number
        disp(['Iteration: ' runType ' ' num2str(k)]);
        
        %grab values from SVM results
        trainClassifierData = results{1,k}.trainClassifierData;
        svmInitialClassificationP = results{1,k}.svmInitialClassificationP; %training set
        P = results{1,k}.P; %test set
        svmPredictedStates = results{1,k}.svmPredictedStates;
        groundTruth = results{1,k}.groundTruth;
        svmPredictedCodes = zeros(length(svmPredictedStates),1);
        
        %begin initializing/creating our HMM
        d = length(uniqueStates);
        nstates = d;
        mu = zeros(d,nstates);
        sigma = zeros(d,1,nstates);
        Pi = ones(length(uniqueStates),1) ./ length(uniqueStates);
        
        %LIBSVM left some of the states and codes in incorrect orders
        %fix: check highest SVM predicted probability for each type of
        %state, and remap the predictions back to their right states
        
        %remapping for the training data
        matchingIndex = zeros(length(uniqueStates),1);
        mappingIndex = zeros(length(uniqueStates),1);
        for i = 1:length(uniqueStates)
            state = uniqueStates{i};
            matchingIndex(i,1) = find(strcmp(state,svmPredictedStates),1);
            [maxVal,mappingIndex(i,1)] = max(svmInitialClassificationP(matchingIndex(i,1),:));
            indices = find(strcmp(state,svmPredictedStates));
            svmPredictedCodes(indices,1) = i;
        end
        trainMap = mappingIndex;
        trainingP = svmInitialClassificationP(:,trainMap);
        
        %remapping for the test data
        %extra catch in case the classifier does not predicted a state
        %luckily only 1 state was not predicted and we can fill it in by
        %process of elimination       
        matchingIndex = zeros(length(uniqueStates),1);
        mappingIndex = zeros(length(uniqueStates),1);
        svmTestCodes = results{1,k}.prePredictedCodes;
        svmTestStates = results{1,k}.prePredictedStates;
        svmTestCodesCheck = zeros(length(svmTestCodes),1);
        for i = 1:length(uniqueStates)
            state = uniqueStates{i};
            try
                matchingIndex(i,1) = find(strcmp(state,svmTestStates),1);
            catch
                matchingIndex(i,1) = 0;
            end
            try
                [maxVal,mappingIndex(i,1)] = max(P(matchingIndex(i,1),:));
            catch
                mappingIndex(i,1) = 0;
            end
            indices = find(strcmp(state,svmTestStates));
            svmTestCodesCheck(indices,1) = i;
        end
        check = all(svmTestCodesCheck == svmTestCodes);
        if any(mappingIndex == 0)
            ind = find(mappingIndex == 0);
            for y = 1:length(mappingIndex)
                if ~any(mappingIndex == y)
                    mappingIndex(ind) = y;
                end
            end
        end
        testMap = mappingIndex;
        testP = P(:,testMap);
        
        %load the correct transition matrix
        transitionFile = 'A.xlsx';
        if strcmp(runType,'All')
            %20x20 matrix
            [A,T,R] = xlsread(transitionFile,'Sheet2');
        elseif strcmp(runType,'Activity')
            [A,T,R] = xlsread(transitionFile,'Sheet4');
        else
            %5x5 matrix
            [A,T,R] = xlsread(transitionFile,'Sheet3');
        end
        
        %create emission probabilities for HMM
        sigmaConstant = .1;
        clipProbabilityList = cell(d,1);
        for clipType = 1:d
            clipIndices = strcmp(uniqueStates{clipType},...
                trainClassifierData.activity);
            clipProbabilityList{clipType,1} = trainingP(clipIndices,:);
            mu(:,clipType) = mean(clipProbabilityList{clipType,1});
            sigma(:,:,clipType) = sigmaConstant;
        end
        emission = struct('Sigma',[],'mu',[],'d',[]);
        emission.Sigma = sigma;
        emission.mu = mu;
        emission.d = d;
        
        %construct HMM using pmtk3 package
        model = hmmCreate('gauss',Pi,A,emission);
        model.emission =  condGaussCpdCreate(emission.mu,emission.Sigma);
        model.fitType = 'gauss';
        
        %predict the states using the HMM
        [gamma logp, alpha, beta, B] = hmmInferNodes(model,testP');
        [postPredictedStates postPredictedCodes] = getPredictedStates(gamma',uniqueStates);

        %construct plots
        if doPlot
            figure(k);
            clf;
            plot(groundTruth-.2,'bo');
            hold on
            plot(results{1,k}.prePredictedCodes,'ro');
            plot(postPredictedCodes+.2,'go');
            legend('True State','SVM','SVM+HMM')
            set(gca,'YTick',1:length(uniqueStates))
            set(gca,'YTickLabel',uniqueStates)
            pause(.5);
        end
        
        HMMaccuracy = sum(postPredictedCodes == groundTruth) * 100 / length(groundTruth);
        SVMaccuracy = sum(results{1,k}.prePredictedCodes == groundTruth) * 100 / length(groundTruth);
        
%         marginalAccuracySvm = getMarginalAccuracy(groundTruth,results{1,k}.prePredictedCodes);
        SVMfinalAccuracy.allVec(k) = SVMaccuracy;
%         SVMfinalAccuracy.activityVec(k) = marginalAccuracySvm.activity;
%         SVMfinalAccuracy.wearingVec(k) = marginalAccuracySvm.wearing;
        
%         marginalAccuracyHmm = getMarginalAccuracy(groundTruth,postPredictedCodes);
        HMMfinalAccuracy.allVec(k) = HMMaccuracy;
%         HMMfinalAccuracy.activityVec(k) = marginalAccuracyHmm.activity;
%         HMMfinalAccuracy.wearingVec(k) = marginalAccuracyHmm.wearing;
        
        %display results
        if doSvmDisplay
            disp(['SVM: ' num2str(SVMaccuracy)]);
%             disp(['Activity: ' num2str(marginalAccuracySvm.activity)]);
%             disp(['Wearing: ' num2str(marginalAccuracySvm.wearing)]);
            disp('');
        end
        if doHmmDisplay
            disp(['HMM: ' num2str(HMMaccuracy)]);
%             disp(['Activity: ' num2str(marginalAccuracy.activity)]);
%             disp(['Wearing: ' num2str(marginalAccuracy.wearing)]);
            disp('');
            disp('');
            disp('----------------');
        end
        
        hmmResults{1,k}.hmmPredictedStates = postPredictedStates;
        hmmResults{1,k}.hmmPredictedCodes = postPredictedCodes;
        hmmResults{1,k}.groundTruth = groundTruth;
        hmmResults{1,k}.model = model;
        hmmResults{1,k}.trainMap = trainMap;
        hmmResults{1,k}.testMap = testMap;
        
        wearing = {'Bag','Belt','Hand','Pocket'};
        wearingAcc = zeros(length(wearing),1);
        for w = 1:length(wearing)
            %get indices for wearing condition
            tempInd = find(strcmp(wearing{w},results{1,k}.testClassifierData.wearing));
            
            %take those indices, find out how many we got right in
            %predicted codes
            numRight = sum(postPredictedCodes(tempInd) == groundTruth(tempInd));
            numSVMRight = sum(svmTestCodes(tempInd) == groundTruth(tempInd));
            svmWearAcc(k,w) = numSVMRight / length(tempInd);
            wearingAcc(w) = numRight / length(tempInd);
            wearVec(k,w) = wearingAcc(w);
        end
        hmmResults{1,k}.wearingAccuracies = wearingAcc;
        hmmResults{1,k}.wearingLabels = wearing;
        [hmmConTemp acc] = createConfusionMatrix(groundTruth,postPredictedCodes);
        hmmCon = hmmCon + hmmConTemp;
        svmCon = svmCon + results{1,k}.preCon;
    end
    
    %save hmm results
    filename = ['CV_HMM_' runType];
    save(filename,'hmmResults');
    
    SVMfinalAccuracy.all = mean(SVMfinalAccuracy.allVec);
%     SVMfinalAccuracy.activity = mean(SVMfinalAccuracy.activityVec);
%     SVMfinalAccuracy.wearing = mean(SVMfinalAccuracy.wearingVec);
 
    HMMfinalAccuracy.all = mean(HMMfinalAccuracy.allVec);
%     HMMfinalAccuracy.activity = mean(HMMfinalAccuracy.activityVec);
%     HMMfinalAccuracy.wearing = mean(HMMfinalAccuracy.wearingVec);
    
    finalWearingAccuracies =  mean(wearVec);
    svmWearing = mean(svmWearAcc)
    if doFinalDisplay
        SVMfinalAccuracy
        HMMfinalAccuracy
    end
end