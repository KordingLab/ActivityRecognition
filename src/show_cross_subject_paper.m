clear;
close all;

load('accuracy_paper.mat');

subjects = {'SC', 'ED', 'MG', 'LL', 'PL', 'ML', 'DM', 'ES', 'DR', 'AR', 'SM', 'RK', 'BC', 'AT', 'MD'};

h = figure;
hold on;
set(h, 'position', [2305         215         654         431]);

% removing subject DM's data which was buggy
accuracy_baseline(:,7,:) = [];
accuracy_expert(:,7,:) = [];

accuracy_baseline(14,:,:) = [];
accuracy_expert(14,:,:) = [];

kappa_baseline = (accuracy_baseline-.5)/(1-.5);
kappa_expert = (accuracy_expert-.5)/(1-.5);

plot(median(mean(kappa_baseline,3),2),'color','b','linewidth',1)
plot(median(mean(kappa_expert,3),2),'color',[0 .5 0],'linewidth',1)
l = legend('Baseline Model','Expert Model', 'location', 'SE');
set(l, 'fontsize', 10);

shadedErrorBar(1:13, median(mean(kappa_baseline,3),2),std(mean(kappa_baseline,3),1,2), 'b', 1);
shadedErrorBar(1:13, median(mean(kappa_expert,3),2),std(mean(kappa_expert,3),1,2), [0 .5 0], 1);

xlim([1 13]);
set(gca, 'xtick', 1:13);

xlabel('Number of Training Subjects','fontsize',12);
% ylabel('\kappa','fontsize',20);
ylabel('Accuracy (Scaled)','fontsize',12);
plot([1 13], [0 0], '--k');

colors = parula(14);

h = figure(2);
set(h, 'position', [1943         216         653         434]);
hold on;
k = 0;
for i=randsample(1:14,14),
    k = k+1;
    plot(100*(mean(accuracy_expert(:,i,:),3)-mean(accuracy_baseline(:,i,:),3)),'color',[.7 .7 .7]);%colors(k,:)); 
end
plot(100*mean(mean(accuracy_expert,3)-mean(accuracy_baseline,3),2),'k','linewidth',2);
errorbar(1:13, 100*mean(mean(accuracy_expert,3)-mean(accuracy_baseline,3),2), ...
    std(100*(mean(accuracy_expert,3)-mean(accuracy_baseline,3))/sqrt(14),1,2),'k');
xlim([.5 13.5]);
set(gca, 'xtick', 1:13);
xlabel('Number of Training Subjects','fontsize',12);
ylabel('Accuracy Difference % (Expert - Baseline)','fontsize',12);
