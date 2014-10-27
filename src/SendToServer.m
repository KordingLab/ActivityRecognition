function result = SendToServer(forest, traindata, accuracy)

command = 'curl -X POST -H "Content-Type: application/json" -d ''';

% json = sprintf('{ "tree" : { "note" : "test" , "pr_id" : "FTC0" , "model_type" : "tree" , "accuracy" : "%.1f" , "model" : "\n', accuracy);
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
json = [json, '],\n\t"map":{\n'];
for i=1:length(traindata.featureLabels),
    json = [json, sprintf('\t\t"p20featuresprobe_%s":"x%d"', traindata.featureLabels{i}, i)];
    if i<length(traindata.featureLabels),
        json = [json, ','];
    end
    json = [json, '\n'];
end
json = [json, '\t}\n}'];
       
command = [command, json, ''' https://pr-models-cms-staging.cbits.northwestern.edu/trees.json --insecure'];
 
%send to server
% status = system(command);

%also write to local file
fid = fopen('matlab-forest.json', 'w');
fprintf(fid, json);

result = 0;%status;

end