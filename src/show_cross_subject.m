clear;
close all;

addpath('functions\');

load('accuracy_paper.mat');
% removing subject DM's data from cheating data which was influenced by a bug in the phone app
accuracy_baseline(:,7,:) = [];
accuracy_expert(:,7,:) = [];
accuracy_baseline(14,:,:) = [];
accuracy_expert(14,:,:) = [];
accuracy_baseline_cheating = accuracy_baseline;
accuracy_expert_cheating = accuracy_expert;

load('accuracy_onnormal');
accuracy_baseline_normal = accuracy_baseline;
accuracy_expert_normal = accuracy_expert;

clear accuracy_baseline accuracy_expert;

h = figure;
hold on;
set(h, 'position', [395.4000  209.8000  557.6000  516.0000]);

plot(median(mean(accuracy_baseline_cheating,3),2),'k-o','markerfacecolor',[0 0 0],'linewidth',1)
plot(median(mean(accuracy_expert_cheating,3),2),'k-^','markerfacecolor',[0 0 0],'linewidth',1)

plot(median(mean(accuracy_baseline_normal,3),2),'k--o', 'markerfacecolor',[0 0 0],'linewidth',1);
plot(median(mean(accuracy_expert_normal,3),2),'k--^','markerfacecolor',[0 0 0],'linewidth',1);

plot([1 13], [.5 .5], ':k');

l = legend('Baseline Model / Fake Data','Expert Model / Fake Data', ...
    'Baseline Model / Normal Data','Expert Model / Normal Data', 'Chance Level', ...
    'location', 'northoutside');
set(l, 'fontsize', 10);

shadedErrorBar(1:13, median(mean(accuracy_baseline_cheating,3),2),std(mean(accuracy_baseline_cheating,3),1,2), '-o', 2);
shadedErrorBar(1:13, median(mean(accuracy_expert_cheating,3),2),std(mean(accuracy_expert_cheating,3),1,2), '-^', 2);

xlim([1 13]);
set(gca, 'xtick', 1:13);

xlabel('Number of Training Subjects','fontsize',14);
ylabel('Accuracy','fontsize',14);

h = figure(2);
set(h, 'position', [0  0  653  434]);
hold on;
k = 0;
colors = parula(14);

for i=randsample(1:14,14),
    k = k+1;
    plot(100*(mean(accuracy_expert_cheating(:,i,:),3)-mean(accuracy_baseline_cheating(:,i,:),3)),'color',[.5 .5 .5]);%colors(k,:)); 
end
plot(100*mean(mean(accuracy_expert_cheating,3)-mean(accuracy_baseline_cheating,3),2),'k','linewidth',2);
errorbar(1:13, 100*mean(mean(accuracy_expert_cheating,3)-mean(accuracy_baseline_cheating,3),2), ...
    std(100*(mean(accuracy_expert_cheating,3)-mean(accuracy_baseline_cheating,3))/sqrt(14),1,2),'k');
xlim([.5 13.5]);
set(gca, 'xtick', 1:13);
xlabel('Number of Training Subjects','fontsize',12);
ylabel('Accuracy Difference % (Expert - Baseline)','fontsize',12);
% legend('S1','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11','S12','S13','S14',...
%     'location', 'eastoutside');

