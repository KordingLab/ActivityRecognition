function accuracy = getMarginalActivity(mainPred,mainTruth,marginalTruth)

sit2StandCorrect  = 0;    sit2StandTotal  = 0;
sittingCorrect    = 0;    sittingTotal    = 0;
stand2SitCorrect  = 0;    stand2SitTotal  = 0;
standingCorrect   = 0;    standingTotal   = 0;
walkingCorrect    = 0;    walkingTotal    = 0;


for i = 1:length(mainPred)
    if strcmp('Sit to Stand',marginalTruth{i})
        sit2StandTotal = sit2StandTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            sit2StandCorrect = sit2StandCorrect + 1;
        end
    end
    if strcmp('Sitting',marginalTruth{i})
        sittingTotal = sittingTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            sittingCorrect = sittingCorrect + 1;
        end
    end
    if strcmp('Stand to Sit',marginalTruth{i})
        stand2SitTotal = stand2SitTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            stand2SitCorrect = stand2SitCorrect + 1;
        end
    end
    if strcmp('Standing',marginalTruth{i})
        standingTotal = standingTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            standingCorrect = standingCorrect + 1;
        end
    end
    if strcmp('Walking',marginalTruth{i})
        walkingTotal = walkingTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            walkingCorrect = walkingCorrect + 1;
        end
    end
end

accuracy.stand2Sit = stand2SitCorrect/stand2SitTotal;
accuracy.sitting = sittingCorrect/sittingTotal;
accuracy.sit2Stand = sit2StandCorrect/sit2StandTotal;
accuracy.standing = standingCorrect/standingTotal;
accuracy.walking = walkingCorrect/walkingTotal;
