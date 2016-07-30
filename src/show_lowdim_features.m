clear;
close all;

subject = 'LL';
n_trial = 5;
runmode = 'sit';

plot_in_matlab = true;
plot_in_plotly = false;

% loading normal walk data (from subject)
load(sprintf('~/Dropbox/Data/FTC/features/archive/%s/F1_accgyr_%sW0.mat', subject, subject));
data_nwalk = features_data.features(10:end,:);
label_nwalk = ones(size(features_data.features(10:end,:),1),1)*[1 0 0];

% loading normal still data (from baseline)
load('~/Dropbox/Data/FTC/features/archive/baseline/F1_accgyr_baseline2.mat');
data_nsit = features_data.features(10:end,:);
label_nsit = ones(size(features_data.features(10:end,:),1),1)*[0 0 1];

% PCA
% [coefs, ~] = pca([data_nwalk; data_nsit]);
% coefs = coefs(:,1:3);

% Sparse PCA
% gamma=0.01*ones(1,3);
% coefs = GPower([data_nwalk; data_nsit], gamma, 3 ,'l1',0);

% Factor Analysis
coefs = factoran([data_nwalk; data_nsit], 3);
coefs_psinv = inv(coefs'*coefs)*coefs';
coefs = coefs_psinv';

% score = [data_nwalk; data_nsit]*coefs;
score = [data_nwalk; data_nsit]*coefs;
label = [label_nwalk; label_nsit];

if plot_in_matlab,
    figure(1);
    scatter3(score(:,1), score(:,2), score(:,3), 50, label, 'filled');
end

if plot_in_plotly,
    scatter3_plotly(score, label, 'normal_behavior');
end

x_lim_min = 0;
x_lim_max = 0;
y_lim_min = 0;
y_lim_max = 0;
z_lim_min = 0;
z_lim_max = 0;

% loading deceptive walk (fake still)

score_plotly_walk = [data_nsit]*coefs;
label_plotly_walk = [label_nsit*0];
score_plotly_sit = [data_nwalk]*coefs;
label_plotly_sit = [label_nwalk*0];

colors = jet(n_trial-1);

for i=1:(n_trial-1),
    
    if strcmp(runmode,'walk'),
        
        load(sprintf('~/Dropbox/Data/FTC/features/archive/%s/F1_accgyr_%sW%d.mat',subject,subject,i));
        data_dwalk = features_data.features;%(10:end,:);
        if strcmp(subject, 'LL'),
            load(sprintf('~/Dropbox/Data/FTC/models/%s/%sS%d.mat',subject,subject,i-1));
        else
            load(sprintf('~/Dropbox/Data/FTC/models/%s/%sS%d.mat',subject,subject,i));
        end
        [RFout, ~] = predict(RFmodel, data_dwalk);
        label_dwalk = strcmp(RFout, '1')*[1 0 0] + strcmp(RFout, '2')*[1 .6 .6];
        %label_dwalk = strcmp(RFout, '1')*[1 (i-1)/(n_trial) 0] + strcmp(RFout, '2')*[1 (i-1)/(n_trial) 0];
        %label_dwalk = strcmp(RFout, '1')*colors(i,:) + strcmp(RFout, '2')*colors(i,:);
        success = sum(strcmp(RFout, '2'))/length(RFout);
        
        % centering (default for MATLAB's pca)
        %     score = (data-ones(size(data,1),1)*mean(data))*coefs;
        score = [data_nsit; data_dwalk]*coefs;

        score_plotly_walk = [score_plotly_walk; data_dwalk*coefs];
        label_plotly_walk = [label_plotly_walk; label_dwalk];

        if plot_in_matlab,
            figure(i+1);
            scatter3(score(:,1), score(:,2), score(:,3), 50, [label_nsit; label_dwalk], 'filled');
        end
        
    elseif strcmp(runmode,'sit'),
        
        load(sprintf('~/Dropbox/Data/FTC/features/archive/%s/F1_accgyr_%sS%d.mat',subject,subject,i));
        data_dsit = features_data.features;%(10:end,:);
        if strcmp(subject, 'LL'),
            load(sprintf('~/Dropbox/Data/FTC/models/%s/%sW%d.mat',subject,subject,i));
        else
            load(sprintf('~/Dropbox/Data/FTC/models/%s/%sW%d.mat',subject,subject,i-1));
        end
        [RFout, ~] = predict(RFmodel, data_dsit);
        label_dsit = strcmp(RFout, '2')*[0 0 1] + strcmp(RFout, '1')*[.6 .6 1];
        %label_dsit = strcmp(RFout, '2')*[0 (i-1)/(n_trial-1) 1-(i-1)/(n_trial-1)] + strcmp(RFout, '1')*[0 (i-1)/(n_trial-1) 1-(i-1)/(n_trial-1)];
        %label_dsit = strcmp(RFout, '2')*colors(i,:) + strcmp(RFout, '1')*colors(i,:);
        success = sum(strcmp(RFout, '1'))/length(RFout);
        
        % centering (default for MATLAB's pca):
        %     score = (data-ones(size(data,1),1)*mean(data))*coefs;
        score = [data_nwalk; data_dsit]*coefs;

        score_plotly_sit = [score_plotly_sit; data_dsit*coefs];
        label_plotly_sit = [label_plotly_sit; label_dsit];

        if plot_in_matlab,
            figure(i+1);
            scatter3(score(:,1), score(:,2), score(:,3), 50, [label_nwalk; label_dsit], 'filled');
        end
        
    end
    
    if plot_in_matlab,
        title(sprintf('Success: %.0f%%', success*100));
        x_lim = xlim;
        x_lim_min = min(x_lim_min, x_lim(1));
        x_lim_max = max(x_lim_max, x_lim(2));
        y_lim = ylim;
        y_lim_min = min(y_lim_min, y_lim(1));
        y_lim_max = max(y_lim_max, y_lim(2));
        z_lim = zlim;
        z_lim_min = min(z_lim_min, z_lim(1));
        z_lim_max = max(z_lim_max, z_lim(2));
    end

end

if plot_in_matlab,
    for i=1:(n_trial-1),
        
        figure(i+1);
        xlim([x_lim_min x_lim_max]);
        ylim([y_lim_min y_lim_max]);
        zlim([z_lim_min z_lim_max]);
        
    end
end

if plot_in_plotly,
    if strcmp(runmode,'walk'),
        scatter3_plotly(score_plotly_walk, label_plotly_walk, 'deceptive_walk');
    elseif strcmp(runmode,'sit'),
        scatter3_plotly(score_plotly_sit, label_plotly_sit, 'deceptive_sit');
    end
end

% tsne(data, label, 2, 6);

% score = data*coefs;
