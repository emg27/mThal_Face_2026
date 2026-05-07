clear
close all
%%

pathName = '/Volumes/rnelshare/projects/human/VOP STIM/DATA/Chronic_DBS/BP/20241203/TMS/';

D = dir(fullfile(pathName,'*.mat'));

Trial2Load = 'Face';

switch Trial2Load
    case 'Face'
        Trial = {'10' '11'};
        TimeWindow = [75 100];
    case 'Hand'
        Trial = {'5' '13'};
        TimeWindow = [100 140];
end


muscles = {'L_APB' 'L_MASS' 'L_ORIS' 'R_APB' 'R_MASS' 'R_ORIS'};
stim = {'noStim' '55Hz Tremor'};

%% Load Data
for s = 1:length(Trial) %Stim
    for d = 1:size(D,1) %Trials
        if contains(D(d).name,Trial{s})
            Data(s) = load(fullfile(D(d).folder,D(d).name)); % Load Data
        end
    end
end

Fs = 2500; %Delsy's Sampling Rate

% Load MEP Traces
fieldN = fieldnames(Data);

for m = 1:length(muscles) %Muscle
    idxM = find(contains(fieldN,muscles{m})); %Idx for Muscle
    for s = 1:length(Data) %Stim
        for i = 1:length(idxM)
            MEPsnips{i} = Data(s).([fieldN{idxM(i)}]); %Avg + Snips
        end
        MEPtraces{s,m} = MEPsnips{2}; %filter Snips
        snipTime{s} = Data(s).snipTime; %Time
    end
end

%% Low-Pass Filter + Check Traces
close all

count = 1;
for s = 1:size(MEPtraces,1) %stim
    for m = 1:size(MEPtraces,2) %muscle
        F(count) = figure; 
        F(count).Name = sprintf('%s %s Lowpass 100Hz', stim{s}, muscles{m});
        for ii = 1:size(MEPtraces{s,m},1) %Reps

            %LowPass Filter
            [Bbp, Abp] = butter(4,[100]/(Fs/2),'low');
            filtMEP{s,m}(ii,:) = filtfilt(Bbp, Abp, MEPtraces{s,m}(ii,:));

            %Plot Traces
            ax(1)=subplot(2,1,1); hold on,
            plot(snipTime{s}, MEPtraces{s,m}(ii,:)) %raw trace
            title('Raw')

            ax(2)=subplot(2,1,2); hold on
            plot(snipTime{s},filtMEP{s,m}(ii,:)),hold on, %filtered trace
            title('LowPass')
            xlabel('Time')
            if ii == size(MEPtraces{s,m},1)
                subplot(2,1,1), hold on, plot(snipTime{s}, mean(MEPtraces{s,m},1),'LineWidth',2,'Color', 'k')
                subplot(2,1,2), hold on, plot(snipTime{s}, mean(filtMEP{s,m},1),'LineWidth',2,'Color', 'k');
            end
            sgtitle(sprintf('%s %s', muscles{m}, stim{s}), 'Interpreter', 'none')
        end
        linkaxes(ax, 'xy')
        xlim([60 200])

        count = count+1;
    end
end

%% Plot All Traces
close all

tracefilt = {'Raw' 'Filtered'};

for s = 1:size(MEPtraces,1) %stim
    T(s) = figure; hold on
    T(s).Name = sprintf('MEP traces %s', stim{s});
    for f = 1:2
        if f==1
            traces2Plot = MEPtraces;
        else
            traces2Plot = filtMEP;
        end

        for m = 1:size(traces2Plot,2) %muscle
            figIdx = (m-1)*2+f;
            subplot(size(traces2Plot,2), size(traces2Plot,1),figIdx), hold on
            for ii = 1:size(traces2Plot{s,m},1)
                plot(snipTime{s},traces2Plot{s,m}(ii,:)),hold on
            end
            plot(snipTime{s},mean(traces2Plot{s,m}), 'LineWidth', 2, 'Color', 'k')
            xlabel('Time(ms)')

            if f ==1
                ylabel(muscles{m},'Interpreter','none','FontWeight','bold')
            end

            if m ==1
                title(tracefilt{f})
            end
        end
    end
    sgtitle(stim{s})
end

%% Plot NoStim v. Stim
close all
tracefilt = {'Raw' 'Filtered'};

for f = 1:2 %Raw v. Filtered
    T(f) = figure; hold on
    T(f).Name = sprintf('MEP traces %s', tracefilt{f});
    if f == 1
        traces2Plot = MEPtraces;
    else 
        traces2Plot = filtMEP;
    end

    for s = 1:size(traces2Plot,1) %stim
        for m = 1:size(traces2Plot,2) %muscle
            figIdx = (m-1)*2+s;
            Tx(figIdx) = subplot(size(traces2Plot,2), size(traces2Plot,1),figIdx); hold on
            for ii = 1:size(traces2Plot{s,m},1)
                plot(snipTime{s},traces2Plot{s,m}(ii,:)),hold on
            end
            plot(snipTime{s},mean(traces2Plot{s,m}), 'LineWidth', 2, 'Color', 'k')
            xlabel('Time(ms)')
            ylabel(muscles{m},'Interpreter','none','FontWeight','bold')
            xlim([60 120])

            if m ==1
                title(stim{s})
            end
        end
        linkaxes([Tx(5) Tx(6)])

    end
    sgtitle(tracefilt{f})
end

%% Peak2Peak 
close all
%Muscle2Plot = 2; %L_MASS

for s = 1:size(filtMEP,1)
    for m = 1:size(filtMEP,2)
        [~, startIdx] = min(abs(snipTime{s} - TimeWindow(1)));
        [~, stopIdx] = min(abs(snipTime{s} - TimeWindow(2)));

        for ii = 1:size(filtMEP{s,m},1) %rep
            peakwindow = filtMEP{s,m}(ii,startIdx:stopIdx);
            adj_peakwindow = abs(peakwindow - mean(peakwindow(1:3)));

            aucMat{s,m}(ii,:) = trapz(adj_peakwindow);
            p2pMat{s,m}(ii,:) = peak2peak(adj_peakwindow); %peak2peak of peaks
        end
        p2pCleaned{s,m} = rmoutliers(p2pMat{s,m});
        aucCleaned{s,m} = rmoutliers(aucMat{s,m});
    end
end


ColorMap = 	{"#0072BD",	"#D95319","#EDB120", "#7E2F8E","#77AC30","#4DBEEE", "#A2142F"};

G(1) = figure; hold on
G(1).Name = sprintf('P2P %s', Trial2Load);
for m = 1:size(p2pMat,2)
    Gx(m) = subplot(2, 3, m); hold on
    myboxplot(p2pCleaned(:,m),'box', ColorMap,1, Gx(m))
    xticks(1:size(p2pMat,1))
    xticklabels(stim)
    title(muscles{m}, 'Interpreter', 'none')
end
sgtitle('P2P MEPs')

G(2) = figure; hold on
G(2).Name = sprintf('AUC %s', Trial2Load);
for m = 1:size(aucMat,2)
    Dx(m) = subplot(2, 3, m); hold on
    myboxplot(aucCleaned(:,m),'box', ColorMap,1, Dx(m))
    xticks(1:size(aucMat,1))
    xticklabels(stim)
    title(muscles{m}, 'Interpreter', 'none')
end
sgtitle('AUC MEPs')

%% Percentage of Increase
close all

for s = 1:size(aucCleaned,1) %Stim
    for m = 1:size(aucCleaned,2) %Muscles
        meanAUC(s,m) = mean(aucCleaned{s,m}); %Mean AUC
    end
end

V(1) = figure; hold on
V(1).Name = sprintf('Percentage Increase %s pts', Trial2Load);

for s = 1:size(aucCleaned,1) %stim
    for m = 1:size(aucCleaned,2) %muscle
        baselineAUC = meanAUC(1,m); %NoStim Norm
        varAUCmean = (meanAUC(s,m)-baselineAUC)/baselineAUC*100;

        subplot(2, 3, m); hold on
        plot(s,varAUCmean, '-o','Color', ColorMap{s})

        for r = 1:length(aucCleaned{s,m}) %reps
            varAUC{s,m}(r,1) = (aucCleaned{s,m}(r)-baselineAUC)/baselineAUC*100;
            plot(s,varAUC{s,m}(r,1), '.', 'Color', ColorMap{s})
        end

        xticks(1:size(aucMat,1))
        xticklabels(stim)
        ylabel('Percentage Increase')
        title(muscles{m}, 'Interpreter', 'none')
    end
end
sgtitle('Percentage Increase TMS')

V(2) = figure; hold on
V(2).Name = sprintf('Percentage Increase %s Stats', Trial2Load);
for m = 1:size(aucMat,2)
    Vx(m) = subplot(2, 3, m); hold on
    myboxplot(varAUC(:,m),'box', ColorMap,1, Vx(m))
end
%% Save

savePATH = 'P:\projects\human\VOP STIM\DATA\Chronic_DBS\BP\20241203\TMS\figures\';

saveFigurePDF(V, [savePATH '\' Trial2Load])
