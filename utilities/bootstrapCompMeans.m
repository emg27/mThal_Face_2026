function [ci95, rejectNull, diffSampMeans] = bootstrapCompMeans(dataSet1,dataSet2,bootstrapReps,alpha,multComp,sided)

if nargin == 2
    bootstrapReps = 10000;
    alpha = 0.05;
    multComp = 1;
    sided = [];
elseif nargin == 3
    alpha = 0.05;
    multComp = 1;
    sided = [];
elseif nargin == 4
    multComp = 1;
    sided = [];
elseif nargin == 5
    sided = [];
end

sampMeans1 = nan(1,bootstrapReps);
sampMeans2 = nan(1,bootstrapReps);
diffSampMeans = nan(1,bootstrapReps);
for i=1:bootstrapReps
    % Resample from each dataset with replacement
    bootstrapSamp1 = randsample(dataSet1, length(dataSet1), true);
    bootstrapSamp2 = randsample(dataSet2, length(dataSet2), true);
    
    % Get means of both samples
    meanSamp1 = mean(bootstrapSamp1,'omitnan');
    sampMeans1(i) = meanSamp1;
    meanSamp2 = mean(bootstrapSamp2,'omitnan');
    sampMeans2(i) = meanSamp2;
    
    % Get the difference of the means
    diffMeans = meanSamp1 - meanSamp2;
    diffSampMeans(i) = diffMeans;
end

% Calculate confidence interval of difference of means
alpha = alpha/multComp;
ci95 = quantile(diffSampMeans, [alpha/2, 1-(alpha/2)]);

% If ci95 contains 0 then don't reject null
if isempty(sided)
    if (ci95(1) <= 0) && (ci95(2) >= 0)
        rejectNull = false;
    else
        rejectNull = true;
    end
elseif ismember(sided,{'r','right'}) % && (ci95(1) >= 0) %
    rejectNull = (ci95(1) >= 0); %false;
elseif ismember(sided,{'l','left'}) % && (ci95(2) <= 0)
    rejectNull = (ci95(2) <= 0); %false;
else
    rejectNull = true;
end

%     Plot histogram to confirm
%figure;
%hist(diffSampMeans, 100)

end