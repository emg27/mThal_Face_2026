clear
close all

%% Load the data
sessions = {'20220824' '20220825' '20220826' '20220911' '20220914' '20220919' '20220923' '20230630'};
%sessions = {'20230630' '20241204'};

%load('P:\projects\human\VOP STIM\DATA\Chronic_DBS\BP\Speech Assessment\Phoneme\phoneme_presenceCheck.mat')
%load('/Volumes/rnelshare/projects/human/VOP STIM/DATA/Chronic_DBS/BP/Speech Assessment/Phoneme/phoneme_presenceCheck_2024.mat')

load("/Users/zira/Data/mThal_NatComm_2026/phoneme_presenceCheck_TBI01_sessions.mat")
%load("/Users/zira/Data/mThal_NatComm_2026/phoneme_presenceCheck_complete.mat")
sessions = unique({phonDat.dataset});
%% Collect all the phoneme data
inclStress = 0;
iPA = 1;

% % Determine total number of phonemes
allUniPhons = [];
for s = 1:length(sessions)
    phones = [];
    for n = 1:size(phonDat,2)
        if contains(phonDat(n).dataset, sessions(s))
            phones = [phones; phonDat(n).phoneme(:)];
        end
    end

    % Identify all the unique phonemes
    if ~inclStress
        for n = 1:size(phones,1)
            phones(n).phon_wStress = phones(n).phon;
            if contains(phones(n).phon,{'0','1','2','3'})
                phones(n).phon{:} = phones(n).phon{:}(1:end-1);
            end
        end
    end

    allUniPhons(s) = numel(unique([phones.phon]));
end

LabelAll =repmat({''},max(allUniPhons),numel(sessions));
% By Sessions
for s = 1:length(sessions)
    phones = [];
    for n = 1:size(phonDat,2)
        if contains(phonDat(n).dataset, sessions(s))
            phones = [phones; phonDat(n).phoneme(:)];
        end
    end

    % Identify all the unique phonemes
    if ~inclStress
        for n = 1:size(phones,1)
            phones(n).phon_wStress = phones(n).phon;
            if contains(phones(n).phon,{'0','1','2','3'})
                phones(n).phon{:} = phones(n).phon{:}(1:end-1);
            end
        end
    end
    [uniPhon,~,idxPhon] = unique([phones.phon]);
    
    %convert to iPA
    if iPA
        for i = 1:length(uniPhon)
            Label{i} = arpa2ipa(uniPhon{i});
            LabelAll{i,s} = uniPhon{i};
        end
    end

    % Double check that none of the valids are characters
    for i = 1:numel(phones)
        if ischar(phones(i).valid)
            phones(i).valid = str2num(phones(i).valid);
        end
    end

    % Plot the frequency of each of the words
    figure
    histogram(idxPhon,'BinWidth',1)
    xlabel('Phonemes'),ylabel('Trial Count')
    gx = gca;
    set(gx,'XTick',1:size(Label,2),'XTickLabel',Label)
    title(sprintf('%s Phoneme Frequency', sessions{s}))

    uniCond = {'No Stim','55Hz','130Hz'};
    [~,idxCond] = ismember({phones.cond},uniCond);
   

    % Iterate through each word and condition
    %close all
    diffCond = {'No Stim','55Hz'};%{'55Hz' '130Hz'};
    figure('Position',[1 49 1920 1075])
    [xNum,yNum] = optSubplotLayout(size(Label,2));
    for n = 1:size(Label,2)

        % Iterate through each conditon
        bin = nan(3);
        for k = 1:3
            mask = idxPhon' == n & idxCond == k;
            bin(k,:) = histcounts([phones(mask==1).valid],[0 1 2 10])/sum(mask);
            hold on
            %histogram([phones(mask==1).valid],'BinWidth',1)
        end
        % Reorder the bin data to be Present, Replaced, Absent
        bin = bin(:,[2 3 1]);

        diff50 = bin(2,1) - bin(1,1); %Changes 55Hz vs. nostim
        diff130 = bin(3,1) - bin(1,1); %Changes 130Hz vs. nostim
        diff = [diff50 diff130];
        diffVal{n,s} = diff';
        %diffVal = diffVal';
        binVal{n,s} = bin'; % Flipped the order to make it easier to read the material

        subplot(xNum,yNum,n)
        bar(diff,'stacked')
        %bar(bin,'stacked')
        title(Label{n})
        gx = gca;
        set(gx,'XTickLabel',diffCond)
        % legend('Abstent','Present','Replaced')
    end
    legend('Present','Replaced','Absent','Location','bestoutside')
    title(sprintf('%s Phoneme Present', sessions{s}))
    linkaxes
end

%% Identify the position of the consonant phoneme based on location in the mouth
tPhon = {'P','B','M','W','F','V','TH','DH','T','D','S','Z','N','L','R','CH','SH','ZH','Y','K','G','NG','HH'};

% Iterate through each trace

for n = 1:numel(tPhon)
    mask = ismember(LabelAll,tPhon(n));
    b = diffVal(mask==1);
    b2=[b{:}];
    diffPres{n} = b2(1,:);
    c = binVal(mask==1);
    c2 = [c{:}];
    binPres{n} = c;
end

diffPres = [tPhon; diffPres];

% %% Save Figure
% 
% figFolder = 'P:\projects\human\VOP STIM\DATA\Chronic_DBS\BP\Speech Assessment\Phoneme\Figures\';
% freqIdx = [1 3 5 7 9 11 13 15];
% hisIdx = [2 4 6 8 10 12 14 16];
% 
% for s = 1:length(sessions)
%     F(s) = figure(freqIdx(s));
%     F(s).Name = sprintf('%s_freq', sessions{s});
%     G(s) = figure(hisIdx(s));
%     G(s).Name = sprintf('%s_presence', sessions{s});
% end
% 
%  saveFigurePDF(G, [figFolder])
% % saveFigurePDF(F, [figFolder])
% % %saveas(G, [figFolder '\' sessions{s} '.fig'])

%% Functions
function [ipa] = arpa2ipa(phone)
% Match the arpa value to ipa #TODO make the flpip function ipa2arpa
switch phone
    case {'AA'}, ipa = 'ɑ';
    case {'AE'}, ipa = 'æ';
    case {'AH'}, ipa = 'ʌ';
    case {'AO'}, ipa = 'ɔ';
    case {'AW'}, ipa = 'aʊ';
    case {'AY'}, ipa = 'aɪ';
    case {'EH'}, ipa = 'ɛ';
    case {'ER'}, ipa = 'ɝ';
    case {'EY'}, ipa = 'eɪ';
    case {'IH'}, ipa = 'ɪ';
    case {'IY'}, ipa = 'i';
    case {'OW'}, ipa = 'oʊ';
    case {'OY'}, ipa = 'ɔɪ';
    case {'UH'}, ipa = 'ʊ';
    case {'UW'}, ipa = 'u';
    case {'B'}, ipa = 'b';
    case {'CH'}, ipa = 'tʃ';
    case {'D'}, ipa = 'd';
    case {'DH'}, ipa = 'ð';
    case {'F'}, ipa = 'f';
    case {'G'}, ipa = 'g';
    case {'HH'}, ipa = 'h';
    case {'JH'}, ipa = 'dʒ';
    case {'K'}, ipa = 'k';
    case {'L'}, ipa = 'l';
    case {'M'}, ipa = 'm';
    case {'N'}, ipa = 'n';
    case {'NG'}, ipa = 'ŋ';
    case {'P'}, ipa = 'p';
    case {'R'}, ipa = 'ɹ';
    case {'S'}, ipa = 's';
    case {'SH'}, ipa = 'ʃ';
    case {'T'}, ipa = 't';
    case {'TH'}, ipa = 'θ';
    case {'V'}, ipa = 'v';
    case {'W'}, ipa = 'w';
    case {'Y'}, ipa = 'j';
    case {'Z'}, ipa = 'z';
    case {'ZH'}, ipa = 'ʒ';
    otherwise
        ipa = '';
end
end