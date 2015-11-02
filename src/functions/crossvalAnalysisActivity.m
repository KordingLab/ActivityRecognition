%% script to run parallel cross validation
runTypes = {'Bag','Belt','Hand','Pocket'};
% runTypes = {'Activity'};
for i = 1:length(runTypes)
    runType = runTypes{i};
    job1  = svmAnalysisActivity(1,10,.1,runType);
    job2  = svmAnalysisActivity(2,10,.1,runType);
    job3  = svmAnalysisActivity(3,10,.1,runType);
    job4  = svmAnalysisActivity(4,10,.1,runType);
    job5  = svmAnalysisActivity(5,10,.1,runType);
    job6  = svmAnalysisActivity(6,10,.1,runType);
    job7  = svmAnalysisActivity(7,10,.1,runType);
    job8  = svmAnalysisActivity(8,10,.1,runType);
    job9  = svmAnalysisActivity(9,10,.1,runType);
    job10 = svmAnalysisActivity(10,10,.1,runType);
    job11 = svmAnalysisActivity(11,10,.1,runType);
    job12 = svmAnalysisActivity(12,10,.1,runType);
    
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