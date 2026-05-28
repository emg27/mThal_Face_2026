%% InterraterReliabilityMBS
% Computes quadratic weighted Cohen's kappa for two-rater ordinal agreement
% on modified barium swallow (MBS) severity scores.
%
% Two methods are implemented and compared as a cross-check:
%   Method 1   Quadratic weighted kappa via weighted_kappa_quadratic()
%   Method 2   Manual quadratic weighted Cohen's kappa
%
% Required Data:
%   KG, ST    Row vectors of integer severity ratings from each rater.
%             Edit these vectors directly to match your data.
%
% User Configuration:
%   KG        Ratings from rater 1
%   ST        Ratings from rater 2
%
% Created by Lilly Tang, Erinn Grigsby, and Arianna Damiani
% Copyright (C) 2026

clear, close all

%% Input Data
KG = [0 0 0 1 2 0 0 0 1 0 0 0 0 0];
ST = [0 0 0 2 2 1 1 1 0 0 0 0 0 0];

%% Method 1: Function — Quadratic Weighted Cohen's Kappa
kappa1 = weighted_kappa_quadratic(KG, ST);

%% Method 2: Manual Quadratic Weighted Cohen's Kappa
confmat = confusionmat(KG, ST);

k = size(confmat, 1);
weights = zeros(k);
for i = 1:k
    for j = 1:k
        weights(i, j) = (i - j)^2 / (k - 1)^2;
    end
end

n  = sum(confmat(:));
po = sum(sum(weights .* confmat)) / n;

row_marginals = sum(confmat, 2);
col_marginals = sum(confmat, 1);
expected = (row_marginals * col_marginals) / n;

pe = sum(sum(weights .* expected)) / n;

kappa2 = 1 - po / pe;
fprintf('Manual Quadratic Weighted Cohen''s Kappa: %.3f\n', kappa2);

%% Local Functions

function kappa = weighted_kappa_quadratic(rater1, rater2)
    if length(rater1) ~= length(rater2)
        error('Rater inputs must have the same length.');
    end

    C = confusionmat(rater1, rater2);
    n = sum(C(:));
    k = size(C, 1);

    W = zeros(k);
    for i = 1:k
        for j = 1:k
            W(i,j) = ((i - j)^2) / ((k - 1)^2);
        end
    end

    O = C / n;
    row_marginals = sum(C, 2) / n;
    col_marginals = sum(C, 1) / n;
    E = row_marginals * col_marginals;

    observed_weighted = sum(sum(W .* O));
    expected_weighted = sum(sum(W .* E));

    kappa = 1 - (observed_weighted / expected_weighted);
    fprintf('Quadratic Weighted Cohen''s Kappa: %.3f\n', kappa);
end
