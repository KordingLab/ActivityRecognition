% Changed from scaling to [0 1] to normalization

function [data] = scaleFeatures(data)

featureMean = nanmean(data,1);
featureStd = nanstd(data,1);
data = (data - ones(size(data,1),1)*featureMean)./(ones(size(data,1),1)*featureStd);

end
