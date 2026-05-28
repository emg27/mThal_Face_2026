%% F2-F1 Change Plot
% Created by Isabella Montanaro, last updated 29MAY2024
% Please reach out to ism83@pitt.edu with questions


% Some Notes:

% This file DOES NOT calculate formants
% Formant values are loaded in through a .mat data file, along with
% other information about day, subject, stimulation condition, etc.

% This file generates a plot of formant values in F2-F1 space
% Phoneme symbols are plotted at the Stim OFF location
% Arrows point to location with Stim ON, only if significant change

% There are multiple places in this file where you can choose what to plot:
% Which subject, which stimulation condition, etc.
% Inline comments exist in these locations


%% Load in data

% The data currently loaded into this file is for Subjects 1 (severe) and 4
% (mild). When new data becomes available, if it is structured in the same
% way as the existing .mat file below, simply change the file name to load
% in the new data.

% If new data is structured differently, the code in subsequent sections may
% not work.

clear all; %close all
%load('allCutVowelPhonemes_Subject001+Subject004_20240319.mat');
%load('D:\RNEL\analysis\allCutVowelPhonemes_Subject001_20230630_20241204.mat');
%load("/Users/zira/Library/CloudStorage/Dropbox/PostDoc/ElviraMarco/One-on-One/20241121/datPhoneme_allVowels_20240319.mat")
%dat_vowelPhoneme = dat_vowelPhoneme_OG;
load("/Users/zira/Data/mThal_NatComm_2026/Fig4_C_formantData.mat")

% Next, need to choose ON condition (not always 55Hz)
onCond = "55Hz";
offCond = "No Stim";
%% Split data by subject

% Currently, this is manually set up to only include Subjects 1 (severe)
% and 4 (mild), as this is the only data available in the existing .mat
% file. This will need to be updated when new subject data becomes
% available.

% sub1ii = [];
% sub4ii = [];
%
% for tr=1:length(dat_vowelPhoneme)
%     if contains(convertCharsToStrings(dat_vowelPhoneme(tr).subject),"Subject001")
%         sub1ii = [sub1ii tr];
%     elseif contains(convertCharsToStrings(dat_vowelPhoneme(tr).subject),"Subject004")
%         sub4ii = [sub4ii tr];
%     end
% end

sub1ii = find(contains({dat_vowelPhoneme.subject},{'Subject001'}));
sub4ii = find(contains({dat_vowelPhoneme.subject},{'Subject004'}));

sub1 = dat_vowelPhoneme(sub1ii);
sub4 = dat_vowelPhoneme(sub4ii);

%%%%%%%%%% CHOOSE SUBJECT HERE %%%%%%%%%%
% Define which subject you want to analyze in the rest of the script
sub = sub1;
subStr = "Subject 1"; % "Subject 1";

% Note:
% you can only analyze one subject at a time in this script, and should
% completely restart (clear all variables) when switching between subjects

%% Organize data features

% This section organizes days, phoneme sounds, and diphthong status into
% separate vectors for easy access

% days = [convertCharsToStrings(sub(1).dataset)];
% sounds = [convertCharsToStrings(sub(1).ipa)];
% for ph=1:length(sub)
%     if isempty(find(days==convertCharsToStrings(sub(ph).dataset)))
%         days = [days convertCharsToStrings(sub(ph).dataset)];
%     end
%     if isempty(find(sounds==convertCharsToStrings(sub(ph).ipa)))
%         sounds = [sounds convertCharsToStrings(sub(ph).ipa)];
%     end
% end

days = unique({sub.dataset});
sounds = unique([sub.ipa]);

% Binary indicator of whether a certain phoneme sound is a diphthong or not
% 0 = not a diphthong, 1 = diphthong
% Note: the sounds are organized in a vector, and the binary diphthong
% status is in a separate vector, but the indices align
% e.g. sounds(1) is the first phoneme, and diphthongs(1) is the
% diphthong status of the first phoneme

dipththongs = zeros(1,length(sounds));
for vs=1:length(sounds)
    if length(sounds{vs})>1
        dipththongs(vs) = 1;
    end
end

%% Remove the second blocks for each condition

% Create an index of words
words = cell(length(sub),1);
for ph=1:length(sub)
    idx = regexp(sub(ph).word,'_');
    words{ph} = sub(ph).word(1:idx-1);
end
[uniWord,~,idxWord] = unique(words);

% Create index of all conditions
[uniSess,~,idxSess] = unique({sub.dataset});
[uniCond,~,idxCond] = unique({sub.cond});

% Create index of all vowels
[uniIPA,~,idxIPA] = unique([sub.ipa]);

datCSWI = [idxCond idxSess idxWord idxIPA];
[uniCSWI,~,idxCSWI] = unique(datCSWI,'rows');

% Identify the valid conditions
if ~strcmp(subStr,"Subject 4")
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
end
%% Create structures to load in Formant Values
processDat = 1;
idxSubset = 15:85;%25:75;
numVS = length(sounds);

% 4 Columns:
%   1. phoneme name (ipa)
%   2. F1 (Hz)
%   3. F2 (Hz)
%   4. diphthong status (binary, 0=no/1=yes)

% First, stimulation OFF
formantsOFF = cell(numVS, 4, length(days));
for vs = 1:numVS
    for day=1:length(days)
        formantsOFF{vs,1,day} = sounds(vs); % phoneme name
        formantsOFF{vs,2,day} = []; % initialize F1 vector
        formantsOFF{vs,3,day} = []; % initialize F2 vector
        formantsOFF{vs,4,day} = dipththongs(vs); % diphthong status
    end
end
formantsON = formantsOFF; % initialize same structure for ON

%%%%%%%%%% CHOOSE ON CONDITION HERE %%%%%%%%%%
% % Next, need to choose ON condition (not always 55Hz)
% onCond = "55Hz";

% Now, load in formant values
for ph=1:length(sub)

    % Extract data
    day = convertCharsToStrings(sub(ph).dataset);
    dayii = find(days==day);
    vs = convertCharsToStrings(sub(ph).ipa);
    cond = convertCharsToStrings(sub(ph).cond);

    % Sort it properly
    for testVS = 1:numVS
        if vs==formantsOFF{testVS,1,dayii} % phoneme name is the same for OFF and ON
            % Process formant data by applying a median filter for
            % smoothing and then time warping the data to 1:100;
            if sum(~isnan(sub(ph).formant(:,1)))>0
                f1 = sub(ph).formant(1,:);
                f2 = sub(ph).formant(2,:);

                if processDat
                    f1 = medfilt1(f1);
                    sz = size(sub(ph).formant,2);
                    f1 = spline(linspace(1,100,sz),f1,1:100);

                    f2 = medfilt1(f2);
                    f2 = spline(linspace(1,100,sz),f2,1:100);

                    if ~isempty(idxSubset)
                        f1 = f1(idxSubset);
                        f2 = f2(idxSubset);
                    end
                end

                if cond == offCond
                    if isempty(sub(ph).formant)
                        % nothing to add.. phoneme was not said on this
                        % day/condition

                        %%%%%%%%%% CHOOSE IGNORED TRIALS HERE %%%%%%%%%%
                        % If you want to ignore a certain trial (practice, fatigue,
                        % etc.), you must put the trial number in the elseif
                        % statement. If you want to consider all trials, you must
                        % comment out the elseif statement
                    elseif sub(ph).trl == 1
                        % e.g. elseif sub(ph).trl == 1, we are ignoring ALL
                        % trial 1 data (across days, formants, etc.)

                    else
                        formantsOFF{testVS,2,dayii} = [formantsOFF{testVS,2,dayii} mean(f1)];%mean(f1)];
                        formantsOFF{testVS,3,dayii} = [formantsOFF{testVS,3,dayii} mean(f2)];%mean(f2)];
                        % formantsOFF{testVS,2,dayii} = [formantsOFF{testVS,2,dayii} mean(sub(ph).formant(1,:))];
                        % formantsOFF{testVS,3,dayii} = [formantsOFF{testVS,3,dayii} mean(sub(ph).formant(2,:))];
                        % the "mean" calculation here weights each phoneme utterance equally
                        % (rather than weighting them by length of utterance)
                    end

                elseif cond == onCond
                    if isempty(sub(ph).formant)
                        % nothing to add.. phoneme was not said on this
                        % day/condition

                        %%%%%%%%%% CHOOSE IGNORED TRIALS HERE %%%%%%%%%%
                        % Match your selection above
                    elseif sub(ph).trl == 1

                    else
                        formantsON{testVS,2,dayii} = [formantsON{testVS,2,dayii} mean(f1)];%mean(f1)];
                        formantsON{testVS,3,dayii} = [formantsON{testVS,3,dayii} mean(f2)];%mean(f2)];
                        % formantsON{testVS,2,dayii} = [formantsON{testVS,2,dayii} mean(sub(ph).formant(1,:))];
                        % formantsON{testVS,3,dayii} = [formantsON{testVS,3,dayii} mean(sub(ph).formant(2,:))];
                        % again, the "mean" calculation here weights each phoneme utterance equally
                        % (rather than weighting them by length of utterance)
                    end
                end
            end
        end
    end
end

%% Calculate averages

% Each time a sound is uttered, the phoneme formant values are calculated
% at intervaled windows for the whole duration of the sound
% Thus, each trial of a phoneme sound generates multiple formant values
% In the section above, the mean calculation produced the average
% across all windows, resulting in ONE formant value for each trial

% In THIS section, the mean calculation is averaging across multiple
% trials

% First, by day (one average formant value for each sound on each day)
for dayii=1:length(days)
    for vs=1:numVS
        avgF1OFF_daily(vs,dayii) = nanmean(formantsOFF{vs,2,dayii});
        avgF2OFF_daily(vs,dayii) = nanmean(formantsOFF{vs,3,dayii});
        avgF1ON_daily(vs,dayii) = nanmean(formantsON{vs,2,dayii});
        avgF2ON_daily(vs,dayii) = nanmean(formantsON{vs,3,dayii});
    end
end

% Then, overall, across days (averaging the daily averages... this weights each day equally)
for vs=1:numVS
    avgF1OFF(vs) = nanmean(avgF1OFF_daily(vs,:));
    avgF2OFF(vs) = nanmean(avgF2OFF_daily(vs,:));
    avgF155(vs) = nanmean(avgF1ON_daily(vs,:));
    avgF255(vs) = nanmean(avgF2ON_daily(vs,:));
end

%% Percent Change and Significance

% Statistical significance is calculated for the difference in means
% between the OFF and ON conditions, using the lab's existing Bootstrap
% script (bootstrapCompMeans)

% It is calculated for each sound on each day
% 0 = not significant change, 1 = significant change at p=0.05 level

% FYI: This section takes a few moments to run...

sig_F1 = zeros(numVS,length(days));
sig_F2 = zeros(numVS,length(days));

for dayii=1:length(days)
    for vs=1:numVS
        pchF1(vs,dayii) = 100*(avgF1ON_daily(vs,dayii) - avgF1OFF_daily(vs,dayii))/avgF1OFF_daily(vs,dayii);
        pchF2(vs,dayii) = 100*(avgF2ON_daily(vs,dayii) - avgF2OFF_daily(vs,dayii))/avgF2OFF_daily(vs,dayii);

        if ~isnan(formantsOFF{vs,2,dayii})
            if ~isempty(formantsON{vs,2,dayii})
                % First check F1
                [ci95,rejectNull,diffSampMeans] = bootstrapCompMeans(formantsOFF{vs,2,dayii},formantsON{vs,2,dayii});
                if rejectNull
                    sig_F1(vs,dayii)=1;
                end

                % Then check F2
                [ci95,rejectNull,diffSampMeans] = bootstrapCompMeans(formantsOFF{vs,3,dayii},formantsON{vs,3,dayii});
                if rejectNull
                    sig_F2(vs,dayii)=1;
                end
            end
        end
    end
end

%% Set up Plotting Details

colorsblack = zeros(numVS,3);
words = formantsOFF(:,1,1);

navy = "#0072BD";
gold = "#EDB120";

%%%%%%%%%% CHOOSE AXIS SCALE HERE %%%%%%%%%%
% Choose between log-scale (semitone=0) or semitone-scale (semitone=1) for
% figure axes
semitone = 1;

%% Figure: Significant Changes in F2-F1 Space
% This figure displays everything on one plot
% The next section provides code for a figure that splits the data up
% into specific F1 and F2 changes

figure;%(1);

% These variables count how many times a phoneme has a significant change
% This is used to space out the arrows on the plot so that they are all
% visible and do not overlap
f1s = zeros(numVS,2); % columns are up, down (arrow direction)
f2s = zeros(numVS,2); % columns are left, right (arrow direction)

% Plot an arrow for each day, sound with significant change
% Note that arrows are plotted independently for F1 and F2 (if a sound
% has a significant change in both directions, there will be two
% perpendicular arrows (not one diagonal))
for dayii=1:length(days)
    for vs=1:length(words)

        % Location of OFF point in F2-F1 space
        avgx = avgF2OFF(vs); avgy = avgF1OFF(vs);

        % If F1 change is significant (regardless of F2)
        if sig_F1(vs,dayii)==1
            if pchF1(vs,dayii)>0 % percent change > 0: F1 increases
                f1s(vs,1) = f1s(vs,1)+1;
                offset = 7*(f1s(vs,1)-1);
                color = navy;
            elseif pchF1(vs,dayii)<0 % percent change < 0: F1 decreases
                f1s(vs,2) = f1s(vs,2)+1;
                offset = 7*(f1s(vs,2)-1);
                color = navy;
            end

            % Only draw in F1 direction, proportional to size of change
            x=[avgx+offset avgx+offset+avgF2ON_daily(vs,dayii)-avgF2OFF_daily(vs,dayii)];
            y=[avgy avgy+avgF1ON_daily(vs,dayii)-avgF1OFF_daily(vs,dayii)];
            if semitone==1
                ref=110;
                x = 12*(log(x/ref))/(log(2));
                y = 12*(log(y/ref))/(log(2));
            end
            drawArrow = @(x,y) quiver(x(1),y(1),x(1)-x(1),y(2)-y(1), 'AutoScale','on', 'AutoScaleFactor', 1, 'color', color, 'LineWidth', 3);
            drawArrow(x,y); hold on;
        end

        % If F2 change is significant (regardless of F1)
        if sig_F2(vs,dayii)==1
            if pchF2(vs,dayii)>0 % percent change > 0: F2 increases
                f2s(vs,1) = f2s(vs,1)+1;
                offset = 7*(f2s(vs,1)-1);
                color = gold;
            elseif pchF2(vs,dayii)<0 % percent change < 0: F2 decreases
                f2s(vs,2) = f2s(vs,2)+1;
                offset = 7*(f2s(vs,2)-1);
                color = gold;
            end

            % Only draw in F2 direction, proportional to size of change
            x=[avgx avgx+avgF2ON_daily(vs,dayii)-avgF2OFF_daily(vs,dayii)];
            y=[avgy+offset avgy+offset+avgF1ON_daily(vs,dayii)-avgF1OFF_daily(vs,dayii)];
            if semitone==1
                ref=110;
                x = 12*(log(x/ref))/(log(2));
                y = 12*(log(y/ref))/(log(2));
            end
            drawArrow = @(x,y) quiver(x(1),y(1),x(2)-x(1),y(1)-y(1), 'AutoScale','on', 'AutoScaleFactor', 1, 'color', color, 'LineWidth', 3);
            drawArrow(x,y); hold on;
        end
    end
end

% Now plot average OFF location (avg across days)
clear circleplotX; clear circleplotY;
for vs=1:numVS
    circleplotX(vs) = avgF2OFF(vs);
    circleplotY(vs) = avgF1OFF(vs);
end
circleplotX(find(circleplotX==0))=[];
circleplotY(find(circleplotY==0))=[];

% Note that axis limits are manually set here. Change as needed.
if semitone==1
    scatter(12*log(circleplotX./ref)/log(2),12*log(circleplotY./ref)/log(2),250,'filled','MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8);
    textscatter(12*log(avgF2OFF./ref)/log(2), 12*log(avgF1OFF./ref)/log(2), words, 'ColorData', colorsblack, 'FontSize', 15, 'TextDensityPercentage', 100);
    set(gca, 'XDir', 'reverse'); xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back','Semitone Scale'}, 'FontWeight','bold'); %xlim(12/log(2).*[log(850/ref) log(2050/ref)]);
    set(gca, 'YDir', 'reverse'); ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close','Semitone Scale'},'FontWeight','bold'); %ylim(12/log(2).*[log(300/ref) log(800/ref)]);
    %set(gca, 'XDir', 'reverse', 'XTick',[]); xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back','Semitone Scale'}, 'FontWeight','bold'); %xlim(12/log(2).*[log(850/ref) log(2050/ref)]);
    %set(gca, 'YDir', 'reverse','YTick',[]); ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close','Semitone Scale'},'FontWeight','bold'); %ylim(12/log(2).*[log(300/ref) log(800/ref)]);
else
    scatter(circleplotX,circleplotY,250,'filled','MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8);
    textscatter(avgF2OFF, avgF1OFF, words, 'ColorData', colorsblack, 'FontSize', 15, 'TextDensityPercentage', 100);
    set(gca, 'XDir', 'reverse', 'XTick',[],'XScale','log'); xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back','log Scale'}, 'FontWeight','bold'); xlim([850 2050]);
    set(gca, 'YDir', 'reverse','YTick',[],'YScale','log'); ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close','log Scale'},'FontWeight','bold'); ylim([300 800]);
end

title(strcat(subStr,": Formant Trajectories, OFF to ", onCond))

hold off;

%% Figure Subplots: Significant Increases in F1 and F2
% This figure displays significant F1 and F2 increases in separate plots

figure;%(2);

% These variables count how many times a phoneme has a significant change
% This is used to space out the arrows on the plot so that they are all
% visible and do not overlap
f1s = zeros(numVS,2); % columns are up, down (arrow direction)
f2s = zeros(numVS,2); % columns are left, right (arrow direction)

% Plot an arrow for each day, sound with significant change
% Separate F1 and F2 arrows into different subplots
for dayii=1:length(days)
    for vs=1:length(words)

        % Location of OFF point in F2-F1 space
        avgx = avgF2OFF(vs); avgy = avgF1OFF(vs);

        % If F1 change is significant (regardless of F2)
        if sig_F1(vs,dayii)==1

            % The following if statement make it such that ONLY increases
            % in F2 are plotted. To plot all significant changes, comment
            % out the if statement to run the contained code always.
            if pchF1(vs,dayii)>0 % percent change > 0: F1 increases
                f1s(vs,1) = f1s(vs,1)+1;
                offset = 7*(f1s(vs,1)-1);
                sp=1;
                color = navy;

                % Only draw in F1 direction, proportional to size of change
                x=[avgx+offset avgx+offset+avgF2ON_daily(vs,dayii)-avgF2OFF_daily(vs,dayii)];
                y=[avgy avgy+avgF1ON_daily(vs,dayii)-avgF1OFF_daily(vs,dayii)];
                if semitone==1
                    ref=110;
                    x = 12*(log(x/ref))/(log(2));
                    y = 12*(log(y/ref))/(log(2));
                end
                drawArrow = @(x,y) quiver(x(1),y(1),x(1)-x(1),y(2)-y(1), 'AutoScale','on', 'AutoScaleFactor', 1, 'color', color, 'LineWidth', 3);
                subplot(2,2,sp); drawArrow(x,y); hold on;
            else pchF1(vs,dayii)<=0 % percent change > 0: F1 increases
                f1s(vs,1) = f1s(vs,1)+1;
                offset = 7*(f1s(vs,1)-1);
                sp=3;
                color = navy;

                % Only draw in F1 direction, proportional to size of change
                x=[avgx+offset avgx+offset+avgF2ON_daily(vs,dayii)-avgF2OFF_daily(vs,dayii)];
                y=[avgy avgy+avgF1ON_daily(vs,dayii)-avgF1OFF_daily(vs,dayii)];
                if semitone==1
                    ref=110;
                    x = 12*(log(x/ref))/(log(2));
                    y = 12*(log(y/ref))/(log(2));
                end
                drawArrow = @(x,y) quiver(x(1),y(1),x(1)-x(1),y(2)-y(1), 'AutoScale','on', 'AutoScaleFactor', 1, 'color', color, 'LineWidth', 3);
                subplot(2,2,sp); drawArrow(x,y); hold on;
            end
        end

        % If F2 change is significant (regardless of F1)
        if sig_F2(vs,dayii)==1

            % The following if statement make it such that ONLY increases
            % in F2 are plotted. To plot all significant changes, comment
            % out the if statement to run the contained code always.
            if pchF2(vs,dayii)>0 % percent change > 0: F2 increases
                f2s(vs,1) = f2s(vs,1)+1;
                offset = 7*(f2s(vs,1)-1);
                sp=2;
                color = gold;

                % Only draw in F2 direction, proportional to size of change
                x=[avgx avgx+avgF2ON_daily(vs,dayii)-avgF2OFF_daily(vs,dayii)]; f2Change = x(2)-x(1);
                y=[avgy+offset avgy+offset+avgF1ON_daily(vs,dayii)-avgF1OFF_daily(vs,dayii)]; f1Change = y(2)-y(1);
                if semitone==1
                    ref=110;
                    x = 12*(log(x/ref))/(log(2));
                    y = 12*(log(y/ref))/(log(2));
                end
                drawArrow = @(x,y) quiver(x(1),y(1),x(2)-x(1),y(1)-y(1), 'AutoScale','on', 'AutoScaleFactor', 1, 'color', color, 'LineWidth', 3);
                subplot(2,2,sp); drawArrow(x,y); hold on;
            elseif pchF2(vs,dayii)<=0 % percent change > 0: F2 increases
                f2s(vs,1) = f2s(vs,1)+1;
                offset = 7*(f2s(vs,1)-1);
                sp=4;
                color = gold;

                % Only draw in F2 direction, proportional to size of change
                x=[avgx avgx+avgF2ON_daily(vs,dayii)-avgF2OFF_daily(vs,dayii)]; f2Change = x(2)-x(1);
                y=[avgy+offset avgy+offset+avgF1ON_daily(vs,dayii)-avgF1OFF_daily(vs,dayii)]; f1Change = y(2)-y(1);
                if semitone==1
                    ref=110;
                    x = 12*(log(x/ref))/(log(2));
                    y = 12*(log(y/ref))/(log(2));
                end
                drawArrow = @(x,y) quiver(x(1),y(1),x(2)-x(1),y(1)-y(1), 'AutoScale','on', 'AutoScaleFactor', 1, 'color', color, 'LineWidth', 3);
                subplot(2,2,sp); drawArrow(x,y); hold on;
            end
        end
    end
end

% Now plot average OFF location (avg across days)
clear circleplotX; clear circleplotY;
for vs=1:numVS
    circleplotX(vs) = avgF2OFF(vs);
    circleplotY(vs) = avgF1OFF(vs);
end

circleplotX(find(circleplotX==0))=[];
circleplotY(find(circleplotY==0))=[];


%titles = [strcat(subStr,": F1 Increases, OFF to ", onCond) strcat(subStr,": F2 Increases, OFF to ", onCond)];
titles = ["Subject 1: F1 Increases, OFF to 55Hz"  "Subject 1: F2 Increases, OFF to 55Hz" "Subject 1: F1 Decreases, OFF to 55Hz"  "Subject 1: F2 Decreases, OFF to 55Hz"]
for sp=1:4
    subplot(2,2,sp); scatter(12*log(circleplotX./ref)/log(2),12*log(circleplotY./ref)/log(2),250,'filled','MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8); hold on;
    subplot(2,2,sp); textscatter(12*log(avgF2OFF./ref)/log(2), 12*log(avgF1OFF./ref)/log(2), words, 'ColorData', colorsblack, 'FontSize', 15, 'TextDensityPercentage', 100);
    subplot(2,2,sp); set(gca, 'XDir', 'reverse'); xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back','Semitone Scale'}, 'FontWeight','bold');
    subplot(2,2,sp); set(gca, 'YDir', 'reverse'); ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close','Semitone Scale'},'FontWeight','bold');
    subplot(2,2,sp); title(titles(sp));
end

% % Note that axis limits are manually set here. Change as needed.
% if semitone==1
%     for sp=1:2
%         subplot(2,1,sp); scatter(12*log(circleplotX./ref)/log(2),12*log(circleplotY./ref)/log(2),250,'filled','MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8); hold on;
%         subplot(2,1,sp); textscatter(12*log(avgF2OFF./ref)/log(2), 12*log(avgF1OFF./ref)/log(2), words, 'ColorData', colorsblack, 'FontSize', 15, 'TextDensityPercentage', 100);
%         subplot(2,1,sp); set(gca, 'XDir', 'reverse', 'XTick',[]); xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back','Semitone Scale'}, 'FontWeight','bold'); xlim(12/log(2).*[log(850/ref) log(2050/ref)]);
%         subplot(2,1,sp); set(gca, 'YDir', 'reverse','YTick',[]); ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close','Semitone Scale'},'FontWeight','bold'); ylim(12/log(2).*[log(300/ref) log(800/ref)]);
%         subplot(2,1,sp); title(titles(sp));
%     end
% else
%     for sp = 1:2
%         subplot(2,1,sp); scatter(circleplotX,circleplotY,250,'filled','MarkerFaceColor',[0.8 0.8 0.8], 'MarkerFaceAlpha',0.8); hold on;
%         subplot(2,1,sp); textscatter(avgF2OFF, avgF1OFF, words, 'ColorData', colorsblack, 'FontSize', 15, 'TextDensityPercentage', 100);
%         subplot(2,1,sp); set(gca, 'XDir', 'reverse', 'XTick',[],'XScale','log'); xlabel({'Front         \leftarrow F2 (Hz) \leftarrow         Back','log Scale'}, 'FontWeight','bold'); xlim([900 2050]);
%         subplot(2,1,sp); set(gca, 'YDir', 'reverse','YTick',[],'YScale','log'); ylabel({'Open   \leftarrow F1 (Hz) \leftarrow   Close','log Scale'},'FontWeight','bold'); ylim([300 800]);
%         subplot(2,1,sp); title(titles(sp));
%     end
% end
hold off;
