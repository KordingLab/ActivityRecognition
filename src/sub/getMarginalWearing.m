function accuracy = getMarginalWearing(mainPred,mainTruth,marginalTruth)

bagCorrect        = 0;    bagTotal        = 0; 
beltCorrect       = 0;    beltTotal       = 0; 
handCorrect       = 0;    handTotal       = 0; 
pocketCorrect     = 0;    pocketTotal     = 0;  

for i = 1:length(mainTruth)
    if strcmp('Bag',marginalTruth{i})
        bagTotal = bagTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            bagCorrect = bagCorrect + 1;
        end
    end
    if strcmp('Belt',marginalTruth{i})
        beltTotal = beltTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            beltCorrect = beltCorrect + 1;
        end
    end
    if strcmp('Hand',marginalTruth{i})
        handTotal = handTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            handCorrect = handCorrect + 1;
        end
    end
    if strcmp('Pocket',marginalTruth{i})
        pocketTotal = pocketTotal + 1;
        if strcmp(mainTruth{i},mainPred{i})
            pocketCorrect = pocketCorrect + 1;
        end
    end
end

accuracy.bag = bagCorrect/bagTotal;
accuracy.belt = beltCorrect/beltTotal;
accuracy.hand = handCorrect/handTotal;
accuracy.pocket = pocketCorrect/pocketTotal;