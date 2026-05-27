%% Fig4_plotIntensityScatterPlot
% Scatter plot analysis of speech intensity comparing no-stimulation and
% stimulation conditions, with clinical relevance categorization.
%
% Creates the intensity scatter plot panels for figure 4 of the manuscript.
%
% Generates the following figures:
%   F2   Scatter plot of mean word intensity: No Stim vs. Stim, colored by word (grayscale)
%   Fh   Histogram of per-session intensity differences (Stim - No Stim)
%   F3   Scatter plot colored by clinical relevance category (±5 dB thresholds)
%
% Required Data:
%   Fig4_A_Fig5_intensityData.mat
%       datWord     Struct array of per-word intensity data, one entry per word.
%                   Each entry has fields: word, uniSess, inten (cell), sigVal (cell)
%       uniWord     Cell array of unique word labels
%       subject     Subject identifier string used for figure naming
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
% Load the intensity data
clear, close all

curPath = pwd; addpath(genpath(curPath));
dataPath    = '/Users/zira/Data/mThal_NatComm_2026';
saveFigPath = '/Users/zira/analysisFigures/mThal_NatComm_2026_figs';
savePlots   = 0; % Set to 1 to save figures as PDF

load(fullfile(dataPath,'Fig4_A_Fig5_intensityData.mat'))

if ~exist(saveFigPath,'dir') && savePlots
    mkdir(saveFigPath);
end

%% Create a scatter plot for each of the words.

colMatScat = gray(size(datWord,2));
posNS = 1;
posS = 2;

sz = 35;
F2 = figure('Position',[680 270 924 728]); hold on
cntNS = 0;
cntS = 0;
checkWord = [];
check = [];
checkNS = [];
checkS = [];
for n = 1:size(datWord,2)
    for k = 1:size(datWord(n).uniSess,2)
        tmpNS = mean(datWord(n).inten{k,posNS},'omitnan');
        tmpS = mean(datWord(n).inten{k,posS},'omitnan');
        checkNS = [checkNS; tmpNS];
        checkS = [checkS; tmpS];
        [~,idxBoot] = ismember([posNS posS],cell2mat([datWord(n).sigVal{1,k}(:,1)]),'rows');
        if abs(datWord(n).sigVal{1,k}{idxBoot,2})>=1
            scatter(tmpNS,tmpS,sz,colMatScat(n,:),'filled')
            cntS = cntS + 1;
        else
            scatter(tmpNS,tmpS,sz,colMatScat(n,:))
            cntNS = cntNS + 1;
        end
        check = [check; datWord(n).sigVal{1,k}{idxBoot,2}];
        checkWord = [checkWord; datWord(n).word];
    end
end
xlabel('No Stim Intensity (dB)'),ylabel('Stim Intensity (dB)')
gx = gca;
axVal = [gx.YLim, gx.XLim];
line([min(axVal) max(axVal)],[min(axVal) max(axVal)],'Color','k','LineStyle','--')
line([min(axVal) max(axVal)],[min(axVal) max(axVal)]+5,'Color','k','LineStyle',':')
line([min(axVal) max(axVal)],[min(axVal) max(axVal)]-5,'Color','k','LineStyle',':')
axis([min(axVal) max(axVal) min(axVal) max(axVal)])
colormap(colMatScat)
h = colorbar;
h.Label.String = 'Tested Words';
h.Ticks = linspace(0,1,length(uniWord));
%h.Ticks = linspace(0,1,51);
h.TickLabels = [datWord.word];
h.Direction = 'reverse';
%h.TickLabels = [datWord(linspace(1,51,11)).word];
title('Intensity Scatter Plot')
F2.Name = [subject '_IntensityScatterPlot_gray'];

figure;
histogram(checkS-checkNS,'BinWidth',5)
xlabel('Difference Intensity (Stim - No Stim)')
ylabel('Word count (all sessions)')
%% Create a scatter plot of the intensity for each word, colored by clinical
% improvement

colMatCD = [251, 166, 19;...% yellow
    243, 207, 149;...%yellow
    126, 183, 237;...%light blue
    34, 45, 171]./255;%blue
clinicalDiff = checkS-checkNS;

% Sort the data into clinically worse, non-clinical decrease, clinical
% improvement, and clinically relavent improvement.
[clinicThres,edge] = discretize(clinicalDiff,[-inf,-5,0,5,inf]);


% Plot the data
F3 = figure('Position',[650 50 1200 850]); hold on
for n = 1:max(clinicThres)
    cntTot(n) = sum(clinicThres == n);
    for k = 1:2 % Test the significance
        if k == 1
            mask = (clinicThres == n) & abs(check) >=1;
            scatter(checkNS(mask),checkS(mask),sz,colMatCD(n,:),'filled');
            cntSig(k,n) = sum(mask);
        else
            mask = (clinicThres == n) & abs(check) ==0;
            scatter(checkNS(mask),checkS(mask),sz,colMatCD(n,:));
            cntSig(k,n) = sum(mask);
        end
    end
end

xlabel('No Stim Intensity (dB)'),ylabel('Stim Intensity (dB)')
gx = gca;
axVal = [gx.YLim, gx.XLim];
line([min(axVal) max(axVal)],[min(axVal) max(axVal)],'Color','k','LineStyle','--')
line([min(axVal) max(axVal)],[min(axVal) max(axVal)]+5,'Color','k','LineStyle',':')
line([min(axVal) max(axVal)],[min(axVal) max(axVal)]-5,'Color','k','LineStyle',':')
axis([min(axVal) max(axVal) min(axVal) max(axVal)])
axis square
colormap(colMatCD)
h = colorbar;
h.Label.String = 'Clinical Change';
tmp = linspace(0,1,9);
h.Ticks = tmp(2:2:end);
h.TickLabels = {sprintf('>5dB decrease, n_{tot}=%0.0f, n_{sig}=%0.0f',cntTot(1),cntSig(1,1)),...
    sprintf('<5dB decrease n_{tot}=%0.0f, n_{sig}=%0.0f',cntTot(2),cntSig(1,2)),...
    sprintf('<5dB increase=%0.0f n_{tot}=%0.0f, n_{sig}=%0.0f',cntTot(3),cntSig(1,3)),...
    sprintf('>5dB increase, n_{tot}=%0.0f, n_{sig}=%0.0f',cntTot(4),cntSig(1,4))};
title('Intensity Scatter Plot')
F3.Name = [subject '_IntensityScatterPlot_clinicalRelevance'];

% g =[sum(clinicalDiff<=-5)...
% sum(clinicalDiff<=0 & clinicalDiff>-5)...
% sum(clinicalDiff>0 & clinicalDiff<5)...
% sum(clinicalDiff>=5 & clinicalDiff<10)...
% sum(clinicalDiff>=10)]

%% Save the figures
if savePlots
    saveFigurePDF([F2; F3],saveFigPath)
end