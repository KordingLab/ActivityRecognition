function result = CreateJSON(forest, traindata, accuracy)

% JSON file is created and copied to the java source code 'asset' to be deployed by the app.

json_file_location = '/home/sohrob/Dropbox/Code/Java/ActivityRecognition/ActivityRecognition/src/main/assets/';

json = sprintf('{\n\t"accuracy": %.3f,\n\t"model_type": "matlab-forest",\n\t"model_source": "Matlab",\n\t"name": "Matlab Forest Model Test",\n\t"model": [\n', accuracy);

for i = 1:length(forest.Trees),
    temp = evalc(sprintf('view(forest.Trees{%d})',i));
    ind_newline = findstr(temp, sprintf('\n'));
    json = [json, '\t\t"'];
    for j = 2:length(ind_newline)-2,
        json = [json, temp(ind_newline(j)+1:ind_newline(j+1)-1)];
        if j<length(ind_newline)-2,
            json = [json, '\\n'];
        end
    end
    json = [json, '"'];
    if i<length(forest.Trees),
        json = [json, ','];
    end
    json = [json, '\n'];
end
json = [json, '],\n'];

% adding feature lables
json = [json, '\t"feature_labels": [\n'];
for i=1:length(traindata.featureLabels),
    json = [json, '"', upper(traindata.featureLabels{i}),'"'];
    if i<length(traindata.featureLabels),
        json = [json, ', '];
    end
end
json = [json, '\n]\n'];

% closing the object
json = [json, '}'];

% write to the phone
fid = fopen([json_file_location, 'matlab-forest.json'], 'w');
fprintf(fid, json);

result = 0;

end