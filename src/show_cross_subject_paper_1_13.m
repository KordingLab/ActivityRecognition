clear;
close all;

load('accuracy_1_13_paper.mat');

accuracy_expert(:,7,:) = [];

fprintf('Accuracy (LOSI/LOSO)\n');
disp(median(mean(accuracy_expert,3),2));

fprintf('Precision - Sitting (LOSI/LOSO)\n');
disp(median(mean(precision_sit,3),2));

fprintf('Precision - Wallking (LOSI/LOSO)\n');
disp(median(nanmean(precision_walk,3),2));

fprintf('Recall - Sitting (LOSI/LOSO)\n');
disp(median(mean(recall_sit,3),2));

fprintf('Recall - Walking (LOSI/LOSO)\n');
disp(median(mean(recall_walk,3),2));