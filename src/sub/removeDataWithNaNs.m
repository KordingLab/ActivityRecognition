function classifierData = removeDataWithNaNs(classifierData)

ind = any(isnan(classifierData.features),2);
classifierData.features(ind,:) = [];
classifierData.wearing(ind) = [];
classifierData.activity(ind) = [];
classifierData.identifier(ind) = [];
classifierData.subject(ind) = [];
classifierData.states(ind) = [];
classifierData.activityFrac(ind) = [];
% disp(['Removed data with NaNs']);
end