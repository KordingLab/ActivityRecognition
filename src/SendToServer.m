function result = SendToServer(forest, traindata, accuracy)

% command = 'curl -X POST -H "Content-Type: application/json" -d ''';

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

% creating the feature name dictionary -- not necessary anymore
% json = [json, ',\n\t"map":{\n'];
% for i=1:length(traindata.featureLabels),
%     json = [json, sprintf('\t\t"%s":"x%d"', upper(traindata.featureLabels{i}), i)];
%     if i<length(traindata.featureLabels),
%         json = [json, ','];
%     end
%     json = [json, '\n'];
% end
% json = [json, '\t}'];

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

%send to server
% command = [command, json, ''' https://pr-models-cms-staging.cbits.northwestern.edu/trees.json --insecure'];
% status = system(command);

%also write to local file
fid = fopen('matlab-forest.json', 'w');
fprintf(fid, json);

result = 0;%status;

end