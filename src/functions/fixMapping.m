function mappingIndex = fixMapping(uniqueStates,predictedStates,P)


matchingIndex = zeros(length(uniqueStates),1);
mappingIndex = zeros(length(uniqueStates),1);
for i = 1:length(uniqueStates)
    state = uniqueStates{i};
    try
        matchingIndex(i,1) = find(strcmp(state,predictedStates),1);
    catch err
        matchingIndex(i,1) = 0;
    end
    try
        [~,mappingIndex(i,1)] = max(P(matchingIndex(i,1),:));
    catch err
        mappingIndex(i,1) = 0;
    end
end
if any(mappingIndex == 0)
    ind = find(mappingIndex == 0);
    for y = 1:length(mappingIndex)
        if ~any(mappingIndex == y)
            mappingIndex(ind) = y;
        end
    end
end