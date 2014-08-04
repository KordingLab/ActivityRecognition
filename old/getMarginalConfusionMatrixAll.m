%create marginal confusion matrices for joint
load kfoldresults3
statesHmm = finalResults(1,1).statesHmm;
statesTrue = finalResults(1,1).statesTrue;
statesSvm = finalResults(1,1).statesSvm;
%create way to get marginal probabilities
splitHmm        = regexp(statesHmm,'/','split');
splitTruth      = regexp(statesTrue,'/','split');
splitSvm        = regexp(statesSvm,'/','split');
activityCountSvm   = 0;
activityCountHmm   = 0;
wearingCountSvm    = 0;
wearingCountHmm    = 0;

len = size(splitTruth,1);
wearingTrue   = cell(len,1);
activityTrue  = cell(len,1);
wearingHmm    = cell(len,1);
activityHmm   = cell(len,1);
wearingSvm    = cell(len,1);
activitySvm   = cell(len,1);
for i = 1:length(splitTruth)
    wearingTrue{i}  = splitTruth{i}{1};
    activityTrue{i} = splitTruth{i}{2};
    wearingHmm{i}   = splitHmm{i}{1};
    activityHmm{i}  = splitHmm{i}{2};
    wearingSvm{i}   = splitSvm{i}{1};
    activitySvm{i}  = splitSvm{i}{2};
end

matActSvm = createConfusionMatrix(activityTrue,activitySvm);
matActHmm = createConfusionMatrix(activityTrue,activityHmm);

matLocSvm = createConfusionMatrix(wearingTrue,wearingSvm);
matLocHmm = createConfusionMatrix(wearingTrue,wearingHmm);

accWearingHmm = getMarginalWearing(activityHmm,activityTrue,wearingTrue);
accWearingSvm = getMarginalWearing(activitySvm,activityTrue,wearingTrue);
accActivityHmm = getMarginalActivity(wearingHmm,wearingTrue,activityTrue);
accActivitySvm = getMarginalActivity(wearingSvm,wearingTrue,activityTrue);
for i = 1:length(splitTruth)
    %activity wearing margin
    if strcmp(splitHmm{i}(1),splitTruth{i}(1))
        wearingCountHmm = wearingCountHmm + 1;
    end
    if strcmp(splitHmm{i}(2),splitTruth{i}(2))
        activityCountHmm = activityCountHmm + 1;
    end
    if strcmp(splitSvm{i}(1),splitTruth{i}(1))
        wearingCountSvm = wearingCountSvm + 1;
    end
    if strcmp(splitSvm{i}(2),splitTruth{i}(2))
        activityCountSvm = activityCountSvm + 1;
    end
end
accActivityMargSvm = activityCountSvm / length(splitTruth);
accWearingMargSvm  = wearingCountSvm / length(splitTruth);
accActivityMargHmm = activityCountHmm / length(splitTruth);
accWearingMargHmm  = wearingCountHmm / length(splitTruth);