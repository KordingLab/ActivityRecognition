clear;
close all;

%% subject name
% format: XX[W/S]k (XX: subject's initials; W/S: trial type (Walk/Sit); k: trial number)
global subject;
subject = 'MDW2';

%% activity class
% 1: walk, 2:stationary
if subject(3)=='W',
    activity_class = 1;
elseif subject(3)=='S',
    activity_class = 2;
else
    error('Subject name format incorrect!');
end

%% phone location (no need to change for FTC)
phone_location = 0;

output_dir = '~/Dropbox/Data/FTC/raw/';

%% creating destination folder for new data
if ~exist([output_dir,subject], 'dir'),
    mkdir([output_dir,subject]);
end

probes = {'acc','gyr','ggl','rfm'};


%% copying files from phone to computer
for i=1:length(probes),
    system(['adb pull /sdcard/Android/data/edu.northwestern.sohrob.activityrecognition.activityrecognition/files/', probes{i}, '.csv ~/Dropbox/Code/MATLAB/ActivityRecognition/src/import/.']);
end
system('adb pull /sdcard/Android/data/edu.northwestern.sohrob.activityrecognition.activityrecognition/files/result.txt ~/Dropbox/Code/MATLAB/ActivityRecognition/src/import/.');

%% writing files to where they can be read by Preprocessing
for i=1:length(probes),
    
    filename = ['import/', probes{i}, '.csv'];
    file_out = [output_dir, subject, '/', probes{i}, '.csv'];%sprintf('_trial%d.csv', trial)];
    
    if ~exist(filename, 'file'),
        error(['Data for probe ', probes{i}, ' does not exist']);
    end
    
    if strcmp(probes{i}, 'ggl'),
        
        copyfile(filename, file_out);
        
    else
        
        data = load(filename);
        
        data = [data, ones(size(data,1),1)*activity_class, ones(size(data,1),1)*phone_location];
        
        
        if exist(file_out, 'file')
            error('Error: data file already exists for %s', subject);
        else
            dlmwrite(file_out, data, 'delimiter', '\t', 'precision', '%f');
        end
    
    end

end

fid=fopen('import/result.txt');
result = textscan(fid,'%s');
msgbox([result{1}{1}, ' !!']);