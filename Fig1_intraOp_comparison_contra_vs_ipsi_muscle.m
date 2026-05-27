%% Fig1_intraOp_comparison_contra_vs_ipsi_muscle
% Pairwise analysis comparing contralateral and ipsilateral muscle responses
% to medial thalamus DCS across stimulation frequencies.
%
% Creates figure 1d, 1e, and supplementary figure 2 for the manuscript.
%
% Generates the following figures:
%   FNorm   Percent increase in normalized AUC from baseline (Fig 1e)
%   F       Ipsilateral vs. contralateral normalized boxplots per subject (Fig 1d)
%   Fbox    Raw data boxplots per subject (Supplementary Fig 2)
%   F2      Line plot comparing median ipsi vs. contra across subjects 
%
% Required Data:
%   Fig1_contra_ipsi_AllData_updated_Dec2025.mat
%       ContraData  Struct of contralateral EMG data, indexed by subject and nucleus
%       IpsiData    Struct of ipsilateral EMG data, indexed by subject and nucleus
%       subj_list   Cell array of subject IDs
%       nuclei      Cell array of stimulation nucleus for each subject
%       freq_labels Cell array of stimulation frequency labels
%
% User Configuration:
%   dataPath        Path to the folder containing the .mat data file
%   saveFigPath     Path to the folder where figures will be saved
%   savePlots       Set to 1 to save figures as PDF, 0 to skip saving
%
% Created by Lilly Tang, Erinn Grigsby, and Arianna Damiani
% Copyright (C) 2026

% Clear workspace and identify the data and figure saving locations.
% Edit the dataPath and saveFigPath as you need to.
clear, close all

curPath = pwd; addpath(genpath(curPath));
dataPath    = '/Users/zira/Data/mThal_NatComm_2026';
saveFigPath = '/Users/zira/analysisFigures/mThal_NatComm_2026_figs';
savePlots   = 0; % Set to 1 to save all figures as PDF

% Load the data and create the save folder if needed
load(fullfile(dataPath,'Fig1_contra_ipsi_AllData_updated_Dec2025.mat'))

if ~exist(saveFigPath,'dir') && savePlots
    mkdir(saveFigPath);
end

% Set the optional plot changes
freq_labelsPlt = freq_labels(1:3); % Plot No Stim, 50 Hz, and 80 Hz only
muscle = {'MYLO','ORIS','MASS','MENT','CRICO'};
idxBP = 1:length(freq_labelsPlt); % Column indices into per-subject data cells
plotType_1e = 'median'; % Summary statistic for normalization: 'median' or 'mean'

% Color map for this plot (one color per stimulation frequency)
colFreq = {'#FDB71A',... % No Stim
    '#24408B',... % 50 Hz
    '#445A8A',... % 80 Hz
    '#666E89',... % 100 Hz
    '#9096ac'};   % 130 Hz

%% Fig 1e: Percent increase in normalized AUC from baseline
matchPlt    = 0;        % Set to 1 to match y-axis scale between ipsi and contra plots

% Set up the figure
axW = 500;
axSp = 100;
nCol = length(muscle);
[fW,fH,Ax] = calcFigureSize(1,nCol,axW,axW,axSp);
FNorm = figure('Position',[50 50 fW fH]);
FNorm.Name = sprintf('percentIncrease_normAUC_combinedAllNuclei_%s',plotType_1e);
colScale = parula(length(subj_list)); % One color per subject

normAll     = []; % Collects normalized percent-increase values across subjects
normStatAll = []; % Collects per-frequency significance flags (1=significant, 0=not)

for m = 1:length(muscle)
    LEGEND = [];
    for s = 1:length(subj_list)

        % Skip this subject if the muscle was not recorded contralaterally
        if ~isfield(ContraData.(subj_list{s}).(nuclei{s}),muscle{m})
            continue
        end

        tmpContr = ContraData.(subj_list{s}).(nuclei{s}).(muscle{m});

        % idxFrqC: indices of frequencies with more than 1 trial
        numTrlC  = cellfun(@length,tmpContr(idxBP));
        idxFrqC  = find(numTrlC>1);

        % Calculate the summary value (median or mean) per frequency
        avgTmp = nan(size(idxFrqC));
        for n = 1:size(idxFrqC,2)
            if strcmp(plotType_1e,'median')
                avgTmp(n) = median(tmpContr{idxFrqC(n)},'omitnan');
            elseif strcmp(plotType_1e,'mean')
                avgTmp(n) = mean(tmpContr{idxFrqC(n)},'omitnan');
            end
        end

        % Normalize to baseline (index 1 = no-stim condition)
        normTmp = 100*(avgTmp-avgTmp(1))./avgTmp(1);

        % Plot the normalized trajectory for this subject
        figure(FNorm)
        subplotSimple(1,length(muscle),m,'Ax',Ax)
        hold on
        plot(idxFrqC,normTmp,'o-','Color',colScale(s,:))
        set(gca,'XTick',1:length(freq_labelsPlt),...
                'XTickLabel',freq_labelsPlt,'FontName','Arial','FontSize',7)
        if strcmp(muscle{m},'MENT') && s == length(subj_list)
            yTickVal = gca().get('YTick');
            set(gca,'YTick',unique([yTickVal 250 25]))
        end
        title([muscle{m} ' ' plotType_1e])
        LEGEND = [LEGEND subj_list(s)];

        % Store normalized values (NaN for frequencies without enough trials)
        normPos = nan(1,length(freq_labelsPlt));
        normPos(idxFrqC) = normTmp;
        normAll = [normAll; normPos];

        % Test each stimulation frequency against the no-stim baseline (index 1)
        statPos = nan(1,length(freq_labelsPlt));
        for frqLoc = 1:length(freq_labelsPlt)
            if sum(ismember(idxFrqC,frqLoc)) > 0
                [~,statPos(frqLoc)] = bootstrapCompMeans(tmpContr{1},tmpContr{frqLoc},10000,0.05,1);
            end
        end
        normStatAll = [normStatAll; statPos];
    end

    subplotSimple(1,length(muscle),m,'Ax',Ax)
    legend(LEGEND,'Location','bestoutside')
end

%% Fig 1d and Supplementary Fig 2: Ipsi vs. contra boxplots per subject and frequency
%plotType_IpsiContra = 'mean';

% Create one figure per muscle for ipsi/contra comparison and one for raw boxplots
for m = 1:length(muscle)
    F(m) = figure('Position',[1 41 1920 963]);
    F(m).Name = sprintf('IpsiContra_boxplots_%s',muscle{m});

    axW = 276;
    axSp = 160;
    nCol = length(subj_list);
    [fW,fH,Ax] = calcFigureSize(2,nCol,axW,axW,axSp);

    Fbox(m) = figure('Position',[50 50 fW fH]);
    Fbox(m).Name = sprintf('Raw_boxplots_%s',muscle{m});
end

boxPlottingOpts = {'LineWidth',0.5,'WhiskerLineColor',[0 0 0],'MarkerSize',0.0016};

% Pre-allocate summary matrices: rows = subjects, cols = frequencies
medIpsi  = repmat({nan(length(subj_list),length(freq_labelsPlt))},length(muscle),1);
medContra= repmat({nan(length(subj_list),length(freq_labelsPlt))},length(muscle),1);

% statIC: 0 = not significant, nonzero = significant ipsi vs. contra difference
statIC   = repmat({zeros(length(subj_list),length(freq_labelsPlt))},length(muscle),1);

for m = 1:length(muscle)
    for s = 1:length(subj_list)

        % Ipsi vs. contra normalized comparison (requires both sides present)
        if isfield(IpsiData,(subj_list{s}))
            if isfield(IpsiData.(subj_list{s}),(nuclei{s}))
                if isfield(ContraData.(subj_list{s}).(nuclei{s}),muscle{m}) && ...
                        isfield(IpsiData.(subj_list{s}).(nuclei{s}),muscle{m})

                    % Baseline = median of the no-stim condition (index 1)
                    baseline_c = median(ContraData.(subj_list{s}).(nuclei{s}).(muscle{m}){1,1},'omitnan');
                    baseline_i = median(IpsiData.(subj_list{s}).(nuclei{s}).(muscle{m}){1,1},'omitnan');

                    for f = 1:length(freq_labelsPlt)
                        % Normalize each trial to the per-subject baseline
                        rawContra  = ContraData.(subj_list{s}).(nuclei{s}).(muscle{m}){1,f};
                        normContra = 100*(rawContra-baseline_c)./baseline_c;
                        ContraData.(subj_list{s}).(nuclei{s}).(['norm_' muscle{m}]){1,f} = normContra;

                        rawIpsi  = IpsiData.(subj_list{s}).(nuclei{s}).(muscle{m}){1,f};
                        normIpsi = 100*(rawIpsi-baseline_i)./baseline_i;
                        IpsiData.(subj_list{s}).(nuclei{s}).(['norm_' muscle{m}]){1,f} = normIpsi;

                        medIpsi{m}(s,f)   = median(normIpsi,'omitnan');
                        medContra{m}(s,f) = median(normContra,'omitnan');

                        % Plot only if both sides have valid data
                        if sum(isnan(normContra))<length(normContra) && ...
                                sum(isnan(normIpsi))<length(normIpsi)
                            figure(F(m))
                            ax{m}(s,f) = subplot(length(freq_labelsPlt),length(subj_list),...
                                s+length(subj_list)*(f-1));
                            myboxplot({normIpsi(:);normContra(:)},'box',...
                                {'#76aa3e','#ff5e5e','#ff815e','#ffa45e'},...
                                0,ax{m}(s,f),0)
                            [statDat] = plotStatComparisons({normIpsi(:);normContra(:)},'plotNS',0);
                            statIC{m}(s,f) = statDat{2};
                            set(ax{m}(s,f),'XTick',1:2,'XTickLabel',{'Ipsi','Contra'})
                            title(sprintf('%s %s',subj_list{s},freq_labelsPlt{f}))
                        end
                    end
                end
            end
        end

        % Create the box plot for the ipsi and contralateral traces
        figure(Fbox(m))

        % Raw contralateral boxplot (Fbox top row)
        if isfield(ContraData.(subj_list{s}).(nuclei{s}),muscle{m})
            tmpContr = ContraData.(subj_list{s}).(nuclei{s}).(muscle{m});
            numTrlC  = cellfun(@length,tmpContr(idxBP));
            idxFrqC  = find(numTrlC>1);
            axBoxC{m}(s) = subplotSimple(2,nCol,s,'Ax',Ax);
            myboxplot(tmpContr(idxBP)','box',colFreq(idxBP),0,...
                axBoxC{m}(s),0,boxPlottingOpts)
            plotStatComparisons(tmpContr(idxBP)','plotNS',0,...
                'compareGroups',{idxFrqC});
            set(axBoxC{m}(s),'XTick',1:length(freq_labelsPlt),...
                'XTickLabel',freq_labelsPlt,'FontName','Arial','FontSize',7)
            title(sprintf('Contra: %s',subj_list{s}),...
                'FontName','Arial','FontSize',7,'FontWeight','normal')
        end

        % Raw ipsilateral boxplot (Fbox bottom row)
        if isfield(IpsiData,(subj_list{s}))
            if isfield(IpsiData.(subj_list{s}),(nuclei{s}))
                if isfield(IpsiData.(subj_list{s}).(nuclei{s}),muscle{m})
                    tmpIpsi = IpsiData.(subj_list{s}).(nuclei{s}).(muscle{m});
                    numTrlI = cellfun(@length,tmpIpsi(idxBP));
                    idxFrqI = find(numTrlI>1);
                    axBoxI{m}(s) = subplotSimple(2,nCol,s+length(subj_list),'Ax',Ax);
                    myboxplot(tmpIpsi(idxBP)','box',colFreq(idxBP),0,...
                        axBoxI{m}(s),0,boxPlottingOpts)
                    plotStatComparisons(tmpIpsi(idxBP)','plotNS',0,...
                        'compareGroups',{idxFrqI});
                    set(axBoxI{m}(s),'XTick',1:length(freq_labelsPlt),...
                        'XTickLabel',freq_labelsPlt,'FontName','Arial','FontSize',7)
                    title(sprintf('Ipsi: %s',subj_list{s}),...
                        'FontName','Arial','FontSize',7,'FontWeight','normal')

                    % Optionally match y-axis scale between ipsi and contra
                    if matchPlt && isfield(ContraData.(subj_list{s}).(nuclei{s}),muscle{m})
                        matchAxis([axBoxI{m}(s) axBoxC{m}(s)]);
                    end
                end
            end
        end
    end
end

% Add muscle label as figure title
for m = 1:length(muscle)
    figure(F(m))
    plotTitle(muscle{m})

    figure(Fbox(m))
    plotTitle(muscle{m})
end

%% Line plot: median ipsi vs. contra per subject, grouped by significance
% Line style encodes significance and direction of the ipsi vs. contra difference:
%   dotted  (:)  = not significant
%   dashed (--) = significant, ipsi > contra
%   solid  (-) = significant, contra > ipsi

% Set up the figure
axW = 101;
axSp = 50;
[fW,fH,Ax] = calcFigureSize(1,length(muscle)+1,axW,axW,axSp);

F2 = figure('Position',[50 50 fW fH]);
F2.Name = sprintf('IpsiContra_linePlot_%s',nuclei{1}); % Named by the nucleus of the first subject (assumes all subjects have the same nucleus)

for m = 1:length(muscle)
    % Last subplot (length(muscle)+1) overlays all muscles together
    ax = {subplotSimple(1,length(muscle)+1,m,'Ax',Ax),...
        subplotSimple(1,length(muscle)+1,length(muscle)+1,'Ax',Ax)};

    for k = 1:length(ax)
        axes(ax{k}), hold on

        % Skip the no-stim condition (index 1) — only plot stimulation frequencies
        for n = 2:length(freq_labelsPlt)

            % Not significant: dotted line, open markers
            idxIS = find(statIC{m,1}(:,n) == 0);
            if ~isempty(idxIS)
                plot([2 1],[medIpsi{m,1}(idxIS,n) medContra{m,1}(idxIS,n)]','o:',...
                    'Color',colFreq{n},'MarkerSize',4.5)
            end

            % Significant, ipsi > contra: dashed line, filled markers
            idxSigI = find(statIC{m,1}(:,n) ~= 0 & medIpsi{m,1}(:,n)>medContra{m,1}(:,n));
            if ~isempty(idxSigI)
                plot([2 1],[medIpsi{m,1}(idxSigI,n) medContra{m,1}(idxSigI,n)]',...
                    'o--','Color',colFreq{n},...
                    'MarkerFaceColor',colFreq{n},'MarkerSize',4.5)
            end

            % Significant, contra > ipsi: solid line, filled markers, thicker
            idxSigC = find(statIC{m,1}(:,n) ~= 0 & medIpsi{m,1}(:,n)<medContra{m,1}(:,n));
            if ~isempty(idxSigC)
                plot([2 1],[medIpsi{m,1}(idxSigC,n) medContra{m,1}(idxSigC,n)]',...
                    'o-','Color',colFreq{n},'LineWidth',1.5,...
                    'MarkerFaceColor',colFreq{n},'MarkerSize',4.5)
            end
        end
        set(ax{k},'XTick',[1 2],'XTickLabel',{'Contra','Ipsi'},...
            'FontName','Arial','FontSize',7)
        ylabel('Percent Increase from DCS')
        if k == 1
            % Title shows muscle name and fraction of significant comparisons
            title(sprintf('%s, sig = %1.0f/%2.0f',muscle{m},...
                sum(sum(statIC{m,1}(:,2:end)~=0)),...
                sum(sum(~isnan(medContra{m,1}(:,2:end))))),...
                'FontName','Arial','FontSize',7)
        else
            title('All Muscles','FontName','Arial','FontSize',7)
        end
        axis square
    end
end

%% Potentiation magnitude: how much larger is contra vs. ipsi for significant pairs
% Only considers cases where both contra and ipsi show a positive response
% and the ipsi vs. contra comparison is significant (statAll2 ~= 0)

cL      = cell2mat(medContra);  % All muscles x subjects x frequencies
iL      = cell2mat(medIpsi);
statAll = cell2mat(statIC);

% Remove the no-stim baseline column (index 1)
cL2      = cL(:,2:end);
iL2      = iL(:,2:end);
statAll2 = statAll(:,2:end);

% Restrict to significant pairs where both sides are positive (net potentiation)
idx = find(statAll2~=0 & iL2>0 & cL2>0);

% Percent difference in potentiation: how much larger is contra relative to ipsi
potentScaleIC  = 100*(cL2(idx)-iL2(idx))./abs(iL2(idx));
medPotScaleIC  = median(potentScaleIC);
avgPotScaleIC  = mean(potentScaleIC);

%% Save the figures
if savePlots
    saveFigurePDF([FNorm; F(:);F2(:);Fbox(:)],saveFigPath)
end
