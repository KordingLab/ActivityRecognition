%load data
clc
clear all
close all
filename = 'trainingClassifierData';
load(filename);

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
testVector = logical(testVector);
[svmPredictedStates classifierFit P acc preStateTest] = classify('svm',trainingClassifierData.features,...
    cellstr(trainingClassifierData.states)',testVector,c,gamma);

%create way to get marginal probabilities
splitPredicted = regexp(svmPredictedStates,'/','split');
splitTruth = regexp(states(testVector),'/','split');

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
accuracy.activity = activityCount / length(splitTruth);
accuracy.wearing = wearingCount / length(splitTruth);
accuracy.all = sum(strcmp(svmPredictedStates',states(testVector)))/length(splitTruth);