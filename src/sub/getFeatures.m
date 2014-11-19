function [fvec flab feature_set] = getFeatures(data, probe, secs, rate)

feature_set = 'F2';

do_interpolation = false;

% Removing samples with identical timestamps
% Ideally this should be done when preparing data (which is the case for
% Purple Robot data), but for some external datasets such as CU's it is
% necessary.
% ind_remove = find(diff(data(1,:))==0);
% data(:,ind_remove) = [];


% if ~isempty(ind_remove),
%     fprintf('getFeatures: Warning: %d samples with identical timestamps found and removed.\n', length(ind_remove));
% end

% no interpolation for now

% INTERPOLATION 
% to make a consistent number of datapoints and get rid of occasional sensor noise
if do_interpolation,
    arr_size = round(secs*rate);
    start_sec = data(1,1);
    data_int = zeros([size(data,1), arr_size]);
    data_int(1,:) = start_sec + ([0:arr_size-1]' / arr_size * secs);
    for dim = 2:size(data,1),
        data_int(dim,:) = interp1(data(1,:), data(dim,:), data_int(1,:), 'linear', 'extrap');
    end
else
    data_int = data;
end

% local variables for feature extraction
S = data_int(2:end,:);
time = data_int(1,:);

fvec = [];
flab = {};
axes = {'x','y','z'};

% treating barometer differently
if size(S,1)==1,
    
    fvec = [fvec S(1,end)-S(1,1)]; flab = [flab; [probe '_end_begin']];
    fvec = [fvec nanmean(diff(S(1,:))./diff(time))]; flab = [flab; [probe '_avg_derivative']];
    if isinf(nanmean(diff(S(1,:))./diff(time))),
        disp('Warning: Barometer feature extraction generated infinity values!');
    end

else

    % features for each of the three channels
    for i=1:size(S,1)
        
        % average
        fvec = [fvec nanmean(S(i,:))]; flab = [flab; [probe axes{i} '_mean']];
        fvec = [fvec abs(nanmean(S(i,:)))]; flab = [flab; [probe axes{i} '_mean_abs']];
        fvec = [fvec sqrt(nanmean(S(i,:).^2))]; flab = [flab; [probe axes{i} '_rms']];

        % looking at separate timescales
%         S5 = conv(S(i,:),gausswin(5)/nansum(gausswin(5)));
%         S10 = conv(S(i,:),gausswin(10)/nansum(gausswin(10)));
%         fvec = [fvec sqrt(nanmean(S5(:).^2))]; flab = [flab; [probe axes{i} '_rms_smooth5']];
%         fvec = [fvec sqrt(nanmean(S10(:).^2))]; flab = [flab; [probe axes{i} '_rms_smooth10']];

        % min and max
        fvec = [fvec nanmax(S(i,:))];  flab = [flab; [probe axes{i} '_max']];
        fvec = [fvec nanmin(S(i,:))];  flab = [flab; [probe axes{i} '_min']];
        fvec = [fvec abs(nanmax(S(i,:)))];  flab = [flab; [probe axes{i} '_max_abs']];
        fvec = [fvec abs(nanmin(S(i,:)))];  flab = [flab; [probe axes{i} '_min_abs']];
        
        %TODO
        % add histogram of raw values
        
        % histogram of the z-score values
        histvec = histc((S(i,:)-nanmean(S(i,:))/nanstd(S(i,:))),[-3:1:3]);
        histvec = histvec(1:end-1); % remove the last data point which counts how many values match exactly 3. (nonsense)
        fvec = [fvec histvec]; 
        for j=1:length(histvec),
            flab = [flab; [probe axes{i} sprintf('_hist%d',j)]];
        end
        
        % 2nd, 3rd, 4th moments
        fvec = [fvec nanstd(S(i,:))];  flab = [flab; [probe axes{i} '_std']];
        fvec = [fvec skewness(S(i,:))]; flab = [flab; [probe axes{i} '_skew']];
        fvec = [fvec kurtosis(S(i,:))]; flab = [flab; [probe axes{i} '_kurt']];
        
        % fourier transform
%         Y = abs(fft(S(i,:)));
%         Y = Y/sqrt(sum(Y.^2));
%         Y = Y(1:end/2);
%         Y = Y(1:10); % only the first 10 coefficients
%         fvec = [fvec Y];
%         for j=1:length(Y),
%             flab = [flab; [probe axes{i} sprintf('_fft%d',j)]];
%         end
        
        
        % moments of the difference
        %fvec = [fvec sqrt(nanmean(diff(S(i,:)).^2))]; flab = [flab; [probe axes{i} '_diff_mean']];
        fvec = [fvec nanmean(diff(S(i,:)))]; flab = [flab; [probe axes{i} '_diff_mean']];  %changed
        fvec = [fvec nanstd(diff(S(i,:)))]; flab = [flab; [probe axes{i} '_diff_std']];
        fvec = [fvec skewness(diff(S(i,:)))]; flab = [flab; [probe axes{i} '_diff_skew']];
        fvec = [fvec kurtosis(diff(S(i,:)))]; flab = [flab; [probe axes{i} '_diff_kurt']];
        
    end
    
    % features that apply across the signals
    
    % overall mean of sqares
    fvec = [fvec nanmean(nanmean(S.^2))]; flab = [flab; [probe '_mean']];
    
    % for quasi-angles
    % NOTE: if this is meant to calculate the angles (cosine of angles)
    % then it is doing it in a completely wrong way
    
    % S2=S/sqrt(nansum(S.^2));
    
    % corrected:
    S2=S./(ones(size(S,1),1)*sqrt(nansum(S.^2)));
    
    fvec = [fvec nanmean(S2(1,:).*S2(2,:))]; flab = [flab; [probe '_cross_xy_norm']];
    fvec = [fvec nanmean(S2(1,:).*S2(3,:))]; flab = [flab; [probe '_cross_zx_norm']];
    fvec = [fvec nanmean(S2(2,:).*S2(3,:))]; flab = [flab; [probe '_cross_yz_norm']];
    fvec = [fvec abs(nanmean(S2(1,:).*S2(2,:)))]; flab = [flab; [probe '_cross_xy_norm_abs']];
    fvec = [fvec abs(nanmean(S2(1,:).*S2(3,:)))]; flab = [flab; [probe  '_cross_zx_norm_abs']];
    fvec = [fvec abs(nanmean(S2(2,:).*S2(3,:)))]; flab = [flab; [probe '_cross_yz_norm_abs']];
    
    % cross products
    fvec = [fvec nanmean(S(1,:).*S(2,:))]; flab = [flab; [probe '_cross_xy']];
    fvec = [fvec nanmean(S(1,:).*S(3,:))]; flab = [flab; [probe '_cross_zx']];
    fvec = [fvec nanmean(S(2,:).*S(3,:))]; flab = [flab; [probe '_cross_yz']];
    fvec = [fvec abs(nanmean(S(1,:).*S(2,:)))]; flab = [flab; [probe '_cross_xy_abs']];
    fvec = [fvec abs(nanmean(S(1,:).*S(3,:)))]; flab = [flab; [probe '_cross_zx_abs']];
    fvec = [fvec abs(nanmean(S(2,:).*S(3,:)))]; flab = [flab; [probe '_cross_yz_abs']];

end

end


%------------------------------------------------------

function [w] = gausswin(M,alpha)
if nargin<2
    alpha=1;
end
n = -(M-1)/2 : (M-1)/2;
w = exp((-1/2) * (alpha * n/(M/2)) .^ 2)';
end
