function finalResults = svmAnalysis(testSubject,c,gamma, runType)

%% CREATE TRAINING DATA


%initialize directories
parentDir = 'C:\Users\Antos\Desktop\Steve Everything Folder\Antos\Testbed\';
trainingFeatureDir = [parentDir 'features\'];

%apply these transformations every run in this order
classifierData = combineAllSubjectFeatures(trainingFeatureDir);
classifierData = combineLocations(classifierData,'Pocket');
classifierData = combineLocations(classifierData,'Belt');
classifierData = combineLocations(classifierData,'Bag');
classifierData = combineLocations(classifierData,'Hand');
classifierData.states = createStateList(classifierData);
classifierData = removeDataWithNaNs(classifierData);
classifierData = removeDataWithLocation(classifierData,'Not wearing');

%fix annotation error: hand was accidentally labeled as belt
classifierData = replaceStateWithState(classifierData,'Belt/Misc','Hand/Misc');

runType = 'Wearing';
switch runType
    case 'All'
        uniqueStates = unique(classifierData.states);
        save('uniqueStatesAll','uniqueStates');
    case 'Pocket'
        classifierData = removeDataWithLocation(classifierData,'Bag');
        classifierData = removeDataWithLocation(classifierData,'Belt');
        classifierData = removeDataWithLocation(classifierData,'Hand');
        classifierData = removeDataWithState(classifierData,'Hand/Misc');
        uniqueStates = unique(classifierData.states);
        save('uniqueStatesPocket','uniqueStates');
    case 'Belt'
        classifierData = removeDataWithLocation(classifierData,'Bag');
        classifierData = removeDataWithLocation(classifierData,'Pocket');
        classifierData = removeDataWithLocation(classifierData,'Hand');
        classifierData = removeDataWithState(classifierData,'Hand/Misc');
        uniqueStates = unique(classifierData.states);
        save('uniqueStatesBelt','uniqueStates');
    case 'Bag'
        classifierData = removeDataWithLocation(classifierData,'Belt');
        classifierData = removeDataWithLocation(classifierData,'Pocket');
        classifierData = removeDataWithLocation(classifierData,'Hand');
        classifierData = removeDataWithState(classifierData,'Hand/Misc');
        uniqueStates = unique(classifierData.states);
        save('uniqueStatesBag','uniqueStates');
    case 'Hand'
        classifierData = removeDataWithLocation(classifierData,'Bag');
        classifierData = removeDataWithLocation(classifierData,'Belt');
        classifierData = removeDataWithLocation(classifierData,'Pocket');
        classifierData = removeDataWithState(classifierData,'Hand/Misc');
        uniqueStates = unique(classifierData.states);
        save('uniqueStatesHand','uniqueStates');
    case 'Activity'
        uniqueStates = unique(classifierData.activity);
        save('uniqueStatesActivity','uniqueStates');
    case 'Wearing'
        uniqueStates = unique(classifierData.wearing);
        save('uniqueStatesWearing','uniqueStates');
    otherwise
        error('Bad runType argument');
end

%Create our test and training set 
%Training set only includes clips with: activity fraction > threshold
testingClassifierData = classifierData;
trainingClassifierData = removeDataWithActivityFraction(classifierData,.8);

%Scale Features
trainingClassifierData = scaleFeatures(trainingClassifierData);
testingClassifierData  = scaleFeatures(testingClassifierData);

%% RUN SVM
subjects = unique(classifierData.subject);
for j = testSubject:testSubject 
    
    %% INITAILIZATION
    tic;
    currentSubject = subjects(j);
    disp(['ITERATION ' num2str(j) currentSubject]);
       
    %sort subjects for cross validation
    trainClassifierData = removeDataWithSubject(trainingClassifierData,currentSubject);
    testClassifierData = keepDataWithSubject(testingClassifierData,currentSubject);
    
    
    %% SVM TRAIN
    %train classifier with all other subjects
    disp('Performing SVM Classification');
    yvec_nums = cell2vec(cellstr(trainClassifierData.wearing)');
    testvec = zeros(size(yvec_nums));  
    [svmPredictedStates classifierFit P] = classify('svm',trainClassifierData.features,...
        cellstr(trainClassifierData.wearing)',testvec,c,gamma);
    classifierFit.type = 'svm';
    svmInitialClassificationP = P;
    runtime = toc;
    disp(['SVM Train Runtime: ' num2str(runtime)]);
    
    filename = ['svm' runType num2str(testSubject)];
    save(filename,'classifierFit');
    
    %% SVM TEST
    disp('Fitting with SVM');
    fit = classifierFit; 
    [prePredictedCodes, accuracy, P] = svmpredict(...
        cell2vec(cellstr(testClassifierData.wearing)')',...
        testClassifierData.features,...
        fit.fit, ['-b 1']);
    prePredictedStates = fit.uStates(prePredictedCodes);
    timePassed = toc;
    disp(['Time elapsed:' num2str(timePassed)]);
    
    runtime = toc;
    disp(['SVM Test Runtime: ' num2str(runtime)]);
   
    
    %% SVM RESULTS

    %get codes for actual states
    groundTruth = zeros(length(testClassifierData.wearing),1);
    for i = 1:length(testClassifierData.wearing)
        groundTruth(i,1) = find(strcmp(testClassifierData.wearing{i},uniqueStates));
    end
    
    %prep codes for confusion matrix
%     preStateStr = regexp(prePredictedStates,'/','split');
    
%     preActivity = cell(length(preStateStr),1);
%     preWearing = cell(length(preStateStr),1);
%     for i = 1:length(preStateStr)
%         preActivity{i} = preStateStr{i}{2};
%         preWearing{i} = preStateStr{i}{1};
%     end
    
     %confusion matrix for everything
    [preCon,accuracyAll] = createConfusionMatrix(cellstr(testClassifierData.wearing'), prePredictedStates');
    disp(['SVM (all): ' num2str(accuracyAll)]);
    
%     %confusion matrix for activities
%     [preActivityCon,accuracyActivity] = createConfusionMatrix(...
%                     cellstr(testClassifierData.activity'), preActivity');
%     disp(['SVM (activities): ' num2str(accuracyActivity)]);
    
%     %confusion matrix for wearing
%     [preWearCon,accuracyWearing] = createConfusionMatrix(...
%                     cellstr(testClassifierData.wearing'), preWearing');
%     disp(['SVM (wearing): ' num2str(accuracyWearing)]);
    
    
    %Save out all of our results and variables for later
    results(j).groundTruth = groundTruth;
    
    results(j).accuracyAll = accuracyAll * 100;
%     results(j).accuracyActivity = accuracyActivity * 100;
%     results(j).accuracyWearing = accuracyWearing * 100;
    
    results(j).preCon = preCon;
%     results(j).preActivityCon = preActivityCon;
%     results(j).preWearCon = preWearCon;
    
    results(j).gamma = gamma;
    results(j).c = c;
    results(j).subject = currentSubject;
    
    results(j).P = P;
    results(j).prePredictedStates = prePredictedStates;
    results(j).prePredictedCodes = prePredictedCodes;
    
    results(j).classifierFit = classifierFit;
    results(j).svmInitialClassificationP = svmInitialClassificationP;
    results(j).svmPredictedStates = svmPredictedStates;
    
    results(j).trainClassifierData = trainClassifierData;
    results(j).testClassifierData = testClassifierData;
      
    runtime = toc;
    disp(['Total Runtime: ' num2str(runtime)]);

end

finalResults = results(j);