% Collect all the voice break data into a single table and plot the data
%
% Created by Erinn Grigsby
% Copyright (C) by Erinn Grigsby
% Emails: erinn.grigsby@gmail.com
clear, close all, clc

%load('C:\Users\emg27\Dropbox\PostDoc\ElviraMarco\One-on-One\20241214\voiceReport_20241216.mat')
%load('D:\RNEL\analysis\voiceBreakAnalysis_all_info_v2.mat') % Load this matfile to run
load('/Users/zira/Library/CloudStorage/Dropbox/PostDoc/ElviraMarco/One-on-One/20241214/voiceReport_20241216.mat')

%% 
allDatTable = fileInfoTable;

% Iterate through each index of data and find the relevant data in the
% voice report. If the data exists then add it to the structure.
check = [];
for n = 1:size(allDatTable,1)
    % Define the wav file information
    tmpName = allDatTable.Name{n};

    % Separate the filename into date and word structure
    idxRE = regexp(tmpName,'_');
    tmpDate = str2num(tmpName(idxRE(1)+1:idxRE(2)-1));
    tmpWav = [tmpName '.wav'];
    %tmpWav = [tmpName(idxRE(2)+1:end) '.wav'];

    % Determine the number of syllables in the word
    idxWord = find(ismember({NumSyllables.Word{:}},fileInfoTable.word(n)));
    if ~isempty(idxWord)
        allDatTable.numSyllable(n) = NumSyllables.NumberOfSyllables(idxWord);
        allDatTable.block(n) = tmpName(idxRE(end-1)+1:idxRE(end)-1);
    end

    % Find the location of the file in the voide reports
    % mask = find(ismember([voiceReports.dataset],tmpDate) & ...
    %     ismember({voiceReports.fileName{:}},tmpWav)');
    mask = find(ismember({voiceReports.fileName{:}},tmpWav)');

    % Determine the number of datafiles that we might be missing
    if ~isempty(mask)
        tmpDat(n,:) = [allDatTable(n,:) voiceReports(mask,:)];
    else
        check = [check; {n,tmpDate,tmpWav}];
    end
end

% NOTE: tmpDat is the file that you want as it will have all information
% that you may need

%% Set an index as invalid if it is the first trial, or the second block
% of a stimulation condition
tmpDat.valid(:) = 1; % Create a column to mask the data. I didn't delete
% anything because I wanted to be certain that
% everything is aligned correctly.

% Remove first trials
mask = contains(tmpDat.Name,'trl1');
tmpDat.valid(mask) = 0;

% Determine if a stimulation condition has already been tested or not
[uniDate,~,idxDate] = unique([tmpDat.datasetString]);
[uniCondAll,~,idxCondAll] = unique([tmpDat.condition]);
pairDC = [idxDate idxCondAll];
[uniPairDC,~,idxPDC] = unique(pairDC,'rows');

% Iterate through each pairDC and remove the second blocks of data
for n = 1:size(uniPairDC,1)
    % See if there are multiple blocks of the condition
    tmpBlk = unique([tmpDat.block(idxPDC == n)]);

    if length(tmpBlk)>1
        pos = find(idxPDC == n & ismember([tmpDat.block],tmpBlk(2:end)));
        tmpDat.valid(pos) = 0;
    end
end

%% Plot the number of voice breaks by condition

uniCond = {'No Stim','55Hz','80Hz','130Hz'};
binWidth = 1;
binEdge = -binWidth*.5:binWidth:8;
plotDat = 'voiceBreak';
col = 'brgc';
figure, hold on
LEGEND = cell(0);

% Create a session mask for publication sessions
sessions = {'20220824','20220825','20220826','20220911','20220914',...
        '20220919','20220923','20230630'}; % Sessions used for publication
maskSess = ismember([tmpDat.datasetString],sessions);

for n = 1:2%size(uniCond,2)
    maskC = ismember([tmpDat.condition],uniCond(n)) & maskSess;
    maskS = ismember([tmpDat.numSyllable],1:3) & maskSess;
    tmp = [tmpDat.(plotDat)];
    tmp = tmp(maskC == 1 & maskS == 1 & tmpDat.valid == 1); % Truncate to the valid data
    histogram(tmp,'binEdge',binEdge,'EdgeColor','auto','Normalization','probability');

    avgVal(n) = mean(tmp,'omitnan');
    medVal(n) = median(tmp,'omitnan');
    modeVal(n) = mode(tmp);
    numVal(n) = size(tmp,1);
    xline(avgVal(n),'Color',col(n))

    LEGEND = [LEGEND,['N_{' uniCond{n} '} = ' num2str(numVal(n))],...
        ['mean_{' uniCond{n} '} = ' num2str(avgVal(n))  ' mode =' num2str(modeVal(n))]]
end
title([plotDat ': All Syllables (1, 2, and 3)'])
legend(LEGEND)
F = gcf;
F.Name = ['Subject001_' plotDat '_all_syllable']

%% Plot the number of voice breaks by condition by date
close all
uniCond = {'No Stim','55Hz','80Hz','130Hz'};
binWidth = 1; % Determines the binWidth for plotting
plotDat = 'voiceBreak'; % Sets what data we are comparing within the table.
col = 'brgc';
[avgVal,medVal,modeVal,numVal] = deal(nan(size(uniDate,1),size(uniCond,2)));
for k = 1:size(uniDate,1)
    F2(k) = figure; hold on
    LEGEND = [];
    for n = 1:size(uniCond,2)
        maskC = ismember([tmpDat.condition],uniCond(n));
        maskS = ismember([tmpDat.numSyllable],1:3);
        tmp = [tmpDat.(plotDat)];
        tmp = tmp(maskC == 1 & maskS == 1 & tmpDat.valid == 1 & idxDate == k); % Truncate to the valid data
        histogram(tmp,'binEdge',binEdge,'EdgeColor','auto','Normalization','probability');

        avgVal(k,n) = mean(tmp,'omitnan');
        medVal(k,n) = median(tmp,'omitnan');
        modeVal(k,n) = mode(tmp);
        numVal(k,n) = size(tmp,1);
        xline(avgVal(k,n),'Color',col(n))
        if ~isempty(tmp)
            if n == 1
                LEGEND = [LEGEND {['N_{No Stim} = ' num2str(numVal(k,1))],...
                    ['mean_{No Stim} = ' num2str(avgVal(k,1)) ' mode =' num2str(modeVal(k,1))]}];
            elseif n ==2
                LEGEND = [LEGEND {['N_{55Hz} = ' num2str(numVal(k,2))],...
                    ['mean_{55Hz} = ' num2str(avgVal(k,2)) ' mode =' num2str(modeVal(k,2))]}];
            elseif n == 3
                LEGEND = [LEGEND {['N_{80Hz} = ' num2str(numVal(k,3))],...
                    ['mean_{80Hz} = ' num2str(avgVal(k,3)) ' mode =' num2str(modeVal(k,3))]}];
            elseif n == 4
                LEGEND = [LEGEND {['N_{130Hz} = ' num2str(numVal(k,4))],...
                    ['mean_{130Hz} = ' num2str(avgVal(k,4)) ' mode =' num2str(modeVal(k,4))]}];
            end
        end
    end
    title([plotDat ': All Syllables, ' uniDate{k}])
    F2(k).Name = ['Subject001_' uniDate{k} '_' plotDat '_all_syllable'];
    legend(LEGEND)

end
%matchAxis(F2([8 11]))