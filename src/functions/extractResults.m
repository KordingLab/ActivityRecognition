%extract results

load CV_HMM_Pocket
activities = {'Sit to Stand' ...
              'Sitting'      ...
              'Stand to Sit' ...
              'Standing'     ...
              'Walking'};
cmatPocket = zeros(5);
for i = 1:12
    res = hmmResults{1,i};
    truth = res.groundTruth;
    predicted = res.hmmPredictedCodes;
    [cmat, acc] = createConfusionMatrix(truth,predicted);
    cmatPocket = cmatPocket + cmat;
end

load CV_HMM_Hand
cmatHand = zeros(5);
for i = 1:12
    res = hmmResults{1,i};
    truth = res.groundTruth;
    predicted = res.hmmPredictedCodes;
    [cmat, acc] = createConfusionMatrix(truth,predicted);
    cmatHand = cmatHand + cmat;
end

load CV_HMM_Belt
cmatBelt = zeros(5);
for i = 1:12
    res = hmmResults{1,i};
    truth = res.groundTruth;
    predicted = res.hmmPredictedCodes;
    [cmat, acc] = createConfusionMatrix(truth,predicted);
    cmatBelt = cmatBelt + cmat;
end

load CV_HMM_Bag
cmatBag = zeros(5);
for i = 1:12
    res = hmmResults{1,i};
    truth = res.groundTruth;
    predicted = res.hmmPredictedCodes;
    [cmat, acc] = createConfusionMatrix(truth,predicted);
    cmatBag = cmatBag + cmat;
end

