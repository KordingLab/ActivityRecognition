function accuracy = getMarginalAccuracy(groundTruth,predictions)

%wearing accuracy
%1-5
%6-10
%11-16
%16-20
wearing{1} = [1:5];
wearing{2} = [6:10];
wearing{3} = [11:16];
wearing{4} = [17:21];

groundTruthBin = zeros(length(groundTruth),1);
predictionsBin = zeros(length(groundTruth),1);
for i = 1:length(groundTruth)
    for j = 1:size(wearing,2)
        if any(wearing{j} == groundTruth(i))
           groundTruthBin(i) = j;
        end
        if any(wearing{j} == predictions(i))
            predictionsBin(i) = j;
        end
    end
end
numWearingCorrect = sum(groundTruthBin == predictionsBin);
accuracy.wearing = 100 * numWearingCorrect / length(groundTruth);
%activity accuracy
%1,6,11,16
%2,7,12,17
%3,8,13,18
%4,9,14,19
%5,10,15,20
activity{1} = [1 6 12 17];
activity{2} = [2 7 13 18];
activity{3} = [3 8 14 19];
activity{4} = [4 9 15 20];
activity{5} = [5 10 16 21];
activity{6} = 11;

groundTruthBin = zeros(length(groundTruth),1);
predictionsBin = zeros(length(groundTruth),1);
for i = 1:length(groundTruth)
    for j = 1:size(activity,2)
        if any(activity{j} == groundTruth(i))
           groundTruthBin(i) = j;
        end
        if any(activity{j} == predictions(i))
            predictionsBin(i) = j;
        end
    end
end
numActivityCorrect = sum(groundTruthBin == predictionsBin);
accuracy.activity = 100 * numActivityCorrect / length(groundTruth);
