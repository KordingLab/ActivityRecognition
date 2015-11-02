clear;
close all;

subjects = {'SC', 'ED', 'MG', 'LL', 'PL', 'ML', 'ES', 'DR', 'AR', 'SM', 'RK', 'BC', 'AT', 'MD'};

load('accuracy_onnormal');

h = figure;
hold on;
set(h, 'position', [0  0  654  431]);

plot(median(mean(accuracy_baseline,3),2),'b:o','linewidth',1);
plot(median(mean(accuracy_expert,3),2),'k:^','linewidth',1);
plot([1 13], [.5 .5], ':k');
l = legend('Baseline Model','Expert Model', 'Chance Level', 'location', 'SE');
set(l, 'fontsize', 10);


xlim([1 13]);
set(gca, 'xtick', 1:13);

ylim([0 1]);

xlabel('Number of Training Subjects','fontsize',12);
ylabel('Accuracy','fontsize',12);

