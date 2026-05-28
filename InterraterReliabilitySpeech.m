%% InterraterReliabilitySpeech
% Computes Fleiss' kappa for multi-rater binary agreement on speech
% intelligibility or perceptual ratings.
%
% Fleiss' kappa generalizes Cohen's kappa to more than two raters.
% Ratings are entered directly as row vectors; the script assembles
% the N × m rating matrix and computes kappa from category proportions.
%
% Required Data:
%   R1–R4     Row vectors of binary ratings (0 or 1), one per rater.
%             Edit these vectors directly to match your data.
%
% User Configuration:
%   R1, R2, R3, R4    Binary rating vectors (one per rater, same length)
%
% Created by Lilly Tang, Erinn Grigsby, and Arianna Damiani
% Copyright (C) 2026

clear, close all

%% Input: ratings from 4 raters
R1 = [0 1 1 0 1 0 1 1 1 1 1 1 1];
R2 = [1 1 1 0 1 0 1 0 1 0 1 1 1];
R3 = [0 0 0 0 1 0 0 0 1 1 0 0 1];
R4 = [0 0 0 1 0 1 1 1 0 1 1 1 0];

ratings = [R1' R2' R3' R4'];   % N × m matrix

%% Convert to Fleiss matrix (counts per category per item)
categories = unique(ratings);
k = length(categories);
N = size(ratings, 1);
m = size(ratings, 2);

M = zeros(N, k);
for i = 1:N
    for j = 1:m
        cat_index = find(categories == ratings(i,j));
        M(i,cat_index) = M(i,cat_index) + 1;
    end
end

%% Compute Fleiss' Kappa
n = sum(M, 2);   % number of ratings per item (should equal m)

% Agreement per item
P = (sum(M.^2, 2) - n) ./ (n .* (n-1));
Pbar = mean(P);

% Category proportions
p  = sum(M) ./ (N * m);
Pe = sum(p.^2);

kappa = (Pbar - Pe) / (1 - Pe);
fprintf('Fleiss'' Kappa (%d raters): %.3f\n', m, kappa);
