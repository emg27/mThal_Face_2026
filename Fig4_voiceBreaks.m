%% Fig4_voiceBreaks
% Collects voice break data across stimulation conditions and sessions into
% a single table, then plots the distribution of voice breaks per condition.
%
% Creates figure 4 (voice breaks panel) for the manuscript.
%
% Generates the following figures:
%   F       Histogram of voice breaks across all sessions, No Stim and 55 Hz (not saved)
%   F2      Per-session histogram of voice breaks across all conditions (not saved)
%
% Required Data:
%   Fig4_B_voiceReports.mat
%       fileInfoTable   Table of recording file metadata (Name, word, condition, etc.)
%       voiceReports    Table of automated voice break detections per file
%       NumSyllables    Struct with fields Word and NumberOfSyllables
%
% User Configuration:
%   dataPath        Path to the folder containing the .mat data file
%   saveFigPath     Path to the folder where figures will be saved
%   savePlots       Set to 1 to save figures as PDF, 0 to skip saving
%
% Created by Lilly Tang, Erinn Grigsby, and Arianna Damiani
% Copyright (C) 2026
% Email: erinn.grigsby@gmail.com

% Clear workspace and identify the data and figure saving locations.
% Edit the dataPath and saveFigPath as you need to.
clear, close all

curPath = pwd; addpath(genpath(curPath));
dataPath    = '/Users/zira/Data/mThal_NatComm_2026';
saveFigPath = '/Users/zira/analysisFigures/mThal_NatComm_2026_figs';
savePlots   = 0; % Set to 1 to save all figures as PDF

% Load the data and create the save folder if needed
load(fullfile(dataPath,'Fig4_B_voiceReports.mat'))

if ~exist(saveFigPath,'dir') && savePlots
    mkdir(saveFigPath);
end

% Color map matching the stimulation condition palette used across all figures
col = {'#FDB71A',... % No Stim
       '#24408B',... % 55 Hz
       '#445A8A',... % 80 Hz
       '#666E89'};   % 130 Hz
%% Build combined data table
allDatTable = fileInfoTable;

% Iterate through each index of data and find the relevant entry in
% voiceReports. If the data exists add it to the table; otherwise log it.
check = [];
for n = 1:size(allDatTable,1)
    tmpName = allDatTable.Name{n};

    % Separate the filename into date and word components
    idxRE   = regexp(tmpName,'_');
    tmpDate = str2double(tmpName(idxRE(1)+1:idxRE(2)-1));
    tmpWav  = [tmpName '.wav'];

    % Determine the number of syllables in the word
    idxWord = find(ismember({NumSyllables.Word{:}},fileInfoTable.word(n)));
    if ~isempty(idxWord)
        allDatTable.numSyllable(n) = NumSyllables.NumberOfSyllables(idxWord);
        allDatTable.block(n)       = tmpName(idxRE(end-1)+1:idxRE(end)-1);
    end

    % Find the matching entry in voiceReports by filename
    mask = find(ismember({voiceReports.fileName{:}},tmpWav)');

    % If multiple matches exist use only the first; log missing files
    if ~isempty(mask)
        tmpDat(n,:) = [allDatTable(n,:) voiceReports(mask(1),:)];
    else
        check = [check; {n,tmpDate,tmpWav}];
    end
end

% NOTE: tmpDat is the merged table with all metadata and voice report
% information needed for subsequent analyses.

%% Flag invalid trials: first trial of a block, or repeated block of a condition
tmpDat.valid(:) = 1; % Mask column — 0 = excluded, 1 = included.
                      % Rows are kept rather than deleted to preserve alignment.

% Remove first trials
mask = contains(tmpDat.Name,'trl1');
tmpDat.valid(mask) = 0;

% Remove second (repeated) blocks of the same stimulation condition per session
[uniDate,~,idxDate]       = unique([tmpDat.datasetString]);
[uniCondAll,~,idxCondAll] = unique([tmpDat.condition]);
pairDC                    = [idxDate idxCondAll];
[uniPairDC,~,idxPDC]     = unique(pairDC,'rows');

for n = 1:size(uniPairDC,1)
    tmpBlk = unique(tmpDat.block(idxPDC == n));
    if length(tmpBlk) > 1
        pos = find(idxPDC == n & ismember({tmpDat.block},tmpBlk(2:end)));
        tmpDat.valid(pos) = 0;
    end
end

%% Plot voice breaks by condition (No Stim and 55 Hz only — manuscript figure)
% 80 Hz and 130 Hz excluded from this summary plot; per-session breakdown
% in the next section includes all four conditions.

uniCond  = {'No Stim','55Hz','80Hz','130Hz'};
binWidth = 1;
binEdge  = -binWidth*0.5:binWidth:8;
plotDat  = 'voiceBreak';

figure, hold on
LEGEND = {};

% Session list used in the manuscript
sessions = {'20220824','20220825','20220826','20220911','20220914',...
        '20220919','20220923','20230630'};
maskSess = ismember([tmpDat.datasetString],sessions);

for n = 1:2  % Only No Stim (1) and 55 Hz (2) shown in the manuscript figure
    maskC = ismember([tmpDat.condition],uniCond(n)) & maskSess;
    maskS = ismember([tmpDat.numSyllable],1:3) & maskSess;
    tmp   = [tmpDat.(plotDat)];
    tmp   = tmp(maskC == 1 & maskS == 1 & tmpDat.valid == 1);
    histogram(tmp,'BinEdges',binEdge,'FaceColor',col{n},...
        'EdgeColor',col{n},'Normalization','probability');

    avgVal(n)  = mean(tmp,'omitnan');
    medVal(n)  = median(tmp,'omitnan');
    modeVal(n) = mode(tmp);
    numVal(n)  = size(tmp,1);
    xline(avgVal(n),'Color',col{n})

    LEGEND = [LEGEND, ...
        {['N_{' uniCond{n} '} = ' num2str(numVal(n))]}, ...
        {['mean_{' uniCond{n} '} = ' num2str(avgVal(n)) '  mode = ' num2str(modeVal(n))]}];
end
title([plotDat ': All Syllables (1, 2, and 3)'])
legend(LEGEND)
F = gcf;
F.Name = ['Subject001_' plotDat '_all_syllable'];

%% Plot voice breaks by condition and session
close all

[avgVal,medVal,modeVal,numVal] = deal(nan(size(uniDate,1),size(uniCond,2)));
for k = 1:size(uniDate,1)
    F2(k) = figure; hold on
    LEGEND = {};
    for n = 1:size(uniCond,2)
        maskC = ismember([tmpDat.condition],uniCond(n));
        maskS = ismember([tmpDat.numSyllable],1:3);
        tmp   = [tmpDat.(plotDat)];
        tmp   = tmp(maskC == 1 & maskS == 1 & tmpDat.valid == 1 & idxDate == k);
        histogram(tmp,'BinEdges',binEdge,'FaceColor',col{n},...
        'EdgeColor',col{n},'Normalization','probability');

        avgVal(k,n)  = mean(tmp,'omitnan');
        medVal(k,n)  = median(tmp,'omitnan');
        modeVal(k,n) = mode(tmp);
        numVal(k,n)  = size(tmp,1);
        xline(avgVal(k,n),'Color',col{n})

        if ~isempty(tmp)
            LEGEND = [LEGEND, ...
                {['N_{' uniCond{n} '} = ' num2str(numVal(k,n))]}, ...
                {['mean_{' uniCond{n} '} = ' num2str(avgVal(k,n)) '  mode = ' num2str(modeVal(k,n))]}];
        end
    end
    title([plotDat ': All Syllables, ' uniDate{k}])
    F2(k).Name = ['Subject001_' uniDate{k} '_' plotDat '_all_syllable'];
    legend(LEGEND)
end

%% Save the figures
if savePlots
    saveFigurePDF([F; F2(:)], saveFigPath)
end
