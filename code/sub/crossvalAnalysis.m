%% script to run parallel cross validation
runTypes = {'All','Bag','Belt','Hand','Pocket'};
runTypes = {'All'};
for i = 1:length(runTypes)
    runType = runTypes{i};
    job1  = svmAnalysis(1,10,.1,runType);
    job2  = svmAnalysis(2,10,.1,runType);
    job3  = svmAnalysis(3,10,.1,runType);
    job4  = svmAnalysis(4,10,.1,runType);
    job5  = svmAnalysis(5,10,.1,runType);
    job6  = svmAnalysis(6,10,.1,runType);
    job7  = svmAnalysis(7,10,.1,runType);
    job8  = svmAnalysis(8,10,.1,runType);
    job9  = svmAnalysis(9,10,.1,runType);
    job10 = svmAnalysis(10,10,.1,runType);
    job11 = svmAnalysis(11,10,.1,runType);
    job12 = svmAnalysis(12,10,.1,runType);
    
    %% save results
    results{1}  = job1;
    results{2}  = job2;
    results{3}  = job3;
    results{4}  = job4;
    results{5}  = job5;
    results{6}  = job6;
    results{7}  = job7;
    results{8}  = job8;
    results{9}  = job9;
    results{10} = job10;
    results{11} = job11;
    results{12} = job12;
    
    accuracy.all = 0;
    accuracy.activity = 0;
    accuracy.wearing = 0;
    for k = 1:12
        accuracy.all = accuracy.all + results{k}.accuracyAll;
%         accuracy.activity = accuracy.activity + results{k}.accuracyActivity;
%         accuracy.wearing = accuracy.wearing + results{k}.accuracyWearing;
    end
    
    accuracy.all = accuracy.all/12;
%     accuracy.activity = accuracy.activity/12;
%     accuracy.wearing = accuracy.wearing/12;
    
    filename = ['CV_' runType];
    save(filename,'results','accuracy');
end