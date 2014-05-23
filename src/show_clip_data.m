clear all;
close all;

clip_dir = '~/Dropbox/Data/ActivityRecognition/clips/';

files = what(clip_dir);
files = files.mat;

for f = 1:length(files),

    file = files(f);
    load([clip_dir cell2mat(file)]);
    

    figure;
    title(file);
    
    subplot 311;
    hold on;
    for i=1:length(clip_data.values),
        plot(clip_data.values{1}(1,:), clip_data.values{1}(2,:));
    end
    
    subplot 312;
    hold on;
    for i=1:length(clip_data.values),
        plot(clip_data.values{1}(1,:));
    end
    
    subplot 313;
    h = plot(cell2vec(clip_data.act_label));
    set(gca, 'ytick', 1:length(unique(clip_data.act_label)), 'yticklabel', unique(clip_data.act_label));
    axis tight;
    
end