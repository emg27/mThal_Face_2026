%%
close all, clear
%load('C:\Users\emg27\Dropbox\PostDoc\ElviraMarco\One-on-One\20241214\datWord_simplifedIntensityData.mat')
load("/Users/zira/Library/CloudStorage/Dropbox/PostDoc/ElviraMarco/One-on-One/20241214/datWord_simplifedIntensityData.mat")

%savePATH = 'C:\Users\emg27\Dropbox\PostDoc\ElviraMarco\One-on-One\20250106\intensityCheck';
%mkdir(savePATH)

%valCond = {'No Stim','55Hz','80Hz','130Hz'};
valCond = {'No Stim','55Hz','130Hz'};

close all

% Create all sessions
[fH,stimInt] = plotBySessionComparison(datWord,valCond,uniSess,...
    uniWord,colMat,'allValCond',1);
%saveFigurePDF(fH,savePATH)

% Create lateral comparisons
[fH,stimInt] = plotBySessionComparison(datWord,uniCond(1:4),uniSess,...
    uniWord,colMat,'saveName','_lateralComparison');
%saveFigurePDF(fH,savePATH)
%% Create an intensity plot by day
function [fH,stimInt] = plotBySessionComparison(datWord,valCond,uniSess,...
    uniWord,colMat,varargin)
plotType = 'inten'; % Could plot inten, pitch, or stErr_pitch
thres = 5;
pltPairwise = 1; % Determine whether or not to plot the pairwised comparison.
allValCond = 1; % This will only plot the sessions that have data for on all conditions.
saveName = [];
exOutliers = 1;

assignopts(who, varargin);

stimInt = repmat(struct('cond',[],'type',plotType,...
    'simpDat',nan(length(uniWord),length(uniSess))),size(valCond,2),1);

if exOutliers
    saveName = [saveName '_exOutliers'];
end
% Iterate through the conditions
for n = 1:size(valCond,2)
    % Identify the position of the data in the structure
    posCond = ismember(datWord(1).conditionOrder,valCond(n));
    stimInt(n).cond = valCond(n);
    % Iterate through the words and session
    for k = 1:size(datWord,2)
        for sess = 1:size(datWord(k).uniSess,2)
            posSess = find(ismember(uniSess,datWord(k).uniSess(sess)));
            temp  = mean(datWord(k).(plotType){sess,posCond==1},'omitnan');
            stimInt(n).simpDat(k,posSess) = temp;
        end
    end
end

% Plot the data by session
fH = [];
for sess = 1:size(stimInt(1).simpDat,2)
    % Determine which sessions have valid data and plot
    mask = ones(size(stimInt));
    temp = cell(0);
    for n = 1:size(valCond,2)
        if sum(~isnan(stimInt(n).simpDat(:,sess)))>0
            temp = [temp; {stimInt(n).simpDat(:,sess)}];
        else
            mask(n) = 0;
        end
    end

    % Determine if all conditions need to be met, if true, but conditions
    % are missing than skip the current session
    if allValCond && sum(mask)~=size(valCond,2)
        continue
    end

    % Determine if there are any outliers and remove them
    if exOutliers
        tmp = [temp{:}];
        [tmp, idxRMO] = rmoutliers(tmp);%,'quartiles');
        for n = 1:size(valCond(mask==1),2)
            temp{n} = tmp(:,n);
        end
    end

    % Define the condition index
    pltcond = valCond(mask==1);
    posCond = find(ismember(datWord(1).conditionOrder,pltcond));

    % Create the figure of the raw words unpaired
    myboxplot(temp,'box',colMat(posCond))
    yline(median(temp{1},'omitnan')+thres,'LineStyle','--','LineWidth',1,'Color',.7*[1 1 1])
    title(sprintf('%s: Raw Speech Intensity',uniSess{sess}))
    ylabel('Intensity (dB)')
    set(gca,'xTick',1:size(pltcond,2),'XTickLabel',pltcond)
    if ~isempty(saveName)
        set(gcf,'Name',sprintf('%s_raw_%s_histogram%s',uniSess{sess},plotType,saveName))
    else
        set(gcf,'Name',sprintf('%s_raw_%s_histogram',uniSess{sess},plotType))
    end
    fH = [fH; gcf];

    % Create a figure of the intensities where it is a paired difference
    if pltPairwise
        pairTemp = temp;
        for n = 1:size(temp,1)
            pairTemp{n} = pairTemp{n} - temp{1};
        end
        myboxplot(pairTemp,'box',colMat(posCond))
        yline(0,'LineStyle','--','LineWidth',1.5,'Color','k')
        yline(thres*[-1 1],'LineStyle','--','LineWidth',1,'Color',.7*[1 1 1])
        title(sprintf('%s: Pairwise comparison Speech Intensity',uniSess{sess}))
        ylabel(sprintf('Intensity Difference from %s (dB)',pltcond{1}))
        set(gca,'xTick',1:size(pltcond,2),'XTickLabel',pltcond)
        if ~isempty(saveName)
            set(gcf,'Name',sprintf('%s_pairwiseCompare_%s_histogram%s',uniSess{sess},plotType,saveName))
        else
            set(gcf,'Name',sprintf('%s_pairwiseCompare_%s_histogram',uniSess{sess},plotType))
        end
        fH = [fH; gcf];
    end
end
end
