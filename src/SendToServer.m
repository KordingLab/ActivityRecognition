function result = SendToServer(forest, accuracy)

author_name = 'SSaeb';
tree_amount = length(forest.Trees);
txt = sprintf('curl -X POST -H "Content-Type: application/json" -d ''{ "tree" : { "author" : "%s" , "tree_amount" : "%d" , "note" : "for test" , "parser" : "default" , "pr_id" : "FTC0" , "model_type" : "tree" , "accuracy" : "%f" , "model" : "', author_name, tree_amount, accuracy);
for i = 1:tree_amount,
    txt_temp = evalc(sprintf('view(forest.Trees{%d})',i));
    txt_temp = txt_temp(34:end);
    txt = [txt, txt_temp];
end
txt = [txt, '" } }'' localhost:3000/trees.json'];
system('cd ~');
status = system(txt);