clear
close all

pathName = 'P:\projects\human\VOP STIM\DATA\Chronic_DBS\BP\20230630\kinematics\iteration2\';

vopToLoad = [1 11 16]; %Reordered labeling by Stim! Different From Notes!
stimToLoad = [1 2 3 4];

labels = {'smile-noStim','tongue-noStim','openClose-noStim','kiss-noStim',...
    'smile-55Hz','tongue-55Hz','openClose-55Hz','kiss-55Hz', ...
    'smile-130Hz','tongue-130Hz','openClose-130Hz','kiss-130Hz'};

stim = {'noStim','55Hz','130Hz'};

faceTasklst = {'jawL','cheekL','mouthL','upperLip','lowerLip','chin','nose','mouthR','cheekR','jawR'};
task = {'smile','tongue','openClose','kiss'};

axisLabel = {'x','y'};

%% Load Data

traces = {};
count = 1;

%allFiles = p;
allFiles = load([pathName 'kinData_offset.mat']).p;
fileNames = {};

for ii = 1:size(allFiles,1)
    fileNames{ii} = allFiles(ii).filename;
end


for t = 1:length(vopToLoad)
    for tt = 1:length(stimToLoad)
    dlc_filename = [sprintf('VOP%04d',vopToLoad(t)) sprintf('_stim%04d',stimToLoad(tt))];
    trialIdx  = find(strcmp(fileNames,dlc_filename));

    % %load refined kinematic traces
    % traceIdx = allFiles(trialIndx).kinDat.threshIdx;
    % 
    % singleTrial = allFiles(trialIndx).kinDat.kinDat(traceIdx,:);
    % traces{count} = singleTrial';

    %load all kinematic traces
    singleTrial = allFiles(trialIdx).kinDat.kinDat;
    data{count} = singleTrial';
    datacol = 2;
    col = 1;

        for ii = 1:length(faceTasklst)
            trial = data{1,count};
            traces{count}(:,col:col+1) = trial(:,datacol:datacol+1);
            datacol = datacol+3;
            col = col+2;
        end
      count = count+1;
    end
end

%% Calculate area
close all

faceTasklst = {'jawL','cheekL','mouthL','upperLip','lowerLip','chin','nose','mouthR','cheekR','jawR'};
task_area = 3; %1:4;

areaPoints = [2 3 5 9
              3 4 5 9              
              3 4 5 10
              1 3 4 5] ;

manualLabel = false; %manual label

stim2Plot = 'All';
switch stim2Plot
    case 'All'
        stimIdx = [1 2 3];
end

ampMat = {};
area_windowed = {};
aucMat = {};
markersLabel = {};

for t = task_area
    for f = 1:size(areaPoints,2)
        markersLabel{f} = faceTasklst{areaPoints(task_area,f)};
    end
end

for t = task_area
    trialsPCA = find((contains(labels, task{t})));

    for tt = 1:length(trialsPCA)

        allMarkers_trace = traces{1,trialsPCA(tt)};

        y1 = allMarkers_trace(:,areaPoints(t,1)*2);
        x1 = allMarkers_trace(:,areaPoints(t,1)*2-1);

        y2 = allMarkers_trace(:,areaPoints(t,2)*2);
        x2 = allMarkers_trace(:,areaPoints(t,2)*2-1);

        y3 = allMarkers_trace(:,areaPoints(t,3)*2);
        x3 = allMarkers_trace(:,areaPoints(t,3)*2-1);

        y4 = allMarkers_trace(:,areaPoints(t,4)*2);
        x4 = allMarkers_trace(:,areaPoints(t,4)*2-1);
        
        singleTrace_area = [];
        for n = 1:length(y1)
            singleTrace_area(end+1) = polyarea([x1(n) x2(n) x3(n) x4(n)],[y1(n) y2(n) y3(n) y4(n)]);
        end

        if size(areaPoints,2) == 3
%             area_trace{t,tt} = 0.5.*abs((x1.*(y2-y3)) + (x2.*(y1-y3)) + (x3.*(y1-y2)));
            area_trace{t,tt} = singleTrace_area;

        elseif size(areaPoints,2) == 4
            y4 = allMarkers_trace(:,areaPoints(t,4)*2);
            x4 = allMarkers_trace(:,areaPoints(t,4)*2-1);
            area_trace{t,tt} = 0.5.*abs(x1.*y2 + x2.*y3 + x3.*y4 + x4.*y1 - x2.*y1 - x3.*y2 - x4.*y3 - x1.*y4);
%             singleTrace_area(end+1) = polyarea([x1(n) x2(n) x3(n)],[y1(n) y2(n) y3(n)]);
        end
        manualLabelCoor = [y3 x3 x2 x3];
        
        if manualLabel
            figure;
%             plot(manualLabelCoor(:,t))
            plot(area_trace{t,tt})

            title([labels{trialsPCA(tt)}])

            [x,y,button]=ginput;
            windowTimes{t,tt} = [x,y,button];
            save([pathName 'ChronicDBS01_DLC_area_startStopInds_v3.mat'],'windowTimes')            
            close all
        else
            windowTimes = load([pathName 'ChronicDBS01_DLC_area_startStopInds_v3.mat']).windowTimes;
        end

        times = windowTimes{t,tt}(:,1);
        peakTimes = times(2:2:end);
        startTimes = times(1:2:end);
        
        xCoor(tt,:) = [mean(x1(floor(peakTimes))) mean(x2(floor(peakTimes))) mean(x3(floor(peakTimes))) mean(x1(floor(peakTimes)))]-mean(x2(floor(peakTimes)));
        yCoor(tt,:) = [mean(y1(floor(peakTimes))) mean(y2(floor(peakTimes))) mean(y3(floor(peakTimes))) mean(y1(floor(peakTimes)))]-mean(y2(floor(peakTimes)));
        singleArea = [];
        for pks = 1:length(peakTimes)
            single_x1 = x1(floor(peakTimes(pks)));
            single_y1 = y1(floor(peakTimes(pks)));
            single_x2 = x2(floor(peakTimes(pks)));
            single_y2 = y2(floor(peakTimes(pks)));
            single_x3 = x3(floor(peakTimes(pks)));
            single_y3 = y3(floor(peakTimes(pks)));
            single_x4 = x4(floor(peakTimes(pks)));
            single_y4 = y4(floor(peakTimes(pks)));


            if size(areaPoints,2) == 4
%                 singleArea(end+1) = 0.5.*abs((single_x1*(single_y2-single_y3)) + (single_x2*(single_y1-single_y3)) + (single_x3*(single_y1-single_y2)));
                singleArea(end+1) = polyarea([single_x1 single_x2 single_x3 single_x4],[single_y1 single_y2 single_y3 single_y4]);

            % elseif size(areaPoints,2) == 4
            % 
            %     y4 = allMarkers_trace(:,areaPoints(4)*2);
            %     x4 = -allMarkers_trace(:,areaPoints(4)*2-1);
            %     singleArea(end+1) = 0.5.*abs(x1.*y2 + x2.*y3 + x3.*y4 + x4.*y1 - x2.*y1 - x3.*y2 - x4.*y3 - x1.*y4);
            end


        end
        
        std_signal=std(singleArea);
        idxToRemove = find(abs(singleArea)> mean(singleArea)+std_signal*2);
        singleArea(idxToRemove) = [];
        area_shape{t,tt} = singleArea;
        area_box{t,tt} = singleArea';

        % Average area of each movement
        for ttt = 1:length(startTimes)
            if ttt == length(startTimes)
                startInd = floor(startTimes(ttt));
                peakInd = floor(peakTimes(ttt));
                endInd = startInd + 2*abs(startInd-peakInd);
            else
                startInd = floor(startTimes(ttt));
                %endInd = floor(endTimes(ttt));
                endInd = floor(startTimes(ttt+1));
            end

            %              endInd = ceil(times(n+1));
            if endInd < length(area_trace{t,tt})
                window = area_trace{t,tt}(startInd:endInd)';

%                 if window(floor(length(window)/2)) < window(1) || window(floor(length(window)/2)) < window(end)
%                     window = -window;
%                 end
                window = abs(window - mean(window(1:3)));
                %area_windowed{tt}(count,:) = window;
                levels = statelevels(window);

                p2pMat{tt}(count,:) = peak2peak(window);
                aucMat{tt}(count,:) = trapz(1:length(window), window);
                count = count+1;

            end
        end
    end

    % Plot Area
    figure; hold on
    plot(area_trace{t,1}-mean(area_trace{t,1}(1:10)))
    plot(area_trace{t,2}-mean(area_trace{t,2}(1:10)))
    plot(area_trace{t,3}-mean(area_trace{t,3}(1:10)))

    xline(startTimes)

    title(task{t})
    legend(stim)

    % subplot(2,3,[4 5])
    % hold on
    % plot(mean(area_windowed{1,1}))
    % plot(mean(area_windowed{1,2}))
    %plot(mean(area_windowed{1,3}))

    title(task{t})
    legend(stim)

    % Plot Area Shape
    legend(stim)
    title([task{t} ' Visualized Area'])

    p2pBoxMat = [];
    aucBoxMat = [];
    a = [];
    p = [];

    for ind = 1:length(aucMat)
        p2pBoxMat = [p2pBoxMat; p2pMat{ind}];
        p = [p; ones(size(p2pMat{ind}))*ind];

        aucBoxMat = [aucBoxMat; aucMat{ind}];
        a = [a; ones(size(aucMat{ind}))*ind];
    end

% Area Coordination
    figure;
    subplot(1,2,1)
    hold on
    plot(xCoor(1,:),yCoor(1,:),'-o')
    plot(xCoor(2,:),yCoor(2,:),'-o')
    plot(xCoor(3,:),yCoor(3,:),'-o')

    legend(stim(stimIdx))

    hold off

    areaBoxMat = [];
    area = [];

    ColorMap = 	{"#0072BD",	"#D95319","#EDB120", "#7E2F8E","#77AC30","#4DBEEE", "#A2142F"};

    for ind = 1:length(stimIdx) %Stim Conditions
        aucShape{t,ind} = rmoutliers(area_shape{t,stimIdx(ind)})'; %myboxplot Matrix
    end

    % for ind = 1:size(area_shape,2) %Stim Conditions
    %     aucShape{t}{ind} = rmoutliers(area_shape{t,ind})'; %myboxplot Matrix
    % end

    ax(t) = subplot(1,2,2);
    myboxplot(aucShape(t,:)', 'box', ColorMap, 1, ax(t));
    %xticks(1:length(stim))
    xticks(1:length(stimIdx))
    xticklabels(stim(stimIdx))
    title([task{t} ' Peak Area'])
    annotation('textbox',[.3 .9 .1 .1], 'String', markersLabel)
end

%% Percent Variation

for t = 1:size(aucShape,1) %Task
    baselineAUC(t) = mean(aucShape{t,1});
    for s = 1:size(aucShape,2) %Stim
        normAUC{t,s} = (aucShape{t,s} - baselineAUC(t))./baselineAUC(t)*100;
    end 
end

T(1) = figure('Name', 'Percent Change in Aperture');
for t = 1:size(normAUC,1)
    ax(t) = subplot(2,2,t); hold on
    myboxplot(normAUC(t,:)','box',[],1,ax(t),1)
    xticks(1:length(stim))
    xticklabels(stim(stimIdx))
    ylabel('Percent Change')
    title(task{t})
end
sgtitle('Aperture Change')

%% Saving Figures

figIdx = [1 2];

count = 1;

for t = task_area
    for m = 1:length(figIdx)
        G(count) = figure(count);
        if m ==1
            G(count).Name = sprintf('%s_trace', task{t});
        else
            G(count).Name = sprintf('%s_area_visualization', task{t});
        end
        count = count+1;
    end
end

figFolder = 'P:\projects\human\VOP STIM\DATA\Chronic_DBS\BP\20230630\kinematics\AUC\myboxplot\';

saveFigurePDF(G, [figFolder])


%% FUNCTIONS

function [ci95, rejectNull] = bootstrapCompMeans(dataSet1, dataSet2, bootstrapReps,alpha)

sampMeans1 = nan(1,bootstrapReps);
sampMeans2 = nan(1,bootstrapReps);
diffSampMeans = nan(1,bootstrapReps);
for i=1:bootstrapReps
    % Resample from each dataset with replacement
    bootstrapSamp1 = randsample(dataSet1, length(dataSet1), true);
    bootstrapSamp2 = randsample(dataSet2, length(dataSet2), true);

    % Get means of both samples
    meanSamp1 = mean(bootstrapSamp1);
    sampMeans1(i) = meanSamp1;
    meanSamp2 = mean(bootstrapSamp2);
    sampMeans2(i) = meanSamp2;

    % Get the difference of the means
    diffMeans = meanSamp1 - meanSamp2;
    diffSampMeans(i) = diffMeans;
end

% Calculate confidence interval of difference of means
ci95 = quantile(diffSampMeans, [alpha/2, 1-(alpha/2)]);

% If ci95 contains 0 then don't reject null
if (ci95(1) <= 0) && (ci95(2) >= 0)
    rejectNull = false;
else
    rejectNull = true;
end

%     Plot histogram to confirm
%     figure;
%     hist(diffSampMeans, 100)

end



function filtered_LFP = filter_signal(LFP)
fs_chan = 30000;

% q = 35;
% bw = (freq/(fs_chan/2))/q;
% [b,a] = iircomb(ceil(fs_chan/freq),bw,'notch');
% %[b,a] = iircomb(50,bw,'notch');
%
% % Zero-phase filter
% filtSig = fliplr(filter(b,a,LFP,[],2));
% filtered_LFP = fliplr(filter(b,a,filtSig,[],2));
% %filtSig=filtfilt(b,a,sig);
% filterbands_Line=[58,62];
% [z, p, k] = butter(2, filterbands_Line/(fs_chan/2), 'stop');
% [sos_line,g_line] = zp2sos(z, p, k, 'down', 'two');

filterbands=[30,500];
[z,p,k] = butter(2, filterbands/(fs_chan/2), 'bandpass');
[sos,g] = zp2sos(z, p, k, 'down', 'two');


filtered_LFP=filtfilt(sos,g,double(LFP'))';
% filtered_LFP=filtfilt(sos_line,g_line,double(filtered_LFP'))';
end
