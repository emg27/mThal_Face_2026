%% Fig2_B_C_TMS_MEP
% TMS motor evoked potential (MEP) analysis comparing no-stimulation and
% DBS conditions across facial and hand muscles.
%
% Creates figures 2B and 2C for the manuscript.
%
% Generates the following figures:
%   F   Per-muscle QC traces: raw vs. low-pass filtered, one figure per condition (not saved)
%   T   All traces overlaid per condition, raw and filtered (not saved)
%   G   Peak-to-peak and AUC boxplots across conditions
%   V   Percentage increase in AUC from no-stim baseline (saved)
%
% Required Data:
%   Fig2_B_Nostim.mat   TMS recording during no-stimulation condition
%   Fig2_B_55Hz.mat     TMS recording during 55 Hz DBS condition
%       Each file contains per-muscle snip arrays and a snipTime vector.
%       MEP data is stored as: Data.(muscleName) — cell array of {avg, snips}
%
% User Configuration:
%   pathName    Path to the folder containing the .mat data files
%   savePATH    Path to the folder where figures will be saved
%   Trial2Load  Which body part to analyze: 'Face' or 'Hand'
%   savePlots   Set to 1 to save figures as PDF, 0 to skip saving
%
% Created by Lilly Tang, Erinn Grigsby, and Arianna Damiani
% Copyright (C) 2026

clear, close all

% Data path information
curPath = pwd; addpath(genpath(curPath));
pathName   = '/Users/zira/Data/mThal_NatComm_2026';
savePATH   = '/Users/zira/analysisFigures/mThal_NatComm_2026_figs';
savePlots  = 0; % Set to 1 to save figures as PDF

% General variables for the function
muscles = {'L_APB' 'L_MASS' 'L_ORIS' 'R_APB' 'R_MASS' 'R_ORIS'};
stim    = {'noStim' '55Hz Tremor'};
Fs = 2500; % Sampling rate (Hz)

% Trial2Load selects the body part and sets the MEP time window (in ms)
% and the .mat filenames to load.
Trial2Load = 'Face';

switch Trial2Load
    case 'Face'
        Trial      = {'Fig2_B_Nostim','Fig2_B_55Hz'};
        TimeWindow = [75 100]; % MEP window in ms post-TMS pulse
    case 'Hand' % Not used in the current manuscript but code is set up to easily switch to hand data if desired
        Trial      = {'5' '13'};
        TimeWindow = [100 140];
end

%% Load data
D = dir(fullfile(pathName,'*.mat'));

for s = 1:length(Trial)
    for d = 1:size(D,1)
        if contains(D(d).name, Trial{s})
            Data(s) = load(fullfile(D(d).folder, D(d).name));
        end
    end
end

% Extract MEP snip traces from the loaded data structs.
% Each muscle field contains {avg, snips} — index 2 gives the individual trial snips.
fieldN = fieldnames(Data);

for m = 1:length(muscles)
    idxM = find(contains(fieldN, muscles{m}));
    if ~isempty(idxM)
        for s = 1:length(Data)
            for i = 1:length(idxM)
                MEPsnips{i} = Data(s).(fieldN{idxM(i)});
            end
            MEPtraces{s,m} = MEPsnips{2}; % Individual trial snips (not the average)
            snipTime{s}    = Data(s).snipTime;
        end
    end
end

%% Low-pass filter and QC traces
% Creates one figure per (stim × muscle) for visual inspection. Not saved.
close all

count = 1;

% Compute filter coefficients once
[Bbp, Abp] = butter(4, 100/(Fs/2), 'low');

% Iterate through all the muscles and simtimulation parameters
for s = 1:size(MEPtraces,1)
    for m = 1:size(MEPtraces,2)
        

        F(count) = figure;
        F(count).Name = sprintf('%s %s Lowpass 100Hz', stim{s}, muscles{m});

        for ii = 1:size(MEPtraces{s,m},1)
            filtMEP{s,m}(ii,:) = filtfilt(Bbp, Abp, MEPtraces{s,m}(ii,:));

            ax(1) = subplot(2,1,1); hold on
            plot(snipTime{s}, MEPtraces{s,m}(ii,:))
            title('Raw')

            ax(2) = subplot(2,1,2); hold on
            plot(snipTime{s}, filtMEP{s,m}(ii,:))
            title('Low-pass (100 Hz)')
            xlabel('Time (ms)')

            % Overlay the trial mean in black on the last rep
            if ii == size(MEPtraces{s,m},1)
                subplot(2,1,1), hold on
                plot(snipTime{s}, mean(MEPtraces{s,m},1), 'LineWidth',2, 'Color','k')
                subplot(2,1,2), hold on
                plot(snipTime{s}, mean(filtMEP{s,m},1), 'LineWidth',2, 'Color','k')
            end
            sgtitle(sprintf('%s %s', muscles{m}, stim{s}), 'Interpreter','none')
        end
        linkaxes(ax, 'xy')
        xlim([60 200])
        count = count + 1;
    end
end

%% All traces overlaid per condition
% Layout: rows = muscles, columns = raw | filtered. Not saved.
close all

tracefilt = {'Raw' 'Filtered'};

for s = 1:size(MEPtraces,1)
    T(s) = figure; hold on
    T(s).Name = sprintf('MEP traces %s', stim{s});

    for f = 1:2
        if f == 1
            traces2Plot = MEPtraces;
        else
            traces2Plot = filtMEP;
        end

        for m = 1:size(traces2Plot,2)
            % figIdx maps (muscle, filter type) to subplot index in a
            % nMuscle × 2 grid (columns = raw/filtered)
            figIdx = (m-1)*2 + f;
            subplot(size(traces2Plot,2), size(traces2Plot,1), figIdx); hold on

            for ii = 1:size(traces2Plot{s,m},1)
                plot(snipTime{s}, traces2Plot{s,m}(ii,:))
            end
            plot(snipTime{s}, mean(traces2Plot{s,m}), 'LineWidth',2, 'Color','k')
            xlabel('Time (ms)')

            if f == 1
                ylabel(muscles{m}, 'Interpreter','none', 'FontWeight','bold')
            end
            if m == 1
                title(tracefilt{f})
            end
        end
    end
    sgtitle(stim{s})
end

%% No-stim vs. stim comparison traces
% Layout: rows = muscles, columns = stim conditions. Not saved.
close all

for f = 1:2
    T(f) = figure; hold on
    T(f).Name = sprintf('MEP traces %s', tracefilt{f});

    if f == 1
        traces2Plot = MEPtraces;
    else
        traces2Plot = filtMEP;
    end

    for s = 1:size(traces2Plot,1)
        for m = 1:size(traces2Plot,2)
            % figIdx maps (muscle, stim) to subplot index in a nMuscle × nStim grid
            figIdx    = (m-1)*2 + s;
            Tx(figIdx) = subplot(size(traces2Plot,2), size(traces2Plot,1), figIdx); hold on

            for ii = 1:size(traces2Plot{s,m},1)
                plot(snipTime{s}, traces2Plot{s,m}(ii,:))
            end
            plot(snipTime{s}, mean(traces2Plot{s,m}), 'LineWidth',2, 'Color','k')
            xlabel('Time (ms)')
            ylabel(muscles{m}, 'Interpreter','none', 'FontWeight','bold')
            xlim([60 120])

            if m == 1
                title(stim{s})
            end
        end
    end

    % Link axes for each muscle across stim conditions so zoom/pan stays in sync
    nMuscle = size(traces2Plot,2);
    nStim   = size(traces2Plot,1);
    for m = 1:nMuscle
        linkaxes(Tx((m-1)*nStim + (1:nStim)));
    end

    sgtitle(tracefilt{f})
end

%% Peak-to-peak and AUC within the MEP window
close all

for s = 1:size(filtMEP,1)
    for m = 1:size(filtMEP,2)
        % Find time indices corresponding to the MEP window
        [~, startIdx] = min(abs(snipTime{s} - TimeWindow(1)));
        [~, stopIdx]  = min(abs(snipTime{s} - TimeWindow(2)));

        for ii = 1:size(filtMEP{s,m},1)
            peakwindow = filtMEP{s,m}(ii, startIdx:stopIdx);

            % Subtract the mean of the first 3 samples as a local baseline,
            % then take absolute value so peak-to-peak is always positive
            adj_peakwindow = abs(peakwindow - mean(peakwindow(1:3)));

            aucMat{s,m}(ii,:) = trapz(adj_peakwindow);
            p2pMat{s,m}(ii,:) = peak2peak(adj_peakwindow);
        end

        % Remove statistical outliers before plotting and computing group stats
        p2pCleaned{s,m} = rmoutliers(p2pMat{s,m});
        aucCleaned{s,m} = rmoutliers(aucMat{s,m});
    end
end

ColorMap = {'#0072BD','#D95319','#EDB120','#7E2F8E','#77AC30','#4DBEEE','#A2142F'};

G(1) = figure;
G(1).Name = sprintf('P2P %s', Trial2Load);
for m = 1:size(p2pMat,2)
    Gx(m) = subplot(2,3,m); hold on
    myboxplot(p2pCleaned(:,m), 'box', ColorMap, 1, Gx(m))
    xticks(1:size(p2pMat,1))
    xticklabels(stim)
    title(muscles{m}, 'Interpreter','none')
end
sgtitle('Peak-to-Peak MEPs')

G(2) = figure;
G(2).Name = sprintf('AUC %s', Trial2Load);
for m = 1:size(aucMat,2)
    Dx(m) = subplot(2,3,m); hold on
    myboxplot(aucCleaned(:,m), 'box', ColorMap, 1, Dx(m))
    xticks(1:size(aucMat,1))
    xticklabels(stim)
    title(muscles{m}, 'Interpreter','none')
end
sgtitle('AUC MEPs')

%% Percentage increase in AUC from no-stim baseline (Fig 2B, 2C)
close all

% Compute mean AUC per (stim, muscle) for normalization
for s = 1:size(aucCleaned,1)
    for m = 1:size(aucCleaned,2)
        meanAUC(s,m) = mean(aucCleaned{s,m});
    end
end

% Individual trial scatter with condition mean
V(1) = figure;
V(1).Name = sprintf('Percentage Increase %s pts', Trial2Load);

for s = 1:size(aucCleaned,1)
    for m = 1:size(aucCleaned,2)
        baselineAUC = meanAUC(1,m); % No-stim mean as baseline
        varAUCmean  = (meanAUC(s,m) - baselineAUC) / baselineAUC * 100;

        subplot(2,3,m); hold on
        plot(s, varAUCmean, '-o', 'Color', ColorMap{s})

        for r = 1:length(aucCleaned{s,m})
            varAUC{s,m}(r,1) = (aucCleaned{s,m}(r) - baselineAUC) / baselineAUC * 100;
            plot(s, varAUC{s,m}(r,1), '.', 'Color', ColorMap{s})
        end

        xticks(1:size(aucMat,1))
        xticklabels(stim)
        ylabel('Percentage Increase')
        title(muscles{m}, 'Interpreter','none')
    end
end
sgtitle('Percentage Increase TMS')

% Summary boxplot with bootstrap statistics
V(2) = figure;
V(2).Name = sprintf('Percentage Increase %s Stats', Trial2Load);
for m = 1:size(aucMat,2)
    Vx(m) = subplot(2,3,m); hold on
    myboxplot(varAUC(:,m), 'box', ColorMap, 1, Vx(m))
    xticks(1:size(aucMat,1))
    xticklabels(stim)
    title(muscles{m}, 'Interpreter','none')
end
sgtitle('Percentage Increase TMS')

%% Save
if savePlots
    if ~exist(savePATH,'dir'), mkdir(savePATH); end
    saveFigurePDF(V, fullfile(savePATH, Trial2Load))
end
