clear;
close all;

% loading true walk
acc = load('~/Dropbox/Data/FTC/raw/LLW0/acc.csv');
gyr = load('~/Dropbox/Data/FTC/raw/LLW0/gyr.csv');
length_min = min(size(acc,1), size(gyr,1));
acc = acc(1:length_min, 2:4);
gyr = gyr(1:length_min, 2:4);
data = [acc, gyr];
label = ones(length_min,1);
clearvars -except data label;

% loading true still
acc = load('~/Dropbox/Data/FTC/raw/baseline2/acc.csv');
gyr = load('~/Dropbox/Data/FTC/raw/baseline2/gyr.csv');
length_min = min(size(acc,1), size(gyr,1));
acc = acc(1:length_min, 2:4);
gyr = gyr(1:length_min, 2:4);
data = [data; [acc, gyr]];
label = [label; 2*ones(length_min,1)];
clearvars -except data label;

% loading cheating walk (fake still)
acc = load('~/Dropbox/Data/FTC/raw/LLW1/acc.csv');
gyr = load('~/Dropbox/Data/FTC/raw/LLW1/gyr.csv');
length_min = min(size(acc,1), size(gyr,1));
acc = acc(1:length_min, 2:4);
gyr = gyr(1:length_min, 2:4);
data = [data; [acc, gyr]];
label = [label; 3*ones(length_min,1)];
clearvars -except data label;

% loading cheating still (fake walk)
acc = load('~/Dropbox/Data/FTC/raw/LLS1/acc.csv');
gyr = load('~/Dropbox/Data/FTC/raw/LLS1/gyr.csv');
length_min = min(size(acc,1), size(gyr,1));
acc = acc(1:length_min, 2:4);
gyr = gyr(1:length_min, 2:4);
data = [data; [acc, gyr]];
label = [label; 4*ones(length_min,1)];
clearvars -except data label;

tsne(data, label, 2, 3);