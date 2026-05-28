%% fig4C_formantChangePlots_EMG
% Visualizes DBS-driven changes in vowel formant space (F1 vs. F2) for
% individual subjects across stimulation conditions.
%
% Creates figure 4C for the manuscript. Formant values are NOT calculated
% here — they are loaded from a pre-computed .mat file. Phoneme symbols
% are plotted at the stimulation-OFF location; arrows indicate significant
% shifts toward the stimulation-ON location.
%
% Generates the following figures:
%   Figure 1   All significant F1 and F2 changes overlaid in a single plot
%   Figure 2   Significant changes split into four subplots:
%              F1 increases, F2 increases, F1 decreases, F2 decreases
%
% Required Data:
%   Fig4_C_formantData.mat
%       dat_vowelPhoneme    Struct array, one entry per phoneme utterance.
%                           Fields: subject, dataset, ipa, cond, word,
%                                   trl, formant (2 × nFrames matrix,
%                                   rows = [F1; F2])
%
% User Configuration:
%   dataPath    Path to the folder containing the .mat data file
%   savePlots   Set to 1 to save figures as PDF, 0 to skip saving
%   savePATH    Path to the folder where figures will be saved
%   onCond      Label of the stimulation-ON condition (e.g. '55Hz')
%   offCond     Label of the stimulation-OFF condition (e.g. 'No Stim')
%   sub         Subject struct to analyze (sub1 or sub4)
%   semitone    Axis scale: 1 = semitone scale, 0 = log Hz scale
%   processDat  1 = apply median filter + spline time-warp to formants
%   idxSubset   Time index range to retain after warping (e.g. 15:85)
%
% Created by Isabella Montanaro
% Updated by Erinn Grigsby, 2026
% Correspondence: ism83@pitt.edu
% Copyright (C) 2026

clear, close all

%% User configuration
curPath = pwd; addpath(genpath(curPath));
dataPath  = '/Users/zira/Data/mThal_NatComm_2026';
savePATH  = '/Users/zira/analysisFigures/mThal_NatComm_2026_figs';
savePlots = 0; % Set to 1 to save figures as PDF

% Optional inputs
onCond  = '55Hz';    % Label for stimulation-ON condition
offCond = 'No Stim'; % Label for stimulation-OFF condition
semitone   = 1;      % 1 = semitone scale, 0 = log Hz scale
processDat = 1;      % 1 = apply median filter + spline time-warp
idxSubset  = 15:85;  % Retain this time window after warping to 1:100
arrowOffset = 7;     % Offset (Hz or semitones) between arrows for the same vowel
ref = 110;           % Reference frequency (Hz) for semitone conversion: semitones = 12*log2(f/ref)

% Colors for plotting
navy = '#0072BD';
gold = '#EDB120';

%% Load data
load(fullfile(dataPath, 'Fig4_C_formantData.mat'))

%% Split data by subject
sub1ii = find(contains({dat_vowelPhoneme.subject}, {'Subject001'}));

sub1 = dat_vowelPhoneme(sub1ii);

%%%%%%%%%% CHOOSE SUBJECT HERE %%%%%%%%%%
sub    = sub1;
subStr = 'Subject 1';

% Note: only one subject can be analyzed at a time. Restart (clear) when
% switching subjects.

%% Organize data features
days   = unique({sub.dataset});
sounds = unique([sub.ipa]);

% diphthongs: binary flag per sound — 1 if the IPA symbol has >1 character
diphthongs = zeros(1, length(sounds));
for vs = 1:length(sounds)
    if length(sounds{vs}) > 1
        diphthongs(vs) = 1;
    end
end

%% Limit to first 5 trials per unique (condition, session, word, vowel) combination
% Caps trial count to balance across conditions and remove late-session fatigue.
words = cell(length(sub), 1);
for ph = 1:length(sub)
    idx      = regexp(sub(ph).word, '_');
    words{ph} = sub(ph).word(1:idx-1);
end
[uniWord, ~, idxWord] = unique(words);

[uniSess, ~, idxSess] = unique({sub.dataset});
[uniCond, ~, idxCond] = unique({sub.cond});
[uniIPA, ~, idxIPA]  = unique([sub.ipa]);

datCSWI = [idxCond idxSess idxWord idxIPA];
[uniCSWI, ~, idxCSWI] = unique(datCSWI, 'rows');

% Identify the valid conditions
validMask = zeros(size(sub));
for n = 1:size(uniCSWI,1)
    trl = find(idxCSWI==n);
    if size(trl,1)>5
        trl = trl(1:5);
    end
    validMask(trl) = 1;
end

% Simplify the data
sub = sub(validMask==1);

%% Build formant cell arrays indexed by (vowel, feature, day)
% Columns: 1=phoneme name, 2=F1 values, 3=F2 values, 4=diphthong flag
numVS       = length(sounds);
formantsOFF = cell(numVS, 4, length(days));
for vs = 1:numVS
    for day = 1:length(days)
        formantsOFF{vs,1,day} = sounds(vs);
        formantsOFF{vs,2,day} = [];
        formantsOFF{vs,3,day} = [];
        formantsOFF{vs,4,day} = diphthongs(vs);
    end
end
formantsON = formantsOFF;

% Populate formant arrays from the trial-level struct.
% Per-trial processing: median filter for smoothing, then spline time-warp
% to a common 1:100 grid, then subset to idxSubset.
% The mean across the retained time window gives one scalar F1 and F2 per trial.
for ph = 1:length(sub)
    day   = convertCharsToStrings(sub(ph).dataset);
    dayii = find(days == day);
    vs    = convertCharsToStrings(sub(ph).ipa);
    cond  = convertCharsToStrings(sub(ph).cond);

    for testVS = 1:numVS
        if vs == formantsOFF{testVS,1,dayii}
            if sum(~isnan(sub(ph).formant(:,1))) > 0
                f1 = sub(ph).formant(1,:);
                f2 = sub(ph).formant(2,:);

                if processDat
                    sz = size(sub(ph).formant, 2);
                    f1 = spline(linspace(1,100,sz), f1, 1:100);
                    f1 = medfilt1(f1);
                    f2 = spline(linspace(1,100,sz), f2, 1:100);
                    f2 = medfilt1(f2);

                    if ~isempty(idxSubset)
                        f1 = f1(idxSubset);
                        f2 = f2(idxSubset);
                    end
                end

                %%%%%%%%%% CHOOSE IGNORED TRIALS HERE %%%%%%%%%%
                % To ignore a specific trial number, add it to the elseif.
                % To include all trials, comment out the elseif.
                if cond == offCond
                    if isempty(sub(ph).formant)
                        % no data for this phoneme on this day/condition
                    elseif sub(ph).trl == 1
                        % trial 1 excluded (practice trial)
                    else
                        % Mean across the retained time window = one value per trial
                        formantsOFF{testVS,2,dayii} = [formantsOFF{testVS,2,dayii} mean(f1)];
                        formantsOFF{testVS,3,dayii} = [formantsOFF{testVS,3,dayii} mean(f2)];
                    end

                elseif cond == onCond
                    if isempty(sub(ph).formant)
                        % no data for this phoneme on this day/condition
                    elseif sub(ph).trl == 1
                        % match exclusion above
                    else
                        formantsON{testVS,2,dayii} = [formantsON{testVS,2,dayii} mean(f1)];
                        formantsON{testVS,3,dayii} = [formantsON{testVS,3,dayii} mean(f2)];
                    end
                end
            end
        end
    end
end

%% Compute daily and cross-day averages
% Two-level averaging: first within each day (mean across trials),
% then across days (mean of daily means, weighting each day equally).
for dayii = 1:length(days)
    for vs = 1:numVS
        avgF1OFF_daily(vs,dayii) = mean(formantsOFF{vs,2,dayii}, 'omitnan');
        avgF2OFF_daily(vs,dayii) = mean(formantsOFF{vs,3,dayii}, 'omitnan');
        avgF1ON_daily(vs,dayii)  = mean(formantsON{vs,2,dayii},  'omitnan');
        avgF2ON_daily(vs,dayii)  = mean(formantsON{vs,3,dayii},  'omitnan');
    end
end

for vs = 1:numVS
    avgF1OFF(vs) = mean(avgF1OFF_daily(vs,:), 'omitnan');
    avgF2OFF(vs) = mean(avgF2OFF_daily(vs,:), 'omitnan');
    avgF1ON(vs)  = mean(avgF1ON_daily(vs,:),  'omitnan');
    avgF2ON(vs)  = mean(avgF2ON_daily(vs,:),  'omitnan');
end

%% Significance testing: bootstrap comparison of OFF vs. ON per vowel per day
% sig_F1/sig_F2: 0 = not significant, 1 = significant at p=0.05
[sig_F1, sig_F2]= deal(zeros(numVS, length(days)));
[pchF1, pchF2]= deal(nan(numVS, length(days)));


for dayii = 1:length(days)
    for vs = 1:numVS
        pchF1(vs,dayii) = 100*(avgF1ON_daily(vs,dayii) - avgF1OFF_daily(vs,dayii)) / avgF1OFF_daily(vs,dayii);
        pchF2(vs,dayii) = 100*(avgF2ON_daily(vs,dayii) - avgF2OFF_daily(vs,dayii)) / avgF2OFF_daily(vs,dayii);

        % Only test if OFF data exists for this vowel/day
        if ~isempty(formantsOFF{vs,2,dayii}) && ~isempty(formantsON{vs,2,dayii})
            [~, rejectNull] = bootstrapCompMeans(formantsOFF{vs,2,dayii}, formantsON{vs,2,dayii}, 10000, 0.05, 1);
            if rejectNull, sig_F1(vs,dayii) = 1; end

            [~, rejectNull] = bootstrapCompMeans(formantsOFF{vs,3,dayii}, formantsON{vs,3,dayii}, 10000, 0.05, 1);
            if rejectNull, sig_F2(vs,dayii) = 1; end
        end
    end
end

%% Plotting setup
colorsblack  = zeros(numVS, 3);
phonemeLabels = formantsOFF(:,1,1); % IPA labels for each vowel (one per sound)

%% Figure 1: All significant F1 and F2 changes overlaid
% Arrows are drawn independently for F1 and F2 — a vowel with a significant
% change in both formants gets two perpendicular arrows, not one diagonal.
% f1s/f2s count prior arrows per vowel to offset overlapping arrows.

F1 = figure;

f1s = zeros(numVS, 2); % col 1 = up (F1 increase), col 2 = down (F1 decrease)
f2s = zeros(numVS, 2); % col 1 = right (F2 increase), col 2 = left (F2 decrease)

for dayii = 1:length(days)
    for vs = 1:length(phonemeLabels)
        avgx = avgF2OFF(vs);
        avgy = avgF1OFF(vs);

        if sig_F1(vs,dayii) == 1
            if pchF1(vs,dayii) > 0     % percent change > 0: F1 increases
                f1s(vs,1) = f1s(vs,1) + 1;
                offset = arrowOffset*(f1s(vs,1)-1);
            else                       % percent change < 0: F1 decreases
                f1s(vs,2) = f1s(vs,2) + 1;
                offset = arrowOffset*(f1s(vs,2)-1);
            end
            % Arrow drawn only in F1 (vertical) direction; x is fixed with offset
            x = [avgx + offset, avgx + offset+avgF2ON_daily(vs,dayii) - avgF2OFF_daily(vs,dayii)];
            y = [avgy, avgy + avgF1ON_daily(vs,dayii) - avgF1OFF_daily(vs,dayii)];
            if semitone
                x = 12*(log(x/ref))/(log(2));
                y = 12*(log(y/ref))/(log(2));
            end
            drawArrow = @(x,y) quiver(x(1),y(1), 0, y(2)-y(1), ...
                'AutoScale','on','AutoScaleFactor',1,'color',navy,'LineWidth',3);
            drawArrow(x,y); hold on;
        end

        if sig_F2(vs,dayii) == 1
            if pchF2(vs,dayii) > 0 % percent change > 0: F2 increases
                f2s(vs,1) = f2s(vs,1) + 1;
                offset = arrowOffset*(f2s(vs,1) - 1);
            else                   % percent change < 0: F2 decreases
                f2s(vs,2) = f2s(vs,2) + 1;
                offset = arrowOffset*(f2s(vs,2) - 1);
            end
            % Arrow drawn only in F2 (horizontal) direction; y is fixed with offset
            x = [avgx, avgx + avgF2ON_daily(vs,dayii) - avgF2OFF_daily(vs,dayii)];
            y = [avgy + offset, avgy + offset + avgF1ON_daily(vs,dayii) - avgF1OFF_daily(vs,dayii)];
            if semitone
                x = 12*(log(x/ref))/(log(2));
                y = 12*(log(y/ref))/(log(2));
            end
            drawArrow = @(x,y) quiver(x(1),y(1), x(2)-x(1), 0, ...
                'AutoScale','on','AutoScaleFactor',1,'color',gold,'LineWidth',3);
            drawArrow(x,y); hold on;
        end
    end
end

% Plot average OFF location as filled circles, labeled with IPA symbols
circleplotX = avgF2OFF;
circleplotY = avgF1OFF;
circleplotX(isnan(circleplotX)) = [];
circleplotY(isnan(circleplotY)) = [];

if semitone
    scatter(12*log(circleplotX/ref)/log(2), 12*log(circleplotY/ref)/log(2), ...
        250, 'filled', 'MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8);
    textscatter(12*log(avgF2OFF/ref)/log(2), 12*log(avgF1OFF/ref)/log(2), ...
        phonemeLabels, 'ColorData',colorsblack, 'FontSize',15, 'TextDensityPercentage',100);
    set(gca,'XDir','reverse','YDir','reverse');
    xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back','Semitone Scale'}, 'FontWeight','bold');
    ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close','Semitone Scale'}, 'FontWeight','bold');
else
    scatter(circleplotX, circleplotY, 250, 'filled', ...
        'MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8);
    textscatter(avgF2OFF, avgF1OFF, phonemeLabels, ...
        'ColorData',colorsblack, 'FontSize',15, 'TextDensityPercentage',100);
    set(gca,'XDir','reverse','XTick',[],'XScale','log');
    xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back','log Scale'}, 'FontWeight','bold');
    xlim([850 2050]);
    set(gca,'YDir','reverse','YTick',[],'YScale','log');
    ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close','log Scale'}, 'FontWeight','bold');
    ylim([300 800]);
end
title([subStr ': Formant Trajectories, OFF to ' onCond]);
hold off;

%% Figure 2: Significant changes split into four subplots
% Subplots: 1=F1 increases, 2=F2 increases, 3=F1 decreases, 4=F2 decreases

F2 = figure;

f1s = zeros(numVS, 2);
f2s = zeros(numVS, 2);

for dayii = 1:length(days)
    for vs = 1:length(phonemeLabels)
        avgx = avgF2OFF(vs);
        avgy = avgF1OFF(vs);

        if sig_F1(vs,dayii) == 1
            if pchF1(vs,dayii) > 0  % F1 increases → subplot 1
                f1s(vs,1) = f1s(vs,1) + 1;
                offset = arrowOffset*(f1s(vs,1)-1);
                sp = 1;
            else                     % F1 decreases → subplot 3
                f1s(vs,2) = f1s(vs,2) + 1;
                offset = arrowOffset*(f1s(vs,2)-1);
                sp = 3;
            end
            x = [avgx+offset avgx+offset];
            y = [avgy avgy + avgF1ON_daily(vs,dayii) - avgF1OFF_daily(vs,dayii)];
            if semitone
                x = 12*(log(x/ref))/(log(2));
                y = 12*(log(y/ref))/(log(2));
            end
            drawArrow = @(x,y) quiver(x(1),y(1), 0, y(2)-y(1), ...
                'AutoScale','on','AutoScaleFactor',1,'color',navy,'LineWidth',3);
            subplot(2,2,sp); drawArrow(x,y); hold on;
        end

        if sig_F2(vs,dayii) == 1
            if pchF2(vs,dayii) > 0  % F2 increases → subplot 2
                f2s(vs,1) = f2s(vs,1) + 1;
                offset = arrowOffset*(f2s(vs,1)-1);
                sp = 2;
            else                     % F2 decreases → subplot 4
                f2s(vs,2) = f2s(vs,2) + 1;
                offset = arrowOffset*(f2s(vs,2)-1);
                sp = 4;
            end
            x = [avgx avgx + avgF2ON_daily(vs,dayii) - avgF2OFF_daily(vs,dayii)];
            y = [avgy+offset avgy+offset];
            if semitone
                x = 12*(log(x/ref))/(log(2));
                y = 12*(log(y/ref))/(log(2));
            end
            drawArrow = @(x,y) quiver(x(1),y(1), x(2)-x(1), 0, ...
                'AutoScale','on','AutoScaleFactor',1,'color',gold,'LineWidth',3);
            subplot(2,2,sp); drawArrow(x,y); hold on;
        end
    end
end

% Add OFF-location scatter and IPA labels to all four subplots
circleplotX = avgF2OFF;
circleplotY = avgF1OFF;
circleplotX(isnan(circleplotX)) = [];
circleplotY(isnan(circleplotX)) = [];

titles = {[subStr ': F1 Increases, OFF to ' onCond], ...
          [subStr ': F2 Increases, OFF to ' onCond], ...
          [subStr ': F1 Decreases, OFF to ' onCond], ...
          [subStr ': F2 Decreases, OFF to ' onCond]};

for sp = 1:4
    subplot(2,2,sp);
    if semitone
        scatter(12*log(circleplotX/ref)/log(2), 12*log(circleplotY/ref)/log(2), ...
            250, 'filled', 'MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8);
        textscatter(12*log(avgF2OFF/ref)/log(2), 12*log(avgF1OFF/ref)/log(2), ...
            phonemeLabels, 'ColorData',colorsblack, 'FontSize',15, 'TextDensityPercentage',100);
        set(gca,'XDir','reverse','YDir','reverse');
        unitLabel = 'Semitone Scale';
    else
        scatter(circleplotX, circleplotY, 250, 'filled', ...
            'MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8);
        textscatter(avgF2OFF, avgF1OFF, phonemeLabels, ...
            'ColorData',colorsblack, 'FontSize',15, 'TextDensityPercentage',100);
        set(gca,'XDir','reverse','XTick',[],'XScale','log','YDir','reverse','YTick',[],'YScale','log');
        unitLabel = 'log Scale';
        axis([850 2050 300 800]);
    end
    hold on;
    
    xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back',unitLabel}, 'FontWeight','bold');
    ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close',unitLabel}, 'FontWeight','bold');
    title(titles{sp});
end
hold off;

%% Save figures
if savePlots
    if ~exist(savePATH,'dir'), mkdir(savePATH); end
    saveFigurePDF([F1; F2], savePATH)
end
