function [fvec flab feature_set] = getFeatures(data, probe)

feature_set = 'F0';

% we do interpolation here to make a consistant number of datapoints
secs = 4;
rate = 50;
arr_size = round(secs*rate);
start_sec = data(1,1);
data_int = zeros([size(data,1), arr_size]);
data_int(1,:) = start_sec + ([0:arr_size-1]' / arr_size * secs);

% removing samplees with identical timestamps
fprintf('getFeatures: Warning: %d samples with identical timestamps found and removed.\n', sum(diff(data(1,:))==0));
data(:,diff(data(1,:))==0) = [];

for dim = 2:size(data,1),
    data_int(dim,:) = interp1(data(1,:), data(dim,:), data_int(1,:), 'linear', 'extrap');
end

S = data_int(2:end,:);
time = data_int(1,:);

fvec = [];
flab = {};
axes = {'x','y','z'};

% treating barometer differently
if size(S,1)==1,
    
    fvec = [fvec S(1,end)-S(1,1)]; flab = [flab; [probe ' end-begin']];
    fvec = [fvec nanmean(diff(S(1,:)))/nanmean(diff(time))]; flab = [flab; [probe ' avg derivative']];
    if isinf(nanmean(diff(S(1,:)))/nanmean(diff(time))),
        disp('Warning: Barometer feature extraction generates infinity values!');
    end

else

    % features for each of the three channels
    for i=1:size(S,1)
        % looking at separate timescales
        S5 = conv(S(i,:),gausswin(5)/nansum(gausswin(5)));
        S10 = conv(S(i,:),gausswin(10)/nansum(gausswin(10)));
        fvec = [fvec sqrt(nanmean(S5(:).^2))]; flab = [flab; '5 smooth rms'];
        fvec = [fvec sqrt(nanmean(S10(:).^2))]; flab = [flab; '10 smooth rms'];
        fvec = [fvec nanmean(S(i,:))]; flab = [flab; [probe ' ' axes{i} ' mean']]; % To be kept
        fvec = [fvec abs(nanmean(S(i,:)))]; flab = [flab; 'abs mean acc'];
        fvec = [fvec sqrt(nanmean(S(i,:).^2))]; flab = [flab; 'rms'];
        fvec = [fvec nanmax(S(i,:))];  flab = [flab; 'max'];
        fvec = [fvec nanmin(S(i,:))];  flab = [flab; 'min'];
        fvec = [fvec abs(nanmax(S(i,:)))];  flab = [flab; 'abs max'];
        fvec = [fvec abs(nanmin(S(i,:)))];  flab = [flab; 'abs min'];
        
        % normalized histogram of the values
        histvec = histc((S(i,:)-nanmean(S(i,:))/nanstd(S(i,:))),[-3:1:3]);
        histvec = histvec(1:end-1); % remove the last data point (which is zero in almost all cases)
        fvec = [fvec histvec]; flab = [flab; cellstr(repmat('hist',length(histvec),1))];
        
        % 2nd, 3rd, 4th moments
        fvec = [fvec nanstd(S(i,:))];  flab = [flab; [probe ' ' axes{i} ' std']];
        fvec = [fvec skewness(S(i,:))]; flab = [flab; [probe ' ' axes{i} ' skew']];
        fvec = [fvec kurtosis(S(i,:))]; flab = [flab; [probe ' ' axes{i} ' kurt']];
        
        % fourier transform
        % This was completely wrong. Instead of first computing the FFT and
        % then getting the first 8 coefficients, it was doing FFT only on the
        % first 16 samples of the signal and then getting the first 8
        % coefficients.
        Y = abs(fft(S(i,:), secs*rate)); % depending on sampling rate and window size
        Y = Y/sqrt(sum(Y.^2));
        Y = Y(1:end/2);
        Y = decimate(Y,2);
        Y = Y(1:10);
        fvec = [fvec Y];
        flab = [flab; cellstr(repmat('fourier',length(Y),1))];
        
        
        % moments of the difference
        fvec = [fvec sqrt(nanmean(diff(S(i,:)).^2))]; flab = [flab; [probe ' ' axes{i} ' mean diff']];
        fvec = [fvec nanstd(diff(S(i,:)))]; flab = [flab; [probe ' ' axes{i} ' std diff']];
        fvec = [fvec skewness(diff(S(i,:)))]; flab = [flab; [probe ' ' axes{i} ' skew diff']];
        fvec = [fvec kurtosis(diff(S(i,:)))]; flab = [flab; [probe ' ' axes{i} ' kurt diff']];
        
    end
    
    % features that apply across the signals
    
    % overall mean
    fvec = [fvec nanmean(nanmean(S.^2))]; flab = [flab; [probe ' overall mean']];
    
    % for quasi angles
    S2=S/sqrt(nansum(S.^2));
    fvec = [fvec nanmean(S2(1,:).*S2(2,:))]; flab = [flab; 'cross prod 1'];
    fvec = [fvec nanmean(S2(1,:).*S2(3,:))]; flab = [flab; 'cross prod 2'];
    fvec = [fvec nanmean(S2(2,:).*S2(3,:))]; flab = [flab; 'cross prod 3'];
    fvec = [fvec abs(nanmean(S2(1,:).*S2(2,:)))]; flab = [flab; 'ABS cross prod 1'];
    fvec = [fvec abs(nanmean(S2(1,:).*S2(3,:)))]; flab = [flab; 'ABS cross prod 2'];
    fvec = [fvec abs(nanmean(S2(2,:).*S2(3,:)))]; flab = [flab; 'ABS cross prod 3'];
    
    % cross products - only for 3axes sensors:
    fvec = [fvec nanmean(S(1,:).*S(2,:))]; flab = [flab; [probe ' cross prod']];
    fvec = [fvec nanmean(S(1,:).*S(3,:))]; flab = [flab; [probe ' cross prod']];
    fvec = [fvec nanmean(S(2,:).*S(3,:))]; flab = [flab; [probe ' cross prod']];
    fvec = [fvec abs(nanmean(S(1,:).*S(2,:)))]; flab = [flab; [probe ' abs cross prod']];
    fvec = [fvec abs(nanmean(S(1,:).*S(3,:)))]; flab = [flab; [probe ' abs cross prod']];
    fvec = [fvec abs(nanmean(S(2,:).*S(3,:)))]; flab = [flab; [probe ' abs cross prod']];

end

return


%------------------------------------------------------

function [w] = gausswin(M,alpha)
if nargin<2
    alpha=1;
end
n = -(M-1)/2 : (M-1)/2;
w = exp((-1/2) * (alpha * n/(M/2)) .^ 2)';
