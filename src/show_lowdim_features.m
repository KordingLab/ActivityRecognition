clear;
close all;

subject = 'ML';

% loading normal walk data
load(sprintf('~/Dropbox/Data/FTC/features/archive/%s/F1_accgyr_%sW0.mat', subject, subject));
data_nwalk = features_data.features(10:end,:);
label_nwalk = ones(size(features_data.features(10:end,:),1),1)*[1 0 0];

% loading normal still data
load('~/Dropbox/Data/FTC/features/archive/baseline/F1_accgyr_baseline2.mat');
data_nsit = features_data.features(10:end,:);
label_nsit = ones(size(features_data.features(10:end,:),1),1)*[0 0 1];

% calculating pca coefs from normal walk and sit data
[coefs, score] = pca([data_nwalk; data_nsit]); 

figure(1);
scatter3(score(:,1), score(:,2), score(:,3), 50, [label_nwalk; label_nsit], 'filled');

x_lim_min = 0;
x_lim_max = 0;
y_lim_min = 0;
y_lim_max = 0;
z_lim_min = 0;
z_lim_max = 0;

% loading deceptive walk (fake still)
for i=1:6,

%     load(sprintf('~/Dropbox/Data/FTC/features/archive/%s/F1_accgyr_%sW%d.mat',subject,subject,i));
%     data = [data_nsit; features_data.features(10:end,:)];
%     label = [label_nsit; ones(size(features_data.features(10:end,:),1),1)*[1 .6 .6]];
%     score = (data-ones(size(data,1),1)*mean(data))*coefs;
%     figure(i+1);
%     scatter3(score(:,1), score(:,2), score(:,3), 50, label, 'filled');

    load(sprintf('~/Dropbox/Data/FTC/features/archive/%s/F1_accgyr_%sS%d.mat',subject,subject,i));
    data = [data_nwalk; features_data.features(10:end,:)];
    label = [label_nwalk; ones(size(features_data.features(10:end,:),1),1)*[.6 .6 1]];
    score = (data-ones(size(data,1),1)*mean(data))*coefs;
    figure(i+1);
    scatter3(score(:,1), score(:,2), score(:,3), 50, label, 'filled');
    
    x_lim = xlim;
    x_lim_min = min(x_lim_min, x_lim(1));
    x_lim_max = max(x_lim_max, x_lim(2));
    y_lim = ylim;
    y_lim_min = min(y_lim_min, y_lim(1));
    y_lim_max = max(y_lim_max, y_lim(2));
    z_lim = xlim;
    z_lim_min = min(z_lim_min, z_lim(1));
    z_lim_max = max(z_lim_max, z_lim(2));

end

for i=1:6,
    
    figure(i+1);
    xlim([x_lim_min x_lim_max]);
    ylim([y_lim_min y_lim_max]);
    zlim([z_lim_min z_lim_max]);
    
end

% tsne(data, label, 2, 6);

% score = data*coefs;
