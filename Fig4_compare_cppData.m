% Load and process the CPPS data and create comparison plots. Note: This
% code is a little messy at the plotting stage currently.
%
% Created by Erinn Grigsby
% Copyright (C) by Erinn Grigsby
% Emails: erinn.grigsby@gmail.com
clear
close all
% Compare the CCPS data
% load('D:\RNEL\human\Chronic_DBS\Subject001\PRAAT_files_wPhonemes\fileCondition_Information_Subject001+Subject004.mat')
% load('D:\RNEL\human\Chronic_DBS\Subject001\PRAAT_files_wPhonemes\CPPS_results_ltas_4.mat')
%load('D:\RNEL\human\Chronic_DBS\Subject001\PRAAT_files_wPhonemes\Subject001_fileCondition_Information.mat')
%load('D:\RNEL\human\Chronic_DBS\Subject001\PRAAT_files_wPhonemes\CPPS_results.mat')
%load('C:\Users\emg27\Dropbox\PostDoc\ElviraMarco\One-on-One\20241214\CPPS_results_2024_info.mat')
%load('C:\Users\emg27\Dropbox\PostDoc\ElviraMarco\One-on-One\20241214\CPPS_results_2024.mat')
%load('/Volumes/rnelshare/projects/human/VOP STIM/Papers/VOP Face/Data/CPPS_results_2024.mat')
load("/Users/zira/Library/CloudStorage/Dropbox/PostDoc/ElviraMarco/One-on-One/20241214/CPPS_results_2024.mat")

% Determine which 2
% Identify each unique word, condition, and session
if ismember({'datasetString'},fileInfoTable.Properties.VariableNames)
    [uniSess,~,idxSess] = unique(fileInfoTable.datasetString);
else
    [uniSess,~,idxSess] = unique(fileInfoTable.dataset);
end
[uniCond,~,idxCond] = unique(fileInfoTable.condition);
[uniWord,~,idxWord] = unique(fileInfoTable.word);

% Create a combination index of word, cond, and session pairings
[uniWCS,~,idxWCS] = unique([idxWord idxCond idxSess],'rows');

sessions = {'20220824','20220825','20220826','20220911','20220914',...
        '20220919','20220923','20230630'}; % Sessions used for publication
%
%close all
plotDat = 'cpps'; 
[sigVal,avgNS,avgS55,avgS80,avgS130] = deal(nan(size(uniWord,1),size(uniSess,1)));
% cpps is working really well and is consistently showing an increase
% except for June 30th
for sess = 1:size(uniSess,1)
    % Skip if the session not part of the publication ready data
    if ~ismember(uniSess(sess),sessions)
        continue
    end

    % Determine how many unique words are in each sess 
    uniSessWord = unique(idxWord(idxSess == sess));
    num_SessWord = size(uniSessWord,1);
    allNS{sess} = [];
    allS55{sess} = [];
    allS80{sess} = [];
    allS130{sess} = [];
    for word = 1:size(uniWord,1)
        tmpDat = cell(0);
        for k = 1:4
            if  k == 1 & ismember(uniSess(sess),{'20220205','20220211'})
                cond = find(ismember(uniCond,'No Stim'));
            elseif k == 2 & ismember(uniSess(sess),{'20220205','20220211'}) 
                cond = find(ismember(uniCond,'50Hz'));
            elseif k == 3 & ismember(uniSess(sess),{'20220205','20220211'})   
                cond = find(ismember(uniCond,'100Hz'));
            elseif k == 1
                cond = find(ismember(uniCond,'No Stim'));
            elseif k == 2
                cond = find(ismember(uniCond,'55Hz'));
            elseif k == 3
                cond = find(ismember(uniCond,'130Hz'));
            else %cond = 1;
                cond = find(ismember(uniCond,{'80Hz'}));
            end%1:size(uniCond,1)
            mask = find(ismember([idxWord idxCond idxSess],[word cond sess],"rows"));
            if size(mask,1) >=5 & ~ismember(uniSess(sess),{'20220205','20220211'})
                tmpDat{k,1} = CPPSresults.(plotDat)(mask(2:5));
            elseif size(mask,1) > 0
                tmpDat{k,1} = CPPSresults.(plotDat)(mask(2:end));
            else
                tmpDat{k,1} = [];
            end
        end
        if ~isempty(tmpDat{1}) & ~isempty(tmpDat{2})
            avgNS(word,sess) = mean(tmpDat{1});
            avgS55(word,sess) = mean(tmpDat{2});
            tmpDatOG = tmpDat;
            
            % Normalize the data
            tmpDat{2} = 100*(tmpDat{2} - mean(tmpDat{1}))./mean(tmpDat{1});
            if ~isempty(tmpDat{3})
                avgS130(word,sess) = mean(tmpDat{3});
                tmpDat{3} = 100*(tmpDat{3} - mean(tmpDat{1}))./mean(tmpDat{1});
            elseif ~isempty(tmpDat{4})
                avgS80(word,sess) = mean(tmpDat{4});
                tmpDat{4} = 100*(tmpDat{4} - mean(tmpDat{1}))./mean(tmpDat{1});
            end
            tmpDat{1} = 100*(tmpDat{1} - mean(tmpDat{1}))./mean(tmpDat{1});
            
            allNS{sess} = [allNS{sess}; tmpDatOG{1} word*ones(size(tmpDatOG{1}))];
            allS55{sess} = [allS55{sess}; tmpDatOG{2} word*ones(size(tmpDatOG{2}))];
            allS130{sess} = [allS130{sess}; tmpDatOG{3} word*ones(size(tmpDatOG{3}))];
            allS80{sess} = [allS80{sess}; tmpDatOG{4} word*ones(size(tmpDatOG{4}))];

            F(sess) = figure(sess)%, set(gcf,'Position',[1 41 1920 963])
            F(sess).Name = sprintf('%s_boxplots_%s',uniSess{sess},plotDat);

            [xx,yy] = optSubplotLayout(num_SessWord+1);
            pos = find(uniSessWord == word);
            ax = subplot(xx,yy,pos); hold on
            % figure(word), set(gcf,'Position',[1 41 1920 963])
            % ax = subplot(2,4,sess); hold on
            myboxplot(tmpDatOG,'box',{'#edb965','#053dad','#11190d','#11190d'},0,ax)
            mask = ones(size(tmpDatOG))
            if size(tmpDat{3}) == 0
                mask(3) = 0;
            elseif size(tmpDat{4}) == 0
                mask(4) = 0;
            end
            statDat = plotStatComparisons(tmpDatOG,'compareGroups',{find(mask==1)});
            sigVal(word,sess) = statDat{2}(1);
            if pos == 1
                ylabel(sprintf('Percent Change from No Stim to Stim (%s)',plotDat))
            end
            title(sprintf('%s %s Comparison: %s',uniSess{sess},uniWord{word}, plotDat))%Word{word})
        end
    end
   % matchAxis(gcf)

   % Plot the histogram difference
   normVal = mean(allNS{sess}(:,1),'omitnan');
   subplot(xx,yy,pos+1); hold on
   histogram(100*(allNS{sess}(:,1)-normVal)./normVal,'BinWidth',5)
   histogram(100*(allS55{sess}(:,1)-normVal)./normVal,'BinWidth',5)
   if ~isempty(allS80{sess})
       histogram(100*(allS80{sess}(:,1)-normVal)./normVal,'BinWidth',5)
   end

   allNS_norm{sess} = [100*(allNS{sess}(:,1)-normVal)./normVal]';
   allS_norm{sess} = [100*(allS55{sess}(:,1)-normVal)./normVal]';
end

% Plot a heatmap of the comparison
colMat = [255,255,255;... % White for the nans
    185, 145, 10;... % Gold
    208, 190, 132;...
    230, 213, 129;...
    237 237 237;... Not Significant Greay
    140, 178, 241;...
    39, 128, 181;...
    69, 69, 135]./255; % blue    

tmp = sigVal;
tmp(isnan(sigVal)) = -4;
F2 = figure('Position',[55 300 965 589]); 
F2.Name = sprintf('statComparison_HeatMaps_%s',plotDat);
imagesc(tmp)
axis square
colormap(colMat)
h = colorbar;
set(h,'Ticks',[-3 -2 -1 0 1 2 3],'TickLabels',...
    {'Decrease (p<0.001)','(p<0.01)','(p<0.05)','n.s','(p<0.05)','(p<0.01)','Increase (p<0.001)'})

set(gca,'YTick',1:size(uniWord,1),'YTickLabel',uniWord,...
    'XTick',1:size(uniSess),'XTickLabelRotation',30,'XTickLabel',uniSess)
ylabel('Words'), xlabel('Sessions')
title(sprintf('Statistic Comparison: %s',plotDat))

%% Create a scatter plot of the values
sz = 20;
F2(2) = figure; hold on
F2(2).Name = sprintf('statComparison_scatterPlot_%s',plotDat);
scatter(avgNS(sigVal==0),avgS55(sigVal==0),sz,[.6 .6 .6])%,'o','Color',
scatter(avgNS(sigVal>0),avgS55(sigVal>0),sz,[69, 69, 135]./255,'filled')%'o','Color',)
scatter(avgNS(sigVal<0),avgS55(sigVal<0),sz,[185, 145, 10]./255,'filled')%'o','Color',
gx = gca;
axLim = [gx.XLim gx.YLim];
line([min(axLim) max(axLim)],[min(axLim) max(axLim)],'Color','k','LineStyle','--')
xlabel('No Stim (dB)'),ylabel('55Hz Stim (dB)'),title(plotDat)

% Plot histogram of the raw difference
figure; histogram(avgS55 - avgNS,'BinWidth',.5)
xline(mean(avgS55(:) - avgNS(:),'omitnan'),'Color','r','LineWidth',2)
title(['Raw Difference: ' plotDat])
xlabel(plotDat)

% Plot histogram of the normalized difference
figure; histogram(100*(avgS55 - avgNS)./avgNS,'BinWidth',5)
xline(mean(100*(avgS55(:) - avgNS(:))./avgNS(:),'omitnan'),'Color','r','LineWidth',2)
mean(100*(avgS55(:) - avgNS(:))./avgNS(:),'omitnan')
title(['Normalized Difference: ' plotDat])
xlabel('Percent Difference')

%% Plot Longitudinal


baseNS = repmat({}, size(idxSess,1),1);
base55 = repmat({}, size(idxSess,1),1);

%Plot Longitudinally
for n = 1:size(uniSess,1)
    baseNS = [baseNS; allNS{n}(:,1)];
    base55 = [base55; allS55{n}(:,1)];
end

% NoStim
G(1) = figure; hold on
G(1).Name = 'Nostim Across Sessions';
myboxplot(baseNS, 'violin')
title('NoStim Across Session')
xticklabels(uniSess)

% 55Hz
G(2) = figure; hold on
G(2).Name = '55Hz Across Sessions';
myboxplot(base55, 'violin')
title('55Hz Across Session')
xticklabels(uniSess)

%% Plot the box plot of the distribution combining all words - BP

G(1) = figure;
G(1).Name = 'CPPS_bySession_normBySess_NS_Median_TBI01';

for n = 1:size(uniSess,1)
    [xx,yy] = optSubplotLayout(size(uniSess,1));
    ax = subplot(xx,yy,n);
    normVal = median(allNS{n}(:,1),'omitnan');
    
    % Normalized matrix
    norMat{n,1} = 100*(allNS{n}(:,1)-normVal)./normVal; %NoStim
    norMat{n,2} = 100*(allS55{n}(:,1)-normVal)./normVal; %55Hz

    myboxplot({100*(allNS{n}(:,1)-normVal)./normVal,...
        100*(allS55{n}(:,1)-normVal)./normVal}','violin',{'#edb965','#053dad','#626E80'},1,ax)
        %100*(allS130{n}(:,1)-normVal)./normVal}','violin',{'#edb965','#053dad','#626E80'},1,ax)
    yline(0,'Color',[.7 .7 .7],'LineStyle','--')
     ylabel('CPPS normalized (%)')
    title(uniSess{n})
end
matchAxis(gcf);
plotTitle([plotDat ' combine across all words'])

%% Find & Plot Difference of Change between NS v. 55Hz
close all

for n = 1:size(norMat,1) %sessions
   normDiff(n) = mean(norMat{n,2}) - mean(norMat{n,1}); %Stim 55Hz - NoStim
end

OFF_idx = [2 5 8 10];
ON_idx = [1 3 4 6 7 9 11];

L(1) = figure;
L(1).Name = 'Difference of Change between 55Hz v NoStim';

%All Sessions
subplot(3,1,1)
plot(normDiff, '-o'), hold on
yline(0, '--')
xticks(1:length(normDiff))
xticklabels(uniSess)
ylabel('CPPS Difference')
title('All')

%Stim ON First
subplot(3,1,2)
for s = 1:length(ON_idx)
    onDiff(s) = normDiff(ON_idx(s));
end
plot(onDiff, '-o'), hold on
yline(0, '--')
xticks(1:length(ON_idx))
xticklabels(uniSess(ON_idx))
ylabel('CPPS Difference')
title('Stim ON First')

%Stim OFF First
subplot(3,1,3)
for s = 1:length(OFF_idx)
    offDiff(s) = normDiff(OFF_idx(s));
end
plot(offDiff, '-o'), hold on
yline(0, '--')
xticks(1:length(offDiff))
xticklabels(uniSess(OFF_idx))
ylabel('CPPS Difference')
title('Stim OFF First')

sgtitle('Difference of 55Hz v. NoStim Normalized')

%saveFigurePDF([F(:); F2(:)],'D:\Dropbox\PostDoc\ElviraMarco\One-on-One\20240619')

%% Plot the box plot of the distribution combining all words - 130Hz
G(1) = figure;
G(1).Name = 'CPPS_bySession_normBySess_NS_Median';
for n = [8 11]%1:size(uniSess,1)
    ax = gca; %subplot(2,5,n)
    normVal = median(allNS{n}(:,1),'omitnan');
    myboxplot({100*(allNS{n}(:,1)-normVal)./normVal,...
        100*(allS55{n}(:,1)-normVal)./normVal,...}','violin',{'#edb965','#053dad','#626E80'},1,ax)
        100*(allS130{n}(:,1)-normVal)./normVal}','violin',{'#edb965','#053dad','#626E80'},1,ax)
    yline(0,'Color',[.7 .7 .7],'LineStyle','--')
    title(uniSess{n})
end
matchAxis(gcf);
plotTitle([plotDat ' combine across all words'])

%saveFigurePDF([F(:); F2(:)],'D:\Dropbox\PostDoc\ElviraMarco\One-on-One\20240619')

%% Plot the box plot of the distribution combining all words - 80 Hz
for n = [1 4]%8%1:size(uniSess,1)
    G(ceil(n/2)) = figure;
    G(ceil(n/2)).Name = ['CPPS_' uniSess{n} '_normBySess_NS_Median_80Hz'];
    ax = gca; %subplot(2,5,n)
    normVal = median(allNS{n}(:,1),'omitnan');
    myboxplot({100*(allNS{n}(:,1)-normVal)./normVal,...
        100*(allS55{n}(:,1)-normVal)./normVal,...}','violin',{'#edb965','#053dad','#626E80'},1,ax)
        100*(allS80{n}(:,1)-normVal)./normVal}','violin',{'#edb965','#053dad','#626E80'},1,ax)
    yline(0,'Color',[.7 .7 .7],'LineStyle','--')
    ylabel('CPPS normalized to the mean no stim value')
    title(uniSess{n})
end
matchAxis(gcf);
plotTitle([plotDat ' combine across all words'])

%% Plot the box plot of the distribution combining all words - 80 Hz/130
for n = 11%[1 4]%8%1:size(uniSess,1)
    G(ceil(n/2)) = figure;
    G(ceil(n/2)).Name = ['CPPS_' uniSess{n} '_normBySess_NS_Median_80Hz'];
    ax = gca %subplot(2,5,n)
    normVal = median(allNS{n}(:,1),'omitnan');
    myboxplot({100*(allNS{n}(:,1)-normVal)./normVal,...
        100*(allS55{n}(:,1)-normVal)./normVal,...}','violin',{'#edb965','#053dad','#626E80'},1,ax)
        100*(allS80{n}(:,1)-normVal)./normVal,...}','violin',{'#edb965','#053dad','#626E80'},1,ax)
        100*(allS130{n}(:,1)-normVal)./normVal}','violin',{'#edb965','#053dad','#626E80','#626E80'},1,ax)
    yline(0,'Color',[.7 .7 .7],'LineStyle','--')
    ylabel('CPPS normalized to the mean no stim value')
    title(uniSess{n})
    set(gca,'XTickLabel',{'No Stim','55Hz','80Hz','130Hz'})
end
matchAxis(gcf);
plotTitle([plotDat ' combine across all words'])
%% Create a percentage change plot, combing across all sessions

% Normalize by the mean
b = mean(avgNS(:),'omitnan'); 
myboxplot({100*(avgNS(:)-b)./b;...
    100*(avgS55(:)-b)./b;...
    100*(avgS80(:)-b)./b;...
    100*(avgS130(:)-b)./b},'violin',{'#edb965','#053dad','#626E80','#626E80'})
yline(0,'Color',[.7 .7 .7],'LineStyle','--')
set(gca,'XTick',1:4,'XTickLabel',{'No Stim','Stim'})
title('CPPS all session data')
ylabel('CPPS normalized to the mean no stim value')
G(2) = gcf;
G(2).Name = 'CPPS_allSessions_normByAll_NS_Mean';

%% Normalize by the median
b = median(avgNS(:),'omitnan'); 
myboxplot({100*(avgNS(:)-b)./b;...
    100*(avgS55(:)-b)./b;...
    100*(avgS80(:)-b)./b;...
    100*(avgS130(:)-b)./b},'violin',{'#edb965','#053dad','#626E80','#626E80'})
yline(0,'Color',[.7 .7 .7],'LineStyle','--')
set(gca,'XTick',1:4,'XTickLabel',{'No Stim','55Hz Stim','80Hz Stim','130Hz Stim'})
title('CPPS all session data')
ylabel('CPPS normalized to the median no stim value')
G(3) = gcf;
G(3).Name = 'CPPS_allSessions_normByAll_NS_Median';

%% Normalize by the median 80 Hz
tAvgNS = avgNS(:,[1 4]);
tAvgS55 = avgS55(:,[1 4]);
tAvgS80 = avgS80(:,[1 4]);

b = median(tAvgNS(:),'omitnan'); 
myboxplot({100*(tAvgNS(:)-b)./b;...
    100*(tAvgS55(:)-b)./b;...
    100*(tAvgS80(:)-b)./b},'violin',{'#edb965','#053dad','#626E80'})
yline(0,'Color',[.7 .7 .7],'LineStyle','--')
set(gca,'XTick',1:3,'XTickLabel',{'No Stim','55Hz Stim','80Hz Stim'})
title('CPPS all session data')
ylabel('CPPS normalized to the median no stim value')
G(3) = gcf;
G(3).Name = 'CPPS_allSessions_normByAll_NS_Median_911+824';
%% Create a scatter plot by session
% Create a scatter plot of the values
sz = 20;
for n = 1:size(uniSess,1)
    F3(n) = figure; hold on
    F3(n).Name = sprintf('%s_statComparison_scatterPlot_%s',uniSess{n},plotDat);
    scatter(avgNS(sigVal(:,n)==0,n),avgS55(sigVal(:,n)==0,n),sz,[.6 .6 .6])%,'o','Color',
    scatter(avgNS(sigVal(:,n)>0,n),avgS55(sigVal(:,n)>0,n),sz,[69, 69, 135]./255,'filled')%'o','Color',)
    scatter(avgNS(sigVal(:,n)<0,n),avgS55(sigVal(:,n)<0,n),sz,[185, 145, 10]./255,'filled')%'o','Color',
    gx = gca;
    axLim = [gx.XLim gx.YLim];
    line([min(axLim) max(axLim)],[min(axLim) max(axLim)],'Color','k','LineStyle','--')
    xlabel('No Stim (dB)'),ylabel('55Hz Stim (dB)'),title([uniSess{n} ' ' plotDat])
end
%saveFigurePDF([F3(:)])