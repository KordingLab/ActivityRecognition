function result = SendToServer(forest, traindata, accuracy)

command = 'curl -X POST -H "Content-Type: application/json" -d ''';
json = sprintf('{ "tree" : { "note" : "test" , "pr_id" : "FTC0" , "model_type" : "tree" , "accuracy" : "%.1f" , "model" : "\n', accuracy);
for i = 1:length(forest.Trees),
    temp = evalc(sprintf('view(forest.Trees{%d})',i));
    ind_newline = findstr(temp, sprintf('\n'));
    for i = 1:length(ind_newline)-1,
        json = [json, temp(ind_newline(i)+1:ind_newline(i+1)-1), char(10)];
    end
end
json = [json, '", "map":{\n'];
for i=1:length(traindata.featureLabels),
    json = [json, sprintf('"%s":"X%d"\n', traindata.featureLabels{i}, i)];
end
json = [json, '} } }'];
       
command = [command, json, ''' https://pr-models-cms-staging.cbits.northwestern.edu/trees.json --insecure'];

%send to server
status = system(command);

%also write to local file
fid = fopen('json.txt', 'w');
fprintf(fid, json);

end