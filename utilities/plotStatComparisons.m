function [statDat] = plotStatComparisons(data,varargin)
%Bootstrap parameters
compareGroups = []; % Determines the number of stat comparisons you are doing.
% If empty then the code will run through all possible
% comparisons.
multcompare = 1;%n_groups-1;
nRep = 10000;
gx = [];
plotNS = 1;

assignopts(who, varargin);
statDat = {};

if isempty(gx)
    gx = gca;
else
    axes(gx)
end
%% Add Nan so each cell has the same legnth and we can use the boxplot and violinplot function

n_groups = length(data);
trials=zeros(n_groups,1);
for n=1:(n_groups)
    trials(n,1) = numel(data{n,1});
end
max_trials = max(trials);

for n=1:(n_groups)
    if numel(data{n,1})<max_trials
        data{n,1}=[data{n,1};NaN(max_trials-numel(data{n,1}),1)];
    end
end

%% Add statistical analysis with bootstrapping

if isempty(compareGroups)
    compareGroups = {1:n_groups};
end

% Determine the number of total comparisons
poss_compare = 0;
for n = 1:size(compareGroups,2)
    n_groups = length(compareGroups{n});
    for k = 1:n_groups
        poss_compare = poss_compare +  (n_groups-k);
    end
end

%Here is to set where to plot the bars for statistics. Updated this code to
%now sent the number axis limit consistently for all groups.
YLimitsOG = get(gx, 'YLim');
rangeOG=diff(YLimitsOG);
ylim([YLimitsOG(1) YLimitsOG(2)+(rangeOG*poss_compare)/30]);

YLimits = get(gca, 'YLim');
top_lim = YLimits(2);
bot_lim = max(max([data{:}]));
range = top_lim - bot_lim;

dy_level = range/(poss_compare+0.3);
ylevel = bot_lim+dy_level : dy_level : bot_lim+poss_compare*dy_level;
comparison = 0;
compNoNS = 0;

for n = 1:size(compareGroups,2)
    grps = compareGroups{n};
    n_groups = length(grps);
    for fir=1:n_groups
        for sec=fir+1:n_groups
            comparison = comparison +1;
            group1 = data{grps(fir)};
            group1 = group1(~isnan(group1));
            group2 = data{grps(sec)};
            group2 = group2(~isnan(group2));

            % One asterisk?
            [ci95, rejectNull]=bootstrapCompMeans(group1,group2,nRep,0.05,multcompare);
            pDir = 0;
            if rejectNull
                pDir = pDir - sign(ci95(1));

                % Two asterisk?
                [ci95, rejectNull]=bootstrapCompMeans(group1,group2,nRep,0.01,multcompare);
                if rejectNull
                    pDir = pDir - sign(ci95(1));
                    % Three asterisk?
                    [ci95, rejectNull]=bootstrapCompMeans(group1,group2,nRep,0.001,multcompare);
                    if rejectNull
                        pDir = pDir - sign(ci95(1));
                        p='***';
                    else
                        p='**';
                    end
                else
                    p='*';
                end
            else
                p='n.s.';
            end

            % Save the comparison data
            statDat{comparison,1} = [grps(fir) grps(sec)]; % Which sessions are being compared
            statDat{comparison,2} = pDir;
            statDat{comparison,3} = p;
            % Now I need to plot the bar and the asterisks. There is now
            % the options to not plot NS comparisons.
            if plotNS & ismember(p,{'n.s.','*','**','***'})
                hold on
                tmp = [grps(fir) grps(sec)];
                line(tmp,[1 1]*ylevel(comparison),'Color','k','LineWidth',1.1)
                if strcmp(p,'n.s.')
                    text(grps(fir),ylevel(comparison)+dy_level/2,p)
                else
                    text(grps(fir),ylevel(comparison)+dy_level/4,p)
                end
            elseif ~plotNS & ismember(p,{'*','**','***'})
                compNoNS = compNoNS + 1;
                hold on
                tmp = [grps(fir) grps(sec)];
                line(tmp,[1 1]*ylevel(compNoNS),'Color','k','LineWidth',1.1)
                text(grps(fir),ylevel(compNoNS)+dy_level/4,p)
                ylim([YLimitsOG(1) YLimitsOG(2)+(rangeOG*compNoNS)/30]);
            end
        end
    end
end
end