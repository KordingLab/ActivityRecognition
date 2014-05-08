%load data
clc
clear all
close all
tic
runTypes = {'All','Bag','Belt','Hand','Pocket'};
for m = 1:length(runTypes)
    runType = runTypes{m};
    filename = 'trainingClassifierData';
    load(filename);
    
    
    switch runType
        case 'All'
        case 'Pocket'
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Bag');
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Belt');
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Hand');
            trainingClassifierData = removeDataWithState(trainingClassifierData,'Hand/Misc');
        case 'Belt'
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Bag');
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Pocket');
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Hand');
            trainingClassifierData = removeDataWithState(trainingClassifierData,'Hand/Misc');
        case 'Bag'
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Belt');
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Pocket');
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Hand');
            trainingClassifierData = removeDataWithState(trainingClassifierData,'Hand/Misc');
        case 'Hand'
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Bag');
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Belt');
            trainingClassifierData = removeDataWithLocation(trainingClassifierData,'Pocket');
            trainingClassifierData = removeDataWithState(trainingClassifierData,'Hand/Misc');
        otherwise
            error('Bad runType argument');
    end
    %create indice bins for each state
    states = trainingClassifierData.states;
    uniqueStates = unique(states);
    stateBin = cell(length(uniqueStates),1);
    for i = 1:length(uniqueStates)
        stateBin{i} = find(strcmp(uniqueStates{i},states));
    end
    
    %create our test vector
    count = 1;
    testInd = [];
    for i = 1:length(stateBin)
        for j = 1:length(stateBin{i})
            
            %put this index in the test set
            if mod(count,10) == 0
                testInd(end + 1) = stateBin{i}(j);
            end
            count = count + 1;
        end
    end
    
    
    testVector = zeros(length(states),1);
    for i = 1:length(testVector)
        if any(i == testInd)
            testVector(i) = 1;
        end
    end
    
    %svm prediction
    
    yvec_nums = cell2vec(cellstr(trainingClassifierData.states)');
    c = 10;
    gamma = .1;
    [svmPredictedStates classifierFit P] = classify('svm',trainingClassifierData.features,...
        cellstr(trainingClassifierData.states)',testVector,c,gamma);
    
    %create way to get marginal probabilities
    splitPredicted = regexp(svmPredictedStates,'/','split');
    splitTruth = regexp(states,'/','split');
    
    activityCount = 0;
    wearingCount = 0;
    for i = 1:length(splitTruth)
        if strcmp(splitPredicted{i}(1),splitTruth{i}(1))
            wearingCount = wearingCount + 1;
        end
        
        if strcmp(splitPredicted{i}(2),splitTruth{i}(2))
            activityCount = activityCount + 1;
        end
    end
    accuracy{m}.all = sum(strcmp(states', svmPredictedStates)) / length(states);
    accuracy{m}.activity = activityCount / length(splitTruth);
    accuracy{m}.wearing = wearingCount / length(splitTruth);
    accuracy{m}.runType = runType;
    
end
toc
save('kFoldResults','accuracy');