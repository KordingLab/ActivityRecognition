function codes = stateToCode(states)

list{1} = 'Bag/Sit to Stand';
list{2} = 'Bag/Sitting';
list{3} = 'Bag/Stand to Sit';
list{4} = 'Bag/Standing';
list{5} = 'Bag/Walking';

list{6} = 'Belt/Sit to Stand';
list{7} = 'Belt/Sitting';
list{8} = 'Belt/Stand to Sit';
list{9} = 'Belt/Standing';
list{10} = 'Belt/Walking';

list{11} = 'Hand/Misc';

list{12} = 'Hand/Sit to Stand';
list{13} = 'Hand/Sitting';
list{14} = 'Hand/Stand to Sit';
list{15} = 'Hand/Standing';
list{16} = 'Hand/Walking';

list{17} = 'Pocket/Sit to Stand';
list{18} = 'Pocket/Sitting';
list{19} = 'Pocket/Stand to Sit';
list{20} = 'Pocket/Standing';
list{21} = 'Pocket/Walking';

codes = zeros(length(states),1);
for i = 1:length(states)
    codes(i) = find(strcmp(list,states{i}));
end
end

