%% Run a pairwise analysis to determine if the contralateral and ipsilateral
% data is distinct

% Clear workspace and load the data
clear, close all
%load('G:\.shortcut-targets-by-id\1g3qpRQ2waZ6vllqg-hudrWpkOsJh9YAd\VOP Face\Figure1\Material\contra_ipsi_AllData.mat')
%load('contra_ipsi_AllData.mat')
%load('contra_ipsi_AllData_vim.mat')
load('contra_ipsi_AllData_vim_updated_Nov2025.mat')

%subj_list = subj_list([1:3 5:end]);
freq_labels = freq_labels(1:end-1);
%freq_labels = freq_labels(1:3); % December 2025 added to removed 100Hz
muscle = {'MYLO','ORIS','MASS','MENT','CRICO'}
idxBP = 1:length(freq_labels); % Number of freq to plot in raw box plot

plotType = 'mean';
matchPlt = 0; % Will plot the ipsi and contra plots on the same axis scale

% Set up the figure
axW = 500;
axSp = 100;
nCol = length(muscle);
[fW,fH,Ax] = calcFigureSize(1,nCol,axW,axW,axSp);
FNorm = figure('Position',[50 50 fW fH]);
FNorm.Name = sprintf('combined_normAUC_nuc_%s_%s',nuclei{1},plotType);
colScale = parula(length(subj_list));

%
normAll = [];
normStatAll = [];
for m = 1:length(muscle)
    contra = [];
    ipsi = [];
    LEGEND = [];
    for s = 1:length(subj_list)
        % for n = 1:length(nuclei)

            % Create the contralateral plots
            if ~isfield(ContraData.(subj_list{s}).(nuclei{s}),muscle{m})
                continue
            end
            tmpContr = ContraData.(subj_list{s}).(nuclei{s}).(muscle{m});
            numTrlC = cellfun(@length,tmpContr(idxBP));
            idxFrqC = find(numTrlC>1);
            % Create the scale plots.
            avgTmp = nan(size(idxFrqC));

            % Calculate the average/median value
            for n = 1:size(idxFrqC,2)
                if strcmp(plotType,'median')
                    avgTmp(n) = median(tmpContr{idxFrqC(n)},'omitnan');
                elseif strcmp(plotType,'mean')
                    avgTmp(n) = mean(tmpContr{idxFrqC(n)},'omitnan');
                end
            end
            % Normalize the data
            normTmp = 100*(avgTmp-avgTmp(1))./avgTmp(1);

            % Plot the data
            figure(FNorm)
            subplotSimple(1,length(muscle),m,'Ax',Ax)
            hold on
            plot(idxFrqC,normTmp,'o-','Color',colScale(s,:))
            set(gca,'XTick',1:length(freq_labels),...
                    'XTickLabel',freq_labels,'FontName','Arial','FontSize',7)
            title([muscle{m} ' ' plotType])
            LEGEND = [LEGEND subj_list(s)];
            
            % Save the normalization values
            normPos = nan(1,length(freq_labels));
            normPos(idxFrqC) = normTmp;

            normAll = [normAll; normPos];

            % Save the stat information
            statPos = nan(1,length(freq_labels));
            
            % Compare DCS with index
            for frqLoc = 1:length(freq_labels)
                if sum(ismember(idxFrqC,frqLoc)) > 0
                    [~,statPos(frqLoc)]=bootstrapCompMeans(tmpContr{1},tmpContr{frqLoc},10000,0.05,1);
                    %statPos(frqLoc) = rejectNull;
                end
            end

            normStatAll = [normStatAll; statPos];

        % end
    end

    subplotSimple(1,length(muscle),m,'Ax',Ax)
    legend(LEGEND,'Location','bestoutside')
end

%%


% Create the figure handles
for m = 1:length(muscle)
        F(m) = figure('Position',[1 41 1920 963]);
        F(m).Name = sprintf('IpsiContra_boxplots_%s',muscle{m});

        % Set up the figure
        axW = 276;
        axSp = 160;
        nCol = length(subj_list);
        [fW,fH,Ax] = calcFigureSize(2,nCol,axW,axW,axSp);

        Fbox(m) = figure('Position',[50 50 fW fH]);
        Fbox(m).Name = sprintf('Raw_boxplots_%s',muscle{m});
end

% Color map
colFreq = {'#FDB71A',... % No Stim
    '#24408B',... %50Hz
    '#445A8A',... % 80Hz
    '#666E89',... %100 Hz
    '#666E89',... %130 Hz
    '#FDB71A'}; % No Stim After

boxPlottingOpts = {'LineWidth',0.5,'WhiskerLineColor',[0 0 0],'MarkerSize',0.0016};

% Iterate through all muscles and nuclei
medIpsi = repmat({nan(length(subj_list),length(freq_labels))},length(muscle),1);%length(nuclei));
medContra = repmat({nan(length(subj_list),length(freq_labels))},length(muscle),1);%length(nuclei));
statIC = repmat({zeros(length(subj_list),length(freq_labels))},length(muscle),1);%length(nuclei));
for m = 1:length(muscle)
    contra = [];
    ipsi = [];
    for s = 1:length(subj_list)
        % for n = 1:length(nuclei)
            if isfield(IpsiData,(subj_list{s}))
                if isfield(IpsiData.(subj_list{s}),(nuclei{s}))
                    if isfield(ContraData.(subj_list{s}).(nuclei{s}),muscle{m}) && ...
                            isfield(IpsiData.(subj_list{s}).(nuclei{s}),muscle{m})


                        % % Collect the baseline data
                        % if ~isfield(ContraData.(subj_list{s}).(nuclei{n}),muscle{m})
                        %     continue
                        % end
                        baseline_c = median(ContraData.(subj_list{s}).(nuclei{s}).(muscle{m}){1,1},'omitnan');
                        baseline_i = median(IpsiData.(subj_list{s}).(nuclei{s}).(muscle{m}){1,1},'omitnan');

                        % Normalize the data for each stimulation frequency
                        for f = 1:length(freq_labels)
                            % Calculate the normalized contralateral data
                            rawContra = ContraData.(subj_list{s}).(nuclei{s}).(muscle{m}){1,f};
                            normContra = 100*(rawContra-baseline_c)./baseline_c;
                            ContraData.(subj_list{s}).(nuclei{s}).(['norm_' muscle{m}]){1,f} = normContra;

                            % Calculate the normalized ipsilateral data
                            rawIpsi = IpsiData.(subj_list{s}).(nuclei{s}).(muscle{m}){1,f};
                            normIpsi = 100*(rawIpsi-baseline_i)./baseline_i;
                            IpsiData.(subj_list{s}).(nuclei{s}).(['norm_' muscle{m}]){1,f} = normIpsi;

                            % Save the median information
                            medIpsi{m}(s,f) = median(normIpsi,'omitnan');
                            medContra{m}(s,f) = median(normContra,'omitnan');

                            %Plot the comparison
                            if sum(isnan(normContra))<length(normContra) &...
                                    sum(isnan(normIpsi))<length(normIpsi)
                                figure(F(m))
                                ax{m}(s,f) = subplot(length(freq_labels),length(subj_list),s+length(subj_list)*(f-1));
                                myboxplot({normIpsi(:);normContra(:)},'box',...
                                    {'#76aa3e','#ff5e5e','#ff815e','#ffa45e'},...
                                    0,ax{m}(s,f),0)
                                [statDat] = plotStatComparisons({normIpsi(:);normContra(:)},'plotNS',0);
                                statIC{m}(s,f) = statDat{2};
                                set(ax{m}(s,f),'XTick',1:2,'XTickLabel',{'Ipsi','Contra'})
                                title(sprintf('%s %s',subj_list{s},freq_labels{f}))
                            end
                        end
                    end
                end
            end
            % Create the box plot for the ipsi and contralateral traces
            figure(Fbox(m))

            % Create the contralateral plots
            if isfield(ContraData.(subj_list{s}).(nuclei{s}),muscle{m})
                axBoxC{m}(s) = subplotSimple(2,nCol,s,'Ax',Ax);
                tmpContr = ContraData.(subj_list{s}).(nuclei{s}).(muscle{m});
                numTrlC = cellfun(@length,tmpContr(idxBP));
                idxFrqC = find(numTrlC>1);
                myboxplot(tmpContr(idxBP)','box',colFreq(idxBP),0,...
                    axBoxC{m}(s),0,boxPlottingOpts)
                plotStatComparisons(tmpContr(idxBP)','plotNS',0,...
                    'compareGroups',{idxFrqC});
                set(axBoxC{m}(s),'XTick',1:length(freq_labels),...
                    'XTickLabel',freq_labels,'FontName','Arial','FontSize',7)
                title(sprintf('Contra: %s',subj_list{s}),...
                    'FontName','Arial','FontSize',7,'FontWeight','normal')
            end

            % Create the ipsilateral plots
            if isfield(IpsiData,(subj_list{s}))
                if isfield(IpsiData.(subj_list{s}).(nuclei{s}),muscle{m})
                    axBoxI{m}(s) = subplotSimple(2,nCol,s+length(subj_list),'Ax',Ax);
                    tmpIpsi = IpsiData.(subj_list{s}).(nuclei{s}).(muscle{m});
                    numTrlI = cellfun(@length,tmpIpsi(idxBP));
                    idxFrqI = find(numTrlI>1);
                    myboxplot(tmpIpsi(idxBP)','box',colFreq(idxBP),0,...
                        axBoxI{m}(s),0,boxPlottingOpts)
                    plotStatComparisons(tmpIpsi(idxBP)','plotNS',0,...
                        'compareGroups',{idxFrqI});
                    set(axBoxI{m}(s),'XTick',1:length(freq_labels),...
                        'XTickLabel',freq_labels,'FontName','Arial','FontSize',7)
                    title(sprintf('Ipsi: %s',subj_list{s}),...
                        'FontName','Arial','FontSize',7,'FontWeight','normal')

                    % Match the axis scale
                    if matchPlt && isfield(ContraData.(subj_list{s}).(nuclei{s}),muscle{m})
                        matchAxis([axBoxI{m}(s) axBoxC{m}(s)]);
                    end
                end
            end

            % Create the scale plots.
            avgTmp = nan(size(idxFrqC));

            % Calculate the average/median value
            for n = 1:size(idxFrqC,2)
                if strcmp(plotType,'median')
                    avgTmp(n) = median(tmpContr{idxFrqC(n)},'omitnan');
                elseif strcmp(plotType,'mean')
                    avgTmp(n) = mean(tmpContr{idxFrqC(n)},'omitnan');
                end
            end
            % Normalize the data
            normTmp = 100*(avgTmp-avgTmp(1))./avgTmp(1);

            % % Plot the data
            % figure(FNorm)
            % subplot(1,length(muscle),m)
            % hold on
            % plot(idxFrqC,normTmp,'o-','Color',colScale(n,:))
            % title(muscle{m})

        % end
    end
end

% Add the plot detail information
for m = 1:length(muscle)
    % for n = 1:length(nuclei)
        figure(F(m))
        plotTitle(muscle{m})
        % plotTitle(sprintf('%s %s',muscle{m},nuclei{n}))
    % end
end

%% Plot the line comparison
colFreq = {'FDB71A',... % No Stim
    '#24408B',... %50Hz
    '#445A8A',... % 80Hz
    '#666E89',...}; %100 Hz
    '#9096ac'}; %130Hz

% Set up the figure
axW = 101;
axSp = 50;
nCol = length(subj_list);
[fW,fH,Ax] = calcFigureSize(1,length(muscle)+1,axW,axW,axSp);

F2 = figure('Position',[50 50 fW fH]);
F2.Name = sprintf('IpsiContra_linePlot_%s',nuclei{1});
for m = 1:length(muscle)
    ax = {subplotSimple(1,length(muscle)+1,m,'Ax',Ax),...
        subplotSimple(1,length(muscle)+1,length(muscle)+1,'Ax',Ax)};

    for k = 1:length(ax)
        axes(ax{k}), hold on
        % iterate through the frequencies
        for n = 2:length(freq_labels)
            % Plot the insignificant traces
            idxIS = find(statIC{m,1}(:,n) == 0);
            if ~isempty(idxIS)
                plot([2 1],[medIpsi{m,1}(idxIS,n) medContra{m,1}(idxIS,n)]','o:',...
                    'Color',colFreq{n},'MarkerSize',4.5)
            end

            % Plot the significant traces (Greater Ipsi)
            idxSigI = find(statIC{m,1}(:,n) ~= 0 & medIpsi{m,1}(:,n)>medContra{m,1}(:,n));
            if ~isempty(idxSigI)
                plot([2 1],[medIpsi{m,1}(idxSigI,n) medContra{m,1}(idxSigI,n)]',...
                    'o--','Color',colFreq{n},...
                    'MarkerFaceColor',colFreq{n},'MarkerSize',4.5)
            end

            % Plot the significant traces (Greater Contra)
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

%% Calculate how large the potentiation is between the conditions
cL = [medContra{1}; medContra{2}; medContra{3}];
iL = [medIpsi{1}; medIpsi{2}; medIpsi{3}];
statAll = [statIC{1}; statIC{2}; statIC{3}];

% Remove the baseline condition
iL2 = iL(:,2:end);
cL2 = cL(:,2:end);
statAll2 = statAll(:,2:end);

% Find all the significant comparison indices
idx = find(statAll2~=0 & iL2>0 & cL2>0);

potentScaleIC = 100*(cL2(idx)-iL2(idx))./abs(iL2(idx));

medPotScaleIC = median(potentScaleIC);
avgPotScaleIC = mean(potentScaleIC);


%% Save the figures
saveFigurePDF([FNorm; F(:);F2(:);Fbox(:)])