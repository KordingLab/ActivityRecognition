%% COUPLING STAGE

%figure out (for each crossval) what wearing condition we predicted

%based on predicted wearing condition, send it through that svm classifier
%that we have saved

%then send that through and HMM model (activity only) that we have

%determine the results from that


%variables we need for this file
%SVM fits per subject per wearing condition
%HMM predictions for first round
%ground truth values
clc
clear
close all
%load hmm models
pocketHMMs = load('CV_HMM_Pocket');
beltHMMs = load('CV_HMM_Belt');
bagHMMs = load('CV_HMM_Bag');
handHMMs = load('CV_HMM_Hand');

%Create our test and training set
%Training set only includes clips with: activity fraction > threshold
results = load('CV_All');
hmmResults = load('CV_HMM_All');

for i = 1:12
    testClassifierData = results.results{1,i}.testClassifierData;
    hmmPredictions = hmmResults.hmmResults{1,i}.hmmPredictedStates;
    finalHMMPredictions = hmmPredictions;
    mapping = [4 3 2 1 5];
    %load the hmm built during cross validation for this subject
    pocketHMM = pocketHMMs.hmmResults{1,i};
    beltHMM   = beltHMMs.hmmResults{1,i};
    bagHMM    = bagHMMs.hmmResults{1,i};
    handHMM   = handHMMs.hmmResults{1,i};
    
    %figure out which classifiers we need for this subject
    pocketFile = ['svmPocket' num2str(i)];
    beltFile   = ['svmBelt' num2str(i)];
    handFile   = ['svmHand' num2str(i)];
    bagFile    = ['svmBag' num2str(i)];
    
    %load fits
    pocketFit = load(pocketFile);
    beltFit   = load(beltFile);
    handFit   = load(handFile);
    bagFit    = load(bagFile);
    
    %load states we are going to be working with
    
    %now we have both SVM and HMM fits
    %take the precited wearing condition and predict activities with that
    
    wearingConfigurations = {'Bag','Belt','Hand','Pocket'};
    for j = 1:length(wearingConfigurations)
        %laod in the states we are going to use on this run through
        
        filename = ['uniqueStates' wearingConfigurations{j}];
        load(filename);
        
        %% CHOOSE THE SVM AND HMM FIT
        if j == 1
            hmm = bagHMM;
            svm = bagFit.classifierFit;
        elseif j == 2
            hmm = beltHMM;
            svm = beltFit.classifierFit;
        elseif j ==3
            hmm = handHMM;
            svm = handFit.classifierFit;
        elseif j == 4
            hmm = pocketHMM;
            svm = pocketFit.classifierFit;
        end
        
        dualStr = regexp(hmmPredictions,'/','split');
        wearingPredictions = cell(length(dualStr),1);
        activityPredictions = cell(length(dualStr),1);
        for k = 1:length(dualStr)
            wearingPredictions{k} = dualStr{k}{1};
            activityPredictions{k} = dualStr{k}{2};
        end
        %get indices of data we need to test for this predicted wearing
        wearingInd = strcmp(wearingPredictions,wearingConfigurations{j});
        
        %grab data only with those indices for classification
        data = getDataWithIndices(testClassifierData,wearingInd);
        data = replaceStateWithState(data,'Hand/Misc','Null/Null');
        randLabelVec = rand(length(data.states),1);
        [prePredictedCodes, accuracy, P] = svmpredict(...
            randLabelVec,...
            data.features,...
            svm.fit, ['-b 1']);
       
        P = P(:,mapping);
        %correct the mapping proble
        for k = 1:length(prePredictedCodes)
            prePredictedCodes(k) = mapping(prePredictedCodes(k)); 
        end
        
         svmPredictedStates = uniqueStates(prePredictedCodes);
        %get our results, break into subsets for which they are not
        %continuous
        count = 1;
        prevStatus = 0;
        clear subset subsetInd numInd;
        subset{1} = [];
        
        for k = 1:length(wearingInd)
            if k == 1
                if wearingInd(k) == 1
                    prevStatus = 1;
                    subset{count}(end+1) = k;
                else
                    prevStatus = 0;
                end
            else
                %add one to this subset
                if prevStatus == 1 && wearingInd(k) == 1
                    subset{count}(end+1) = k;
                    prevStatus = 1;
                    %next time start in a new subset
                elseif prevStatus == 1 && wearingInd(k) == 0
                    count = count + 1;
                    subset{count} = [];
                    prevStatus = 0;
                    %begin a new subset
                elseif prevStatus == 0 && wearingInd(k) == 1
                    subset{count}(end+1) = k;
                    prevStatus = 1;
                else
                    prevStatus = 0;
                end
            end
        end
        for k = 1:length(subset)
            if ~isempty(subset{k})
                subsetInd{k} = subset{k};
            end
        end
        %smooth them with the hmm
        startInd = 1;
        count = 1;
        for k = 1:length(subsetInd)
            ind = startInd:startInd+length(subsetInd{k})-1;
            subP = P(ind,:);
            [gamma logp, alpha, beta, B] = hmmInferNodes(hmm.model,subP');
            [hmmPredictedStates{k} postPredictedCodes] = getPredictedStates(gamma',uniqueStates);
            startInd = startInd + length(subsetInd{k});
            
            for m = 1:length(hmmPredictedStates{k})
                store{count,1} = hmmPredictedStates{k}{m};
                count = count + 1;
            end
        end
        numInd = find(wearingInd);
%         for i = 1:length(store)
%            %ADJUST FOR  
%         end
%         
        
        for k = 1:length(numInd)
            if ~strcmp(finalHMMPredictions{numInd(k)},'Hand/Misc')
                finalHMMPredictions{numInd(k)} = store{k};
            end
        end
        
        
    end
    %for hand ignore any misc activities
    %take those hmm results, plug them back into the indices in which
    %we had them
    constat = 0;
    finalCodes = stateToCode(finalHMMPredictions);
    doPlot = 1;
    if doPlot
        load uniqueStatesAll
        figure(i);
        hold on
        groundTruth = results.results{1,i}.groundTruth;
        plot(results.results{1,i}.groundTruth-.2,'bo');
        plot(prePredictedCodes,'ro');
        plot(finalCodes+.2,'go');
        set(gca,'YTick',1:length(uniqueStates))
        set(gca,'YTickLabel',uniqueStates)
        
    end
    marginalAccuracy = getMarginalAccuracy(groundTruth,finalCodes);
    marginalAccuracy
end

