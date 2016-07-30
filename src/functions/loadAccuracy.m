%create matrix with final results

gamma = {'1e-05' '1e-04' '1e-03' '1e-02' '1e-01' '1' '10' '100' '1000' '10000' '100000'};
c = {'1e-05' '1e-04' '1e-03' '1e-02' '1e-01' '1' '10' '100' '1000' '10000' '100000'};

accuracyOverall = zeros(length(gamma),length(c));
accuracyActivity = zeros(length(gamma),length(c));
accuracyWearing = zeros(length(gamma),length(c));

for row = 1:length(gamma)
    pre2 = gamma{row};
   for col = 1:length(c)
       pre1 = c{col};
       filename = ['CrossValidationResults_c' pre1 '_g' pre2];
       load(filename);
       accuracyOverall(row,col) = accuracy.all;
       accuracyActivity(row,col) = accuracy.activity;
       accuracyWearing(row,col) = accuracy.wearing;
   end
end

save('ALL_ACCURACY','accuracyOverall','accuracyActivity','accuracyWearing');