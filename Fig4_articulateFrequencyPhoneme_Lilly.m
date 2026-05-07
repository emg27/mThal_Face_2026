%% Load the data
sessions = {'20220824' '20220825' '20220826' '20220911' '20220914' '20220919' '20220923' '20230630' '20241204'};

%load('P:\projects\human\VOP STIM\DATA\Chronic_DBS\BP\Speech Assessment\Phoneme\phoneme_presenceCheck.mat')
%load('C:\Users\emg27\Dropbox\PostDoc\ElviraMarco\One-on-One\20240206\phoneme_presenceCheck.mat')
load('/Volumes/rnelshare/projects/human/VOP STIM/DATA/Chronic_DBS/BP/Speech Assessment/Phoneme/phoneme_presenceCheck.mat')

%% Collect all the phoneme data
inclStress = 0;
phones = [];
for n = 1:size(phonDat,2)
    % for s = 1:length(sessions)
    %     if contains(phonDat(n).dataset, sessions(s))
            phones = [phones; phonDat(n).phoneme(:)];
        % end
    % end
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

%% Identify the position of the consonant phoneme based on location in the mouth
tPhon = {'P','B','M','W','F','V','TH','DH','T','D','S','Z','N','L','R','CH','SH','ZH','Y','K','G','NG','HH'};
for n = 1:size(tPhon,2)
    pos(n) = find(ismember(uniPhon,tPhon(n)));
end

% Plot the frequency of each of the words
figure
histogram(idxPhon,'BinWidth',1)
xlabel('Phonemes'),ylabel('Trial Count')
gx = gca;
set(gx,'XTick',1:size(uniPhon,2),'XTickLabel',uniPhon)

uniCond = {'No Stim','55Hz','130Hz'};
[~,idxCond] = ismember({phones.cond},uniCond);

% Heatmap of phoneme count ordered by position in the mouth
[bins,edges] = histcounts(idxPhon,[1:size(uniPhon,2) size(uniPhon,2)]); %,'Normalization','probability');%'BinWidth',1);
figure
imagesc(bins(pos))
colormap default
colorbar
gx = gca;
set(gx,'XTick',1:size(tPhon,2),'XTickLabel',uniPhon(pos))

%% Iterate through each word and condition
close all
consonantDat = {};
diffCond = {'55Hz','130Hz'};

figure('Position',[1 49 1920 1075])
[xNum,yNum] = optSubplotLayout(size(uniPhon,2));
for n = 1:size(uniPhon,2)
    
    % Iterate through each conditon
    bin = nan(3);
    for k = 1:3
        mask = idxPhon' == n & idxCond == k;
        bin(k,:) = histcounts([phones(mask==1).valid],[0 1 2 10])/sum(mask);
       % hold on
        %histogram([phones(mask==1).valid],'BinWidth',1)
    end
    % Reorder the bin data to be Present, Replaced, Absent
    bin = bin(:,[2 3 1]);
    consonantDat{n} = bin(:,[1]);

    diff50 = bin(2,1) - bin(1,1); %Changes 55Hz vs. nostim
    diff130 = bin(3,1) - bin(1,1); %Changes 130Hz vs. nostim
    diff = [diff50 diff130];
    diffVal{n} = diff;
    diffVal = diffVal';

    subplot(xNum,yNum,n)
    %bar(bin,'stacked')
    bar(diff)
    title(uniPhon{n})
    gx = gca;
    set(gx,'XTickLabel',diffCond)
   % legend('Abstent','Present','Replaced')
end
legend('Present','Replaced','Absent','Location','bestoutside')