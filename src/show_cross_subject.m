clear;
close all;

load('accuracy_cross_subject.mat');

% removing subjetc #7 (problem in data)
% k = 1;
% for subj=[1:6,8:length(accuracy_mean)],
%     accuracy_mean2{k} = accuracy_mean{subj};
%     subjects2{k} = subjects{subj};
%     k = k+1;
% end
% accuracy_mean = accuracy_mean2;
% subjects = subjects2;
% clear accuracy_mean2 subjects2;

h = figure;
set(h, 'position', [2413         390         815         420]);

subplot (1,3,[1 2]);
hold on;

colors = hsv(length(accuracy_mean));

for subj=1:length(accuracy_mean),
    
    means = cell2mat(accuracy_mean{subj});
    errors = cell2mat(accuracy_std{subj})/sqrt(8);
    
%     shadedErrorBar(1:length(means), means, errors, colors(subj,:), 1);
    
    plot(1:length(accuracy_mean{subj}), cell2mat(accuracy_mean{subj}), 'color', colors(subj,:), 'linewidth', 2);
%     errorbar(1:length(accuracy_mean{subj}), cell2mat(accuracy_mean{subj}), cell2mat(accuracy_mean{subj})-cell2mat(accuracy_low{subj}), cell2mat(accuracy_high{subj})-cell2mat(accuracy_mean{subj}), 'color', colors(subj,:));
    
    accuracy_vector{subj} = cell2mat(accuracy_mean{subj});
    
    accuracy_first(subj) = accuracy_mean{subj}{1};
    accuracy_last(subj) = accuracy_mean{subj}{end};
    
end

grid on;
% legend(subjects, 'location','SE');
xlabel('Trial (One Participant)');
ylabel('Accuracy on All Other Participants');
set(gca, 'xtick', 1:5);

subplot (1,3,3);
hold on;
for subj=1:length(accuracy_mean),
    plot([accuracy_first(subj) accuracy_last(subj)], 'color', colors(subj,:), 'linewidth',2);
end

plot([mean(accuracy_first) mean(accuracy_last)], 'color', [.75 .75 .75], 'linewidth', 5);
text(1, mean(accuracy_first), sprintf('%.2f',mean(accuracy_first)),'horizontalalignment','right','fontweight','bold');
text(2, mean(accuracy_last), sprintf('%.2f',mean(accuracy_last)),'fontweight','bold');

set(gca, 'xtick', [1 2], 'xticklabel', {'start','end'});
set(gca, 'yticklabel', []);
set(gca, 'ygrid', 'on');

load('accuracy_cross_subject_loocv.mat');
accuracy_before(7) = [];
accuracy_after(7) = [];
h = figure(2);
set(h, 'position', [504   444   393   504]);
hold on;
for subj = 1:length(accuracy_before),
    plot([accuracy_before(subj) accuracy_after(subj)], 'color', colors(subj,:), 'linewidth', 3);
end
plot([mean(accuracy_before) mean(accuracy_after)], '--', 'color', [.75 .75 .75], 'linewidth', 5);
text(1, mean(accuracy_before), sprintf('%.2f',mean(accuracy_before)),'horizontalalignment','right','fontweight','bold');
text(2, mean(accuracy_after), sprintf('%.2f',mean(accuracy_after)),'fontweight','bold');
set(gca, 'xtick', [1 2], 'xticklabel', {'start','end'});
set(gca, 'ygrid', 'on');
% legend(subjects);