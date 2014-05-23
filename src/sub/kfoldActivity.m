%load data
clc
clear all
close all
filename = 'trainingClassifierData';
load(filename);

%create indice bins for each state
states = trainingClassifierData.activity;
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
       if mod(count,5) == 0
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

yvec_nums = cell2vec(cellstr(trainingClassifierData.activity)');
c = 10;
gamma = .1;
testVector = logical(testVector);
[svmPredictedStates classifierFit P acc preStateTest] = classify('svm',trainingClassifierData.features,...
    cellstr(trainingClassifierData.activity)',testVector,c,gamma);

% create way to get marginal probabilities
splitPredicted = regexp(svmPredictedStates,'/','split');
splitTruth = regexp(states','/','split');

activityCount = 0;
wearingCount = 0;
trueActivity = trainingClassifierData.activity(testVector);
trueWearing = trainingClassifierData.wearing(testVector);

bagInd = find(strcmp(trueWearing,'Bag'));
beltInd = find(strcmp(trueWearing,'Belt'));
handInd = find(strcmp(trueWearing,'Hand'));
pocketInd = find(strcmp(trueWearing,'Pocket'));

bagCount = 0;
for i = 1:length(bagInd)
    if strcmp(svmPredictedStates{bagInd(i)},trueActivity{bagInd(i)})
        bagCount = bagCount + 1;
    end
end
bagAcc = bagCount / length(bagInd);

beltCount = 0;
for i = 1:length(beltInd)
    if strcmp(svmPredictedStates{beltInd(i)},trueActivity{beltInd(i)})
        beltCount = beltCount + 1;
    end
end
beltAcc = beltCount / length(beltInd);

handCount = 0;
for i = 1:length(handInd)
    if strcmp(svmPredictedStates{handInd(i)},trueActivity{handInd(i)})
        handCount = handCount + 1;
    end
end
handAcc = handCount / length(handInd);


pocketCount = 0;
for i = 1:length(pocketInd)
    if strcmp(svmPredictedStates{pocketInd(i)},trueActivity{pocketInd(i)})
        pocketCount = pocketCount + 1;
    end
end
pocketAcc = pocketCount / length(pocketInd);

trueVals = zeros(1,length(states));
for i = 1:length(states)
    trueVals(i) = find(strcmp(states{i},uniqueStates));
end

matchingIndex = zeros(length(uniqueStates),1);
mappingIndex = zeros(length(uniqueStates),1);
for i = 1:length(uniqueStates)
    state = uniqueStates{i};
    try
        matchingIndex(i,1) = find(strcmp(state,svmPredictedStates),1);
    catch
        matchingIndex(i,1) = 0;
    end
    try
        [maxVal,mappingIndex(i,1)] = max(P(matchingIndex(i,1),:));
    catch
        mappingIndex(i,1) = 0;
    end
end
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
[vals,testVals] = max(testP,[],2);
truth = trueVals(testVector)';
stateVec = states(testVector);
[cmat, acc] = createConfusionMatrix(stateVec, svmPredictedStates);