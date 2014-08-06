function result = SendToServer(forest, accuracy)

txt = sprintf('curl -X POST -H "Content-Type: application/json" -d ''{ "tree" : { "note" : "test" , "pr_id" : "FTC0" , "model_type" : "tree" , "accuracy" : "%.1f" , "model" : "', accuracy);
for i = 1,%:length(forest.Trees),
    txt_temp = evalc(sprintf('view(forest.Trees{%d})',i));
    ind_newline = findstr(txt_temp, sprintf('\n'));
    for i = 1:length(ind_newline)-1,
        txt = [txt, txt_temp(ind_newline(i)+1:ind_newline(i+1)-1), ' '];
    end
%     txt_temp = txt_temp(34:end); %removing the first line which is a description
%     txt = [txt, txt_temp];
end
txt = [txt, '" } }'' https://pr-models-cms-staging.cbits.northwestern.edu/trees.json --insecure']

% txt = 'curl -X POST -H "Content-Type: application/json" -d ''{ "tree" : { "note" : "test" , "pr_id" : "FTC0" , "model_type" : "tree" , "accuracy" : "0.1" , "model" : " 1  if x59<-0.0396521 then node 2 elseif x59>=-0.0396521 then node 3 else 2 2  if x39<-0.162654 then node 4 elseif x39>=-0.162654 then node 5 else 1 " } }'' https://pr-models-cms-staging.cbits.northwestern.edu/trees.json --insecure';
status = system(txt);