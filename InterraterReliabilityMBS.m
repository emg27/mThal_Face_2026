clear
close all

%% Input Data

KG = [0 0 0 1 2 0 0 0 1 0 0 0 0 0];
ST = [0 0 0 2 2 1 1 1 0 0 0 0 0 0];

%% Method 1: Function Caculate Interrater Reliability

kappa = weighted_kappa_quadratic(KG, ST);

0%% Method 2: Manual Weighted Cohen's Kappa

confmat = confusionmat(KG, ST);

k = size(confmat, 1);
weights = zeros(k);
for i = 1:k
    for j = 1:k
        weights(i, j) = (i - j)^2 / (k - 1)^2;
    end
end

n = sum(confmat(:));
po = sum(sum(weights .* confmat)) / n;

row_marginals = sum(confmat, 2);
col_marginals = sum(confmat, 1);
expected = (row_marginals * col_marginals) / n;

pe = sum(sum(weights .* expected)) / n;

kappa = 1 - po / pe;




function kappa = weighted_kappa_quadratic(rater1, rater2)
    % Check inputs
    if length(rater1) ~= length(rater2)
        error('Rater inputs must have the same length.');
    end

    % Generate confusion matrix
    C = confusionmat(rater1, rater2);
    n = sum(C(:));
    k = size(C, 1);  % number of categories

    % Compute quadratic weights
    W = zeros(k);
    for i = 1:k
        for j = 1:k
            W(i,j) = ((i - j)^2) / ((k - 1)^2);
        end
    end

    % Normalize confusion matrix
    O = C / n;  % observed proportions

    % Compute expected matrix
    row_marginals = sum(C, 2) / n;
    col_marginals = sum(C, 1) / n;
    E = row_marginals * col_marginals;  % expected proportions

    % Calculate weighted kappa
    observed_weighted = sum(sum(W .* O));
    expected_weighted = sum(sum(W .* E));

    kappa = 1 - (observed_weighted / expected_weighted);

    % Optional display
    fprintf('Quadratic Weighted Cohen''s Kappa: %.3f\n', kappa);
end
