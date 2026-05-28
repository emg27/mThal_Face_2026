%% Fig1_G_FrequencyDependentClassification
% Summarizes frequency-dependent MEP classification (No Potentiation,
% Potentiation, Attenuation) across muscles and subjects.
%
% Creates the frequency dependence summary plots for figure 1 of the manuscript.
%
% Generates the following figures:
%   FF   Pie charts of MEP category proportions across all frequencies
%   FG   Grouped bar chart of MEP category percentages at 50–130 Hz (panel G)
%
% Required Data:
%   Fig1_G_frequencyDependenceCatergories.mat
%       AllData   Struct with one field per session. Each session struct has
%                 one field per muscle containing a cell array of per-trial
%                 category codes: 0 = No Potentiation, 1 = Potentiation,
%                 2 = Attenuation.
%
% User Configuration:
%   dataPath      Path to the folder containing the .mat data file
%   saveFigPath   Path to the folder where figures will be saved
%   savePlots     Set to 1 to save figures as PDF, 0 to skip saving
%
% Created by Lilly Tang, Erinn Grigsby, and Arianna Damiani
% Copyright (C) 2026

clear, close all

%% User configuration
curPath = pwd; addpath(genpath(curPath));
dataPath    = '/Users/zira/Data/mThal_NatComm_2026';
saveFigPath = '/Users/zira/analysisFigures/mThal_NatComm_2026_figs';
savePlots   = 0; % Set to 1 to save figures as PDF

%% Load data
load(fullfile(dataPath, 'Fig1_G_frequencyDependenceCatergories.mat'))

if ~exist(saveFigPath, 'dir') && savePlots
    mkdir(saveFigPath);
end

%% Define labels and categories
freq_labels  = {'BL', '50Hz', '80Hz', '100Hz', '130Hz', '200Hz'};
muscle       = {'ORIS', 'MYLO', 'MASS', 'CRICO', 'MENT'};
freq_behav   = {'No Potentiation', 'Potentiation', 'Attenuation'};
freq_behav_n = [0, 1, 2];

subj_list = fieldnames(AllData);

% Category colors matching figure panel G: NoPot (light blue), Pot (navy), Atten (gray)
catColorsRGB = [173 216 230; 36 64 139; 136 141 144] / 255;

%% Build data matrix
% Rows: one per valid muscle-subject observation
% Columns: one per frequency (BL, 50Hz, 80Hz, 100Hz, 130Hz, 200Hz)
data = [];
for m = 1:length(muscle)
    for s = 1:length(subj_list)
        if isfield(AllData.(subj_list{s}), muscle{m})
            subject_data = AllData.(subj_list{s}).(muscle{m});
            data = [data; cell2mat(subject_data)];
        end
    end
end

%% Figure FF: Pie charts of MEP category proportions by frequency
FF = figure;
FF.Name = 'Subject001_MEP_FrequencyPieCharts';
colormap(catColorsRGB);
for i = 1:size(data, 2)
    subplot(1, size(data, 2), i);
    v = data(:, i);
    counts = arrayfun(@(x) sum(v == x), freq_behav_n);
    pie(counts);
    title(freq_labels{i});
end
legend(freq_behav, 'Location', 'southoutside');

%% Figure FG: Grouped bar chart of MEP category percentages (panel G)
% Shows only stimulation frequencies 50Hz–130Hz (BL and 200Hz excluded)
stimCols   = 2:5;   % columns 2–5 correspond to 50Hz, 80Hz, 100Hz, 130Hz
stimLabels = freq_labels(stimCols);

% Compute percentage of observations in each category for each frequency
pctMat = zeros(length(stimCols), length(freq_behav_n));
for fi = 1:length(stimCols)
    v     = data(:, stimCols(fi));
    total = sum(~isnan(v));
    for ci = 1:length(freq_behav_n)
        pctMat(fi, ci) = 100 * sum(v == freq_behav_n(ci)) / total;
    end
end

% pctMat: rows = frequencies (50,80,100,130 Hz), columns = (NoPot, Pot, Atten)
FG = figure('Position', [680 400 560 420]);
FG.Name = 'Subject001_MEP_FrequencyBarChart';
b = bar(pctMat, 'grouped');
for ci = 1:length(freq_behav_n)
    b(ci).FaceColor = catColorsRGB(ci, :);
    b(ci).EdgeColor = catColorsRGB(ci, :);
end
xticks(1:length(stimCols));
xticklabels(stimLabels);
xlabel('mThal Stim Frequency');
ylabel('% MEP');
legend(freq_behav, 'Location', 'northeast');
ylim([0 100]);
title('Frequency Dependence of MEP Categories');

%% Save figures
if savePlots
    saveFigurePDF([FF; FG], saveFigPath);
end
