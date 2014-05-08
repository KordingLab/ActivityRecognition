function createBarPlot(filename)
load(filename);
mat = results(1,1).resultMat;
load('subject_wrong_loc');
%% HMM
%known location
figure(1)
subplot(1,2,2);
bagKnown    = mat{9,5};
beltKnown   = mat{9,6};
handKnown   = mat{9,7};
pocketKnown = mat{9,8};

bagUnknown    = wrongLocResults.bagHmm;
beltUnknown   = wrongLocResults.beltHmm;
handUnknown   = wrongLocResults.handHmm;
pocketUnknown = wrongLocResults.pocketHmm;


bagAgnostic = mat{6,5};
beltAgnostic= mat{6,6};
handAgnostic = mat{6,7};
pocketAgnostic = mat{6,8};

bagJoint = mat{3,5};
beltJoint = mat{3,6};
handJoint = mat{3,7};
pocketJoint = mat{3,8};

x = [bagKnown beltKnown handKnown pocketKnown;
    bagUnknown beltUnknown handUnknown pocketUnknown;
    bagAgnostic beltAgnostic handAgnostic pocketAgnostic;
    bagJoint beltJoint handJoint pocketJoint];
x = x*100;
bar(x);
ylim([0 100]);
title('SVM and HMM Accuracies');

%% SVM
%known location
subplot(1,2,1);
bagKnown = mat{8,5};
beltKnown = mat{8,6};
handKnown = mat{8,7};
pocketKnown = mat{8,8};

bagUnknown = wrongLocResults.bagSvm;
beltUnknown = wrongLocResults.beltSvm;
handUnknown =wrongLocResults.handSvm;
pocketUnknown = wrongLocResults.pocketSvm;


bagAgnostic = mat{5,5};
beltAgnostic= mat{5,6};
handAgnostic = mat{5,7};
pocketAgnostic = mat{5,8};

bagJoint = mat{2,5};
beltJoint = mat{2,6};
handJoint = mat{2,7};
pocketJoint = mat{2,8};

x2 = [bagKnown beltKnown handKnown pocketKnown;
    bagUnknown beltUnknown handUnknown pocketUnknown;
    bagAgnostic beltAgnostic handAgnostic pocketAgnostic;
    bagJoint beltJoint handJoint pocketJoint];
x2 = x2*100;
bar(x2);
% tickLabels = {'Train: One Location | Test: Same Location';
%               'Train: One Location | Test: All Locations';
%               'Train: All Locations | Test: All Locations';
%               'Joint Activity/Location Classifier'};
h = gca;
% set(gca,'XTickLabel',tickLabels);
ylim([0 100]);
title('SVM Accuracies')
ylabel('Classification Accuracy (%)');

%% HMM
%known location
figure(2)
subplot(1,2,2);
sit2StandKnown = mat{9,9};
sitKnown = mat{9,10};
stand2SitKnown = mat{9,11};
standKnown = mat{9,12};
walkKnown = mat{9,13};

load('subject_wrong_act');


sitUnknown = wrongActResults.sittingHmm;
standUnknown = wrongActResults.standingHmm;
walkUnknown = wrongActResults.walkingHmm;
sit2StandUnknown = wrongActResults.sit2StandHmm;
stand2SitUknown = wrongActResults.stand2SitHmm;


sit2StandAgnostic = mat{6,9};
sitAgnostic = mat{6,10};
stand2SitAgnostic = mat{6,11};
standAgnostic= mat{6,12};
walkAgnostic = mat{6,13};

sit2StandJoint = mat{3,9};
sitJoint = mat{3,10};
stand2SitJoint = mat{3,11};
standJoint = mat{3,12};
walkJoint = mat{3,13};

x = [sit2StandKnown sitKnown stand2SitKnown standKnown walkKnown;
    sit2StandUnknown sitUnknown stand2SitUknown standUnknown walkUnknown;
    sit2StandAgnostic sitAgnostic stand2SitAgnostic standAgnostic walkAgnostic;
    sit2StandJoint sitJoint stand2SitAgnostic standJoint walkJoint];
x = x*100;
bar(x);
% tickLabels = {'Train: One Location | Test: Same Location';
%               'Train: One Location | Test: All Locations';
%               'Train: All Locations | Test: All Locations';
%               'Joint Activity/Location Classifier'};
% h = gca;
% set(gca,'XTickLabel',tickLabels);
ylim([0 100]);
title('SVM and HMM Accuracies');

%% SVM
%known location
subplot(1,2,1);
sitKnown = mat{8,10};
standKnown = mat{8,12};
walkKnown = mat{8,13};
sit2StandKnown = mat{8,9};
stand2SitKnown = mat{8,11};


sitUnknown = wrongActResults.sittingSvm;
standUnknown = wrongActResults.standingSvm;
walkUnknown = wrongActResults.walkingSvm;
sit2StandUnknown = wrongActResults.sit2StandSvm;
stand2SitUknown = wrongActResults.stand2SitSvm;

sitAgnostic = mat{5,10};
standAgnostic= mat{5,12};
walkAgnostic = mat{5,13};
sit2StandAgnostic = mat{5,9};
stand2SitAgnostic = mat{5,11};

sitJoint = mat{2,10};
standJoint = mat{2,12};
walkJoint = mat{2,13};
sit2StandJoint = mat{2,9};
stand2SitJoint = mat{2,11};

x2 = [sit2StandKnown sitKnown stand2SitKnown standKnown walkKnown;
    sit2StandUnknown sitUnknown stand2SitUknown standUnknown walkUnknown;
    sit2StandAgnostic sitAgnostic stand2SitAgnostic standAgnostic walkAgnostic;
    sit2StandJoint sitJoint stand2SitAgnostic standJoint walkJoint];
x2 = x2*100;
bar(x2);
ylim([0 100]);
title('SVM Accuracies')
ylabel('Classification Accuracy (%)');

